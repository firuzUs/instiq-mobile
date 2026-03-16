import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/subscription_limits.dart';
import '../../core/analytics/analytics_service.dart';
import '../../core/supabase/supabase_client.dart';
import '../../widgets/glass_card.dart';

const _tiers = [
  ('free', 'Free', '0 ₽', '10 генераций/мес', ['Базовые функции'], false),
  ('creator', 'Creator', '1 290 ₽/мес', '100 генераций/мес', ['Всё из Free', 'Расширенная генерация'], true),
  ('pro', 'Pro', '2 690 ₽/мес', '300 генераций/мес', ['Всё из Creator', 'Приоритетная поддержка'], true),
  ('business', 'Business', '6 490 ₽/мес', 'Безлимит', ['Всё из Pro', 'API доступ'], true),
];

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const _PaywallBody();
}

class _PaywallBody extends ConsumerStatefulWidget {
  const _PaywallBody();

  @override
  ConsumerState<_PaywallBody> createState() => _PaywallBodyState();
}

class _PaywallBodyState extends ConsumerState<_PaywallBody> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.trackEvent('paywall_opened', properties: {'source': 'paywall_screen'});
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final currentTier = profileAsync.valueOrNull?['subscription_tier'] as String? ?? 'free';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Тарифы'),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _PromoField(onActivated: () => ref.invalidate(profileProvider)),
          const SizedBox(height: 24),
          ..._tiers.map((t) {
            final (id, name, price, limit, features, isPaid) = t;
            final isCurrent = currentTier.toLowerCase() == id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(name, style: Theme.of(context).textTheme.titleLarge),
                          if (isCurrent)
                            Chip(
                              label: const Text('Текущий план'),
                              backgroundColor: AppColors.primaryDark.withValues(alpha: 0.2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(price, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primaryDark)),
                      Text(limit, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 8),
                      ...(features as List<String>).map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(Icons.check_rounded, size: 16, color: AppColors.primaryDark),
                            const SizedBox(width: 8),
                            Text(f, style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      )),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: isCurrent
                              ? null
                              : () {
                                  if (isPaid) {
                                    AnalyticsService.trackEvent(
                                      'paywall_choose_clicked',
                                      properties: {'tier': id},
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Скоро будет доступно')),
                                    );
                                  }
                                },
                          child: Text(isCurrent ? 'Текущий план' : 'Выбрать'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PromoField extends StatefulWidget {
  final VoidCallback onActivated;

  const _PromoField({required this.onActivated});

  @override
  State<_PromoField> createState() => _PromoFieldState();
}

class _PromoFieldState extends State<_PromoField> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Промокод', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Введите промокод',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _loading ? null : _activate,
                  child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Применить'),
                ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _activate() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await supabase.functions.invoke('activate-promo', body: {'code': code});
      AnalyticsService.trackEvent('promo_activated', properties: {'code': code});
      widget.onActivated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Промокод активирован')));
      }
    } catch (e) {
      AnalyticsService.trackEvent('promo_activate_failed', properties: {'error': e.toString()});
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() => _loading = false);
    }
  }
}
