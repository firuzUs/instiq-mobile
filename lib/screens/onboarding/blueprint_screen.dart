import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/providers/project_provider.dart';
import '../../core/providers/onboarding_provider.dart';
import '../../core/supabase/supabase_client.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

const _goals = ['Рост', 'Вовлечённость', 'Бренд', 'Продажи', 'Экспертность'];
const _experienceLevels = ['Новичок', 'Опытный', 'Эксперт'];

class BlueprintScreen extends ConsumerStatefulWidget {
  const BlueprintScreen({super.key});

  @override
  ConsumerState<BlueprintScreen> createState() => _BlueprintScreenState();
}

class _BlueprintScreenState extends ConsumerState<BlueprintScreen> {
  final Set<String> _selectedGoals = {};
  String _experienceLevel = _experienceLevels.first;
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final projectId = ref.watch(currentProjectIdProvider);
    final projectsAsync = ref.watch(projectsListProvider);
    final effectiveProjectId = projectId ?? projectsAsync.valueOrNull?.firstOrNull?['id'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ДНК автора'),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => context.pop()),
      ),
      body: _result != null ? _buildResult(context) : profileAsync.when(
        data: (profile) {
          if (profile == null || effectiveProjectId == null) {
            return Center(child: Text('Сначала заполните профиль и выберите проект', style: Theme.of(context).textTheme.bodyLarge));
          }
          final bio = profile['bio'] as String? ?? '';
          final niche = profile['blog_niche'] as String? ?? 'Другое';
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Цели (можно несколько)', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _goals.map((g) => FilterChip(
                    label: Text(g),
                    selected: _selectedGoals.contains(g),
                    onSelected: (v) => setState(() {
                      if (v) _selectedGoals.add(g); else _selectedGoals.remove(g);
                    }),
                    selectedColor: AppColors.primaryDark.withValues(alpha: 0.3),
                  )).toList(),
                ),
                const SizedBox(height: 20),
                Text('Уровень опыта', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _experienceLevels.map((e) => ChoiceChip(
                    label: Text(e),
                    selected: _experienceLevel == e,
                    onSelected: (_) => setState(() => _experienceLevel = e),
                    selectedColor: AppColors.primaryDark.withValues(alpha: 0.3),
                  )).toList(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 24),
                GradientButton(
                  onPressed: _loading ? null : () => _generate(context, bio, niche, effectiveProjectId),
                  child: _loading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54))
                      : const Text('Создать ДНК автора'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    final archetype = _result!['archetype'];
    final pillars = _result!['content_pillars'];
    final tone = _result!['tone_vector'];
    final audience = _result!['audience_profile'];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Архетип', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('$archetype', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
        if (pillars != null && (pillars is List)) ...[
          const SizedBox(height: 16),
          _Section(title: 'Опоры контента', data: pillars),
        ],
        if (tone != null) ...[
          const SizedBox(height: 16),
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Тон', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('$tone', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
        if (audience != null) ...[
          const SizedBox(height: 16),
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Аудитория', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('$audience', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        GradientButton(
          onPressed: () => context.pop(),
          child: const Text('Готово'),
        ),
      ],
    );
  }

  Future<void> _generate(BuildContext context, String bio, String niche, String projectId) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await supabase.functions.invoke(
        'generate-blueprint',
        body: {
          'bio': bio,
          'niche': niche,
          'goals': _selectedGoals.toList(),
          'experienceLevel': _experienceLevel,
          'projectId': projectId,
        },
      );
      if (response.status != 200) throw Exception(response.data?.toString() ?? 'Ошибка');
      final data = response.data;
      if (data is Map) {
        ref.invalidate(onboardingProgressProvider);
        setState(() {
          _result = Map<String, dynamic>.from(data as Map);
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _result = <String, dynamic>{};
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }
}

class _Section extends StatelessWidget {
  final String title;
  final dynamic data;

  const _Section({required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    final list = data is List ? data as List : <dynamic>[];
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...list.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $e', style: Theme.of(context).textTheme.bodyMedium),
            )),
          ],
        ),
      ),
    );
  }
}
