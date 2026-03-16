import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/project_provider.dart';
import '../../core/providers/instagram_provider.dart';
import '../../core/analytics/analytics_service.dart';
import '../../core/supabase/supabase_client.dart';
import '../../widgets/glass_card.dart';

final _usernameRegex = RegExp(r'^[a-zA-Z0-9._]+$');

class InstagramSection extends ConsumerStatefulWidget {
  const InstagramSection({super.key});

  @override
  ConsumerState<InstagramSection> createState() => _InstagramSectionState();
}

class _InstagramSectionState extends ConsumerState<InstagramSection> {
  final _usernameController = TextEditingController();
  bool _analyzing = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectId = ref.watch(currentProjectIdProvider);
    final projectsAsync = ref.watch(projectsListProvider);
    final effectiveProjectId = projectId ?? projectsAsync.valueOrNull?.firstOrNull?['id'] as String?;

    if (effectiveProjectId == null) return const SizedBox.shrink();

    final cacheAsync = ref.watch(instagramCacheProvider(effectiveProjectId));

    return cacheAsync.when(
      data: (cache) {
        if (cache != null && cache.isNotEmpty) {
          return _InstagramCard(
            cache: cache,
            projectId: effectiveProjectId,
            onRefresh: () => _refreshProfile(context, effectiveProjectId),
          );
        }
        return _InstagramUsernameForm(
          projectId: effectiveProjectId,
          usernameController: _usernameController,
          analyzing: _analyzing,
          error: _error,
          onAnalyze: () => _analyze(context, effectiveProjectId),
          onError: (e) => setState(() => _error = e),
          onAnalyzing: (v) => setState(() => _analyzing = v),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _analyze(BuildContext context, String projectId) async {
    final username = _usernameController.text.trim().toLowerCase().replaceAll('@', '');
    if (username.isEmpty) {
      setState(() => _error = 'Введите username');
      return;
    }
    if (!_usernameRegex.hasMatch(username)) {
      setState(() => _error = 'Только латиница, цифры, точка и подчёркивание');
      return;
    }
    setState(() {
      _error = null;
      _analyzing = true;
    });
    try {
      AnalyticsService.trackEvent(
        'instagram_analyze_started',
        projectId: projectId,
        properties: {'username': username},
      );
      await supabase.from('project_profiles').update({'instagram_username': username}).eq('project_id', projectId);
      await supabase.functions.invoke('instagram-profile', body: {'username': username, 'projectId': projectId});
      ref.invalidate(instagramCacheProvider(projectId));
      if (context.mounted) setState(() => _analyzing = false);
      AnalyticsService.trackEvent(
        'instagram_analyzed',
        projectId: projectId,
        properties: {'username': username},
      );
    } catch (e) {
      AnalyticsService.trackEvent(
        'instagram_analyze_failed',
        projectId: projectId,
        properties: {'username': username, 'error': e.toString()},
      );
      if (mounted) setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _analyzing = false;
      });
    }
  }

  Future<void> _refreshProfile(BuildContext context, String projectId) async {
    try {
      final pp = await supabase.from('project_profiles').select('instagram_username').eq('project_id', projectId).maybeSingle();
      final username = pp?['instagram_username'] as String?;
      if (username == null || username.isEmpty) return;
      AnalyticsService.trackEvent(
        'instagram_refresh_started',
        projectId: projectId,
        properties: {'username': username},
      );
      await supabase.functions.invoke('instagram-profile', body: {'username': username, 'projectId': projectId});
      ref.invalidate(instagramCacheProvider(projectId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Данные обновлены')));
      }
      AnalyticsService.trackEvent(
        'instagram_refreshed',
        projectId: projectId,
        properties: {'username': username},
      );
    } catch (_) {}
  }
}

class _InstagramUsernameForm extends StatelessWidget {
  final String projectId;
  final TextEditingController usernameController;
  final bool analyzing;
  final String? error;
  final VoidCallback onAnalyze;
  final void Function(String) onError;
  final void Function(bool) onAnalyzing;

  const _InstagramUsernameForm({
    required this.projectId,
    required this.usernameController,
    required this.analyzing,
    required this.error,
    required this.onAnalyze,
    required this.onError,
    required this.onAnalyzing,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Instagram', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Мы НЕ запрашиваем пароль. Анализ по публичному профилю.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'без @, только имя',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => onError(''),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: analyzing ? null : onAnalyze,
              icon: analyzing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.search_rounded, size: 18),
              label: Text(analyzing ? 'Анализ...' : 'Анализировать профиль'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstagramCard extends StatelessWidget {
  final Map<String, dynamic> cache;
  final String projectId;
  final VoidCallback onRefresh;

  const _InstagramCard({required this.cache, required this.projectId, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final picUrl = cache['profile_pic_url'] as String?;
    final fullName = cache['full_name'] as String?;
    final biography = cache['biography'] as String?;
    final category = cache['category'] as String?;
    final followers = cache['followers'];
    final following = cache['following'];
    final postsCount = cache['posts_count'];
    final avgEr = cache['avg_er'];
    final isVerified = cache['is_verified'] == true;
    final fetchedAt = cache['fetched_at'];

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Instagram', style: Theme.of(context).textTheme.titleMedium),
                if (isVerified) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.verified_rounded, size: 18, color: AppColors.primaryDark),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (picUrl != null && picUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: CachedNetworkImage(
                      imageUrl: picUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Icon(Icons.person_rounded, size: 48),
                      errorWidget: (_, __, ___) => const Icon(Icons.person_rounded, size: 48),
                    ),
                  )
                else
                  const CircleAvatar(radius: 24, child: Icon(Icons.person_rounded)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (fullName != null) Text(fullName, style: Theme.of(context).textTheme.titleSmall),
                      if (category != null) Text(category, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (followers != null) Text('Подписчики: $followers', style: Theme.of(context).textTheme.bodySmall),
                          if (following != null) Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Text('Подписок: $following', style: Theme.of(context).textTheme.bodySmall),
                          ),
                          if (postsCount != null) Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Text('Публикаций: $postsCount', style: Theme.of(context).textTheme.bodySmall),
                          ),
                        ],
                      ),
                      if (avgEr != null) Text('ER: $avgEr%', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            if (biography != null && biography.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(biography, style: Theme.of(context).textTheme.bodySmall, maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
            if (fetchedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Обновлено: $fetchedAt', style: Theme.of(context).textTheme.bodySmall),
              ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Обновить данные'),
            ),
          ],
        ),
      ),
    );
  }
}
