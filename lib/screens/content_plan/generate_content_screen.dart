import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/project_provider.dart';
import '../../core/providers/project_profile_provider.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/providers/content_calendar_provider.dart';
import '../../core/subscription_limits.dart';
import '../../core/supabase/supabase_client.dart';
import '../../screens/paywall/paywall_screen.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

class GenerateContentScreen extends ConsumerStatefulWidget {
  const GenerateContentScreen({super.key});

  @override
  ConsumerState<GenerateContentScreen> createState() => _GenerateContentScreenState();
}

class _GenerateContentScreenState extends ConsumerState<GenerateContentScreen> {
  int _count = 3;
  final Set<String> _selectedTypes = {'reels'};
  DateTime _weekStart = _mondayOf(DateTime.now());
  bool _isLoading = false;
  String? _error;

  static DateTime _mondayOf(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }

  String get _weekStartIso => DateFormat('yyyy-MM-dd').format(_weekStart);

  @override
  Widget build(BuildContext context) {
    final projectId = ref.watch(currentProjectIdProvider);
    final projectsAsync = ref.watch(projectsListProvider);
    final effectiveProjectId = projectId ?? projectsAsync.valueOrNull?.firstOrNull?['id'] as String?;
    final profileAsync = effectiveProjectId != null
        ? ref.watch(projectProfileProvider(effectiveProjectId))
        : const AsyncValue<Map<String, dynamic>?>.data(null);

    if (effectiveProjectId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Создать контент')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Сначала создайте проект',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final niche = profileAsync.valueOrNull?['blog_niche'] as String? ?? profileAsync.valueOrNull?['niche'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать контент'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Количество идей',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _count.toDouble(),
                    min: 1,
                    max: 7,
                    divisions: 6,
                    label: '$_count',
                    onChanged: (v) => setState(() => _count = v.round()),
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: Text('$_count', style: Theme.of(context).textTheme.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Типы контента',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _TypeChip(
                  label: 'Reels',
                  value: 'reels',
                  selected: _selectedTypes.contains('reels'),
                  onTap: () => setState(() {
                    if (_selectedTypes.contains('reels')) {
                      _selectedTypes.remove('reels');
                    } else {
                      _selectedTypes.add('reels');
                    }
                    if (_selectedTypes.isEmpty) _selectedTypes.add('reels');
                  }),
                ),
                _TypeChip(
                  label: 'Stories',
                  value: 'stories',
                  selected: _selectedTypes.contains('stories'),
                  onTap: () => setState(() {
                    if (_selectedTypes.contains('stories')) {
                      _selectedTypes.remove('stories');
                    } else {
                      _selectedTypes.add('stories');
                    }
                    if (_selectedTypes.isEmpty) _selectedTypes.add('reels');
                  }),
                ),
                _TypeChip(
                  label: 'Carousel',
                  value: 'carousel',
                  selected: _selectedTypes.contains('carousel'),
                  onTap: () => setState(() {
                    if (_selectedTypes.contains('carousel')) {
                      _selectedTypes.remove('carousel');
                    } else {
                      _selectedTypes.add('carousel');
                    }
                    if (_selectedTypes.isEmpty) _selectedTypes.add('reels');
                  }),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Неделя (понедельник)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            GlassCard(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _weekStart,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _weekStart = _mondayOf(picked));
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded),
                    const SizedBox(width: 12),
                    Text(DateFormat('d MMMM yyyy', 'ru').format(_weekStart)),
                  ],
                ),
              ),
            ),
            if (niche.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Ниша проекта не задана. Заполните профиль проекта.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.accentDark),
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 32),
            IgnorePointer(
              ignoring: _isLoading || niche.isEmpty,
              child: Opacity(
                opacity: _isLoading || niche.isEmpty ? 0.6 : 1,
                child: GradientButton(
                  onPressed: () => _generate(context, effectiveProjectId, niche),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54),
                        )
                      : const Text('Сгенерировать'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generate(BuildContext context, String projectId, String niche) async {
    final profile = await ref.read(profileProvider.future);
    if (profile != null) {
      final used = profile['monthly_generations_used'] as int? ?? 0;
      final tier = profile['subscription_tier'] as String? ?? 'free';
      if (hasReachedLimit(used, tier)) {
        if (context.mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (ctx) => DraggableScrollableSheet(
              initialChildSize: 0.7,
              expand: false,
              builder: (_, scrollController) => const PaywallScreen(),
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _error = 'Нужна авторизация';
          _isLoading = false;
        });
        return;
      }

      final typeParam = _selectedTypes.length == 1
          ? _selectedTypes.first
          : _selectedTypes.toList();

      final response = await supabase.functions.invoke(
        'generate-content',
        body: {
          'niche': niche.isNotEmpty ? niche : 'блог',
          'count': _count,
          'type': typeParam,
          'weekStart': _weekStartIso,
          'projectId': projectId,
        },
      );

      if (response.status != 200) {
        final msg = response.data is Map ? (response.data as Map)['message'] ?? response.data : response.data;
        throw Exception(msg ?? 'Ошибка генерации');
      }

      final data = response.data;
      List<dynamic> items = const [];
      if (data is Map && data['items'] != null) {
        items = data['items'] is List ? data['items'] as List : [];
      } else if (data is List) {
        items = data;
      }

      if (items.isEmpty) {
        if (mounted) {
          setState(() {
            _error = 'Нет данных от сервера';
            _isLoading = false;
          });
        }
        return;
      }

      final weekEnd = _weekStart.add(const Duration(days: 6));
      final weekEndIso = DateFormat('yyyy-MM-dd').format(weekEnd);

      for (var i = 0; i < items.length; i++) {
        final item = items[i] is Map ? Map<String, dynamic>.from(items[i] as Map) : <String, dynamic>{};
        final plannedDate = item['planned_date'] as String? ?? _weekStartIso;
        await supabase.from('content_calendar').insert({
          'user_id': user.id,
          'project_id': projectId,
          'title': item['title'] ?? 'Идея ${i + 1}',
          'hook': item['hook'],
          'main_content': item['main_content'],
          'anchor': item['anchor'],
          'goal': item['goal'],
          'type': item['type'] ?? 'reels',
          'niche': item['niche'] ?? niche,
          'planned_date': plannedDate,
          'week_start': _weekStartIso,
          'sequence_order': item['sequence_order'] ?? i,
          'status': 'planned',
        });
      }

      ref.invalidate(contentCalendarProvider((projectId, _weekStartIso, weekEndIso)));
      ref.invalidate(projectsListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Создано ${items.length} идей')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryDark.withValues(alpha: 0.3),
      checkmarkColor: AppColors.primaryDark,
    );
  }
}
