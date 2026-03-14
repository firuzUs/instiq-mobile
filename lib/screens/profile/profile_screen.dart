import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/subscription_limits.dart';
import '../../core/supabase/supabase_client.dart';
import '../../widgets/glass_card.dart';
import 'instagram_section.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = supabase.auth.currentUser;
    final profileAsync = ref.watch(profileProvider);
    final tier = profileAsync.valueOrNull?['subscription_tier'] as String? ?? 'free';
    final expiresAt = profileAsync.valueOrNull?['subscription_expires_at'];
    final limit = limitForTier(tier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => context.push('/profile/edit'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.primaryDark.withValues(alpha: 0.3),
                  child: Text(
                    (user?.email?.isNotEmpty == true ? user!.email![0] : '?').toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(user?.email ?? 'Пользователь', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Подписка', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Тариф: ${tier.toUpperCase()}', style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    limit < 0 ? 'Безлимит' : 'Лимит: $limit генераций/мес',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (expiresAt != null)
                    Text('Действует до: $expiresAt', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.push('/paywall'),
                    child: const Text('Улучшить план'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const InstagramSection(),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.card_giftcard_rounded),
                  title: const Text('Промокод'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.people_rounded),
                  title: const Text('Реферальный код'),
                  subtitle: Text('Поделиться кодом', style: Theme.of(context).textTheme.bodySmall),
                  trailing: const Icon(Icons.copy_rounded, size: 20),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.settings_rounded),
                  title: const Text('Настройки'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              await supabase.auth.signOut();
              if (context.mounted) context.go('/auth');
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Выйти'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.destructiveDark,
              side: const BorderSide(color: AppColors.destructiveDark),
            ),
          ),
        ],
      ),
    );
  }
}
