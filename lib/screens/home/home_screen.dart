import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/onboarding_provider.dart';
import '../../core/providers/project_provider.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/subscription_limits.dart';
import '../../widgets/glass_card.dart';
import '../../core/supabase/supabase_client.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = supabase.auth.currentUser;
    final currentProject = ref.watch(currentProjectProvider);
    final projectsAsync = ref.watch(projectsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('InstIQ'),
        actions: [
          _ProjectDropdown(
            currentProject: currentProject,
            projectsAsync: projectsAsync,
            onSwitch: (id) => switchProject(ref, id),
            onNewProject: () => _showNewProjectDialog(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primaryDark.withValues(alpha: 0.3),
                          child: Text(
                            (user?.email?.isNotEmpty == true ? user!.email![0] : '?').toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Привет!',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                user?.email ?? 'Пользователь',
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _GenerationBalanceWidget(onLimitReached: () => context.push('/paywall')),
                    const SizedBox(height: 24),
                    GlassCard(
                      onTap: () => context.push('/chat'),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryDark.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.chat_bubble_rounded, color: AppColors.primaryDark, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('AI-стратег', style: Theme.of(context).textTheme.titleMedium),
                                  Text(
                                    'Советы по развитию блога',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.mutedForegroundDark),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Быстрые действия', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _QuickActionChip(
                            icon: Icons.auto_awesome_rounded,
                            label: 'Создать контент',
                            onTap: () => context.go('/content'),
                          ),
                          const SizedBox(width: 12),
                          _QuickActionChip(
                            icon: Icons.trending_up_rounded,
                            label: 'Тренды',
                            onTap: () => context.go('/trends'),
                          ),
                          const SizedBox(width: 12),
                          _QuickActionChip(
                            icon: Icons.bar_chart_rounded,
                            label: 'Статистика',
                            onTap: () => context.go('/stats'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _OnboardingChecklist(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenerationBalanceWidget extends ConsumerWidget {
  final VoidCallback onLimitReached;

  const _GenerationBalanceWidget({required this.onLimitReached});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();
        final used = profile['monthly_generations_used'] as int? ?? 0;
        final tier = profile['subscription_tier'] as String? ?? 'free';
        final limit = limitForTier(tier);
        final isUnlimited = limit < 0;
        final exhausted = !isUnlimited && hasReachedLimit(used, tier);
        return GlassCard(
          onTap: exhausted ? onLimitReached : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Генерации', style: Theme.of(context).textTheme.titleSmall),
                    if (exhausted)
                      TextButton(
                        onPressed: onLimitReached,
                        child: Text('Лимит исчерпан', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (isUnlimited)
                  Text('$used использовано (безлимит)', style: Theme.of(context).textTheme.bodyMedium)
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value: (used / limit).clamp(0.0, 1.0),
                        backgroundColor: AppColors.borderDark,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          exhausted ? AppColors.destructiveDark : AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$used / $limit в месяц',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: AppColors.primaryDark),
              const SizedBox(width: 8),
              Text(label, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingChecklist extends ConsumerWidget {
  const _OnboardingChecklist();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(onboardingProgressProvider);
    return progress.when(
      data: (p) {
        if (p?.allDone == true) return const SizedBox.shrink();
        return GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 20, color: AppColors.primaryDark),
                    const SizedBox(width: 8),
                    Text('Creator Journey', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 12),
                _OnboardingStepRow(
                  done: p?.step1 ?? false,
                  label: 'Заполни профиль',
                  actionLabel: 'Заполнить',
                  onTap: () => context.push('/profile/edit'),
                ),
                _OnboardingStepRow(
                  done: p?.step2 ?? false,
                  label: 'Создай ДНК автора',
                  actionLabel: 'Создать',
                  onTap: () => context.push('/blueprint'),
                ),
                _OnboardingStepRow(
                  done: p?.step3 ?? false,
                  label: 'Создай контент',
                  actionLabel: 'Создать',
                  onTap: () => context.push('/generate-content'),
                ),
                _OnboardingStepRow(
                  done: p?.step4 ?? false,
                  label: 'Изучи тренды',
                  actionLabel: 'Изучить',
                  onTap: () => context.go('/trends'),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _OnboardingStepRow extends StatelessWidget {
  final bool done;
  final String label;
  final String actionLabel;
  final VoidCallback onTap;

  const _OnboardingStepRow({
    required this.done,
    required this.label,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: done ? AppColors.primaryDark : AppColors.mutedForegroundDark,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          if (!done)
            TextButton(
              onPressed: onTap,
              child: Text(actionLabel),
            ),
        ],
      ),
    );
  }
}

class _ProjectDropdown extends StatelessWidget {
  final Map<String, dynamic>? currentProject;
  final AsyncValue<List<Map<String, dynamic>>> projectsAsync;
  final void Function(String id) onSwitch;
  final VoidCallback onNewProject;

  const _ProjectDropdown({
    required this.currentProject,
    required this.projectsAsync,
    required this.onSwitch,
    required this.onNewProject,
  });

  @override
  Widget build(BuildContext context) {
    final name = currentProject?['name'] as String? ?? 'Проект';
    return PopupMenuButton<String>(
      tooltip: 'Проекты',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_rounded, size: 20, color: Theme.of(context).iconTheme.color),
            const SizedBox(width: 6),
            Text(name, style: Theme.of(context).textTheme.titleMedium, overflow: TextOverflow.ellipsis),
            const Icon(Icons.arrow_drop_down_rounded),
          ],
        ),
      ),
      onSelected: (value) {
        if (value == '__new__') {
          onNewProject();
        } else {
          onSwitch(value);
        }
      },
      itemBuilder: (context) {
        final list = projectsAsync.valueOrNull ?? [];
        final items = <PopupMenuEntry<String>>[
          ...list.map((p) => PopupMenuItem(
                value: p['id'] as String,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.folder_rounded),
                  title: Text(p['name'] as String? ?? 'Без названия'),
                ),
              )),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: '__new__',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.add_rounded),
              title: const Text('+ Новый проект'),
            ),
          ),
        ];
        return items;
      },
    );
  }
}

Future<void> _showNewProjectDialog(BuildContext context, WidgetRef ref) async {
  final nameController = TextEditingController();
  final niches = ['Лайфстайл', 'Красота', 'Фитнес', 'Еда', 'Путешествия', 'Бизнес', 'Образование', 'Другое'];
  String? selectedNiche = niches.first;

  final result = await showDialog<Map<String, String>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Новый проект'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Название проекта',
                  hintText: 'Мой блог',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedNiche,
                decoration: const InputDecoration(labelText: 'Ниша'),
                items: niches.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                onChanged: (v) => setState(() => selectedNiche = v),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(ctx, {
                'name': nameController.text.trim(),
                'niche': selectedNiche ?? 'Другое',
              });
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    ),
  );

  if (result == null) return;
  final user = supabase.auth.currentUser;
  if (user == null) return;
  final name = result['name']!.isNotEmpty ? result['name']! : 'Новый проект';
  final niche = result['niche'] ?? 'Другое';

  try {
    final insertRes = await supabase.from('projects').insert({
      'user_id': user.id,
      'name': name,
      'niche': niche,
    }).select('id').single();
    final projectId = insertRes['id'] as String?;
    if (projectId != null) {
      await supabase.from('project_profiles').insert({
        'project_id': projectId,
        'user_id': user.id,
        'blog_niche': niche,
      });
      switchProject(ref, projectId);
      ref.invalidate(projectsListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Проект создан')));
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }
}

