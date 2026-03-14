import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/trends_provider.dart';
import '../../core/providers/project_provider.dart';
import '../../core/supabase/supabase_client.dart';
import '../../widgets/glass_card.dart';

class TrendsScreen extends ConsumerStatefulWidget {
  const TrendsScreen({super.key});

  @override
  ConsumerState<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends ConsumerState<TrendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тренды'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Сохранённые'),
            Tab(text: 'Ядро трендов'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _SavedTrendsTab(),
          const _TrendCoreTab(),
        ],
      ),
    );
  }
}

class _SavedTrendsTab extends ConsumerWidget {
  const _SavedTrendsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(savedTrendsProvider);
    return async.when(
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Пока нет сохранённых трендов. Сохраняйте понравившиеся из раздела «Радар».',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(savedTrendsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, i) {
              return _SavedTrendCard(
                item: list[i],
                onDelete: () async {
                  final id = list[i]['id'];
                  if (id != null) {
                    await supabase.from('saved_trends').delete().eq('id', id);
                    ref.invalidate(savedTrendsProvider);
                  }
                },
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Ошибка: $e')),
    );
  }
}

class _SavedTrendCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onDelete;

  const _SavedTrendCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = item['thumbnail_url'] as String?;
    final ownerUsername = item['owner_username'] as String? ?? '@username';
    final views = item['views'];
    final likes = item['likes'];
    final erPercent = item['er_percent'];
    final duration = item['duration'];
    final caption = item['caption'] as String?;

    return Dismissible(
      key: ValueKey(item['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.destructiveDark,
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 32),
      ),
      onDismissed: (_) => onDelete(),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: thumbnailUrl != null && thumbnailUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: thumbnailUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: AppColors.borderDark,
                              child: const Icon(Icons.video_library_rounded, size: 40, color: AppColors.mutedForegroundDark),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              width: 80,
                              height: 80,
                              color: AppColors.borderDark,
                              child: const Icon(Icons.video_library_rounded, size: 40, color: AppColors.mutedForegroundDark),
                            ),
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            color: AppColors.borderDark,
                            child: const Icon(Icons.video_library_rounded, size: 40, color: AppColors.mutedForegroundDark),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ownerUsername, style: Theme.of(context).textTheme.titleMedium),
                        if (caption != null && caption.isNotEmpty)
                          Text(
                            caption.length > 80 ? '${caption.substring(0, 80)}...' : caption,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.visibility_rounded, size: 14, color: AppColors.mutedForegroundDark),
                            const SizedBox(width: 4),
                            Text('${views ?? 0}', style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(width: 12),
                            Icon(Icons.favorite_rounded, size: 14, color: AppColors.primaryDark),
                            const SizedBox(width: 4),
                            Text('${likes ?? 0}', style: Theme.of(context).textTheme.bodySmall),
                            if (erPercent != null) ...[
                              const SizedBox(width: 12),
                              Text('ER ${erPercent}%', style: Theme.of(context).textTheme.bodySmall),
                            ],
                            if (duration != null) ...[
                              const SizedBox(width: 12),
                              Text('${duration}s', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: const Text('Создать сценарий'),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _TrendCoreTab extends ConsumerWidget {
  const _TrendCoreTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = ref.watch(currentProjectIdProvider);
    final projectsAsync = ref.watch(projectsListProvider);
    final effectiveProjectId = projectId ?? projectsAsync.valueOrNull?.firstOrNull?['id'] as String?;

    if (effectiveProjectId == null) {
      return Center(
        child: Text(
          'Выберите проект в дашборде',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    final async = ref.watch(trendCoresProvider(effectiveProjectId));

    return async.when(
      data: (core) {
        if (core == null || core.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Ядро трендов ещё не создано. Используйте раздел «Радар» для анализа.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final formats = core['trending_formats'];
        final topics = core['trending_topics'];
        final hooks = core['trending_hooks'];
        final music = core['trending_music'];
        final summary = core['summary'] as String?;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (summary != null && summary.isNotEmpty)
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Резюме', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(summary, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
            if (formats != null && (formats is List) && (formats as List).isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionList(title: 'Форматы', items: (formats as List).cast()),
            ],
            if (topics != null && (topics is List) && (topics as List).isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionList(title: 'Топики', items: (topics as List).cast()),
            ],
            if (hooks != null && (hooks is List) && (hooks as List).isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionList(title: 'Хуки', items: (hooks as List).cast()),
            ],
            if (music != null && (music is List) && (music as List).isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionList(title: 'Музыка', items: (music as List).cast()),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Ошибка: $e')),
    );
  }
}

class _SectionList extends StatelessWidget {
  final String title;
  final List<dynamic> items;

  const _SectionList({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((e) => Chip(label: Text('$e'))).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
