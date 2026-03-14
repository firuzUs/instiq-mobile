import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/content_calendar_provider.dart';
import '../../core/providers/project_provider.dart';
import '../../core/supabase/supabase_client.dart';
import '../../widgets/glass_card.dart';

class ContentPlanScreen extends ConsumerStatefulWidget {
  const ContentPlanScreen({super.key});

  @override
  ConsumerState<ContentPlanScreen> createState() => _ContentPlanScreenState();
}

class _ContentPlanScreenState extends ConsumerState<ContentPlanScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static String _weekStart() {
    final now = DateTime.now();
    final weekday = now.weekday;
    final start = now.subtract(Duration(days: weekday - 1));
    return DateFormat('yyyy-MM-dd').format(start);
  }

  static String _weekEnd() {
    final now = DateTime.now();
    final weekday = now.weekday;
    final end = now.add(Duration(days: DateTime.daysPerWeek - weekday));
    return DateFormat('yyyy-MM-dd').format(end);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectId = ref.watch(currentProjectIdProvider);
    final projectsAsync = ref.watch(projectsListProvider);
    final firstProjectId = projectsAsync.valueOrNull?.isNotEmpty == true
        ? projectsAsync.value!.first['id'] as String?
        : null;
    final effectiveProjectId = projectId ?? firstProjectId;
    final contentParams = (effectiveProjectId, _weekStart(), _weekEnd());
    final contentAsync = ref.watch(contentCalendarProvider(contentParams));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Контент-план'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/generate-content'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'По дням'),
            Tab(text: 'Календарь'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ContentByDayList(
            contentAsync: contentAsync,
            onRefresh: () => ref.invalidate(contentCalendarProvider(contentParams)),
          ),
          _CalendarPlaceholder(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/generate-content'),
        icon: const Icon(Icons.auto_awesome_rounded),
        label: const Text('Создать контент'),
        backgroundColor: AppColors.primaryDark,
      ),
    );
  }

}

class _ContentByDayList extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> contentAsync;
  final VoidCallback? onRefresh;

  const _ContentByDayList({required this.contentAsync, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return contentAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('На эту неделю', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        'Пока нет запланированного контента. Нажми «Создать контент».',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
        final byDay = <String, List<Map<String, dynamic>>>{};
        for (final item in items) {
          final date = item['planned_date'] as String? ?? '';
          byDay.putIfAbsent(date, () => []).add(item);
        }
        final sortedDates = byDay.keys.toList()..sort();
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedDates.length,
          itemBuilder: (context, i) {
            final date = sortedDates[i];
            final dayItems = byDay[date]!;
            final parsed = DateTime.tryParse(date);
            final label = parsed != null ? DateFormat('EEEE, d MMMM', 'ru').format(parsed) : date;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(label, style: Theme.of(context).textTheme.titleSmall),
                ),
                ...dayItems.map((item) => _ContentCard(item: item, onLikeToggle: onRefresh)),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Ошибка: $e')),
    );
  }
}

class _ContentCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onLikeToggle;

  const _ContentCard({required this.item, this.onLikeToggle});

  @override
  Widget build(BuildContext context) {
    final title = item['title'] as String? ?? 'Без названия';
    final hook = item['hook'] as String? ?? '';
    final type = item['type'] as String? ?? 'reels';
    final isLiked = item['is_liked'] as bool? ?? false;
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_iconForType(type), size: 16, color: AppColors.primaryDark),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
                IconButton(
                  icon: Icon(isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isLiked ? AppColors.primaryDark : null),
                  onPressed: () async {
                    await _toggleLike(item);
                    onLikeToggle?.call();
                  },
                ),
              ],
            ),
            if (hook.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(hook, style: Theme.of(context).textTheme.bodySmall),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'stories': return Icons.auto_stories_rounded;
      case 'carousel': return Icons.view_carousel_rounded;
      default: return Icons.videocam_rounded;
    }
  }

  Future<void> _toggleLike(Map<String, dynamic> item) async {
    final id = item['id'];
    if (id == null) return;
    final current = item['is_liked'] as bool? ?? false;
    await supabase.from('content_calendar').update({'is_liked': !current}).eq('id', id);
  }
}

class _CalendarPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Календарь (вид по неделе/месяцу)',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
