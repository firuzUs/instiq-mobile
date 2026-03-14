import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../supabase/supabase_client.dart';
import 'content_calendar_provider.dart';
import 'project_profile_provider.dart';

final currentProjectIdProvider = StateProvider<String?>((ref) => null);

final projectsListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = supabase.auth.currentUser;
  if (user == null) return [];
  final res = await supabase
      .from('projects')
      .select()
      .eq('user_id', user.id)
      .order('created_at');
  return List<Map<String, dynamic>>.from(res ?? []);
});

/// Текущий активный проект (объект) или первый из списка, если current не выбран.
final currentProjectProvider = Provider<Map<String, dynamic>?>((ref) {
  final currentId = ref.watch(currentProjectIdProvider);
  final list = ref.watch(projectsListProvider).valueOrNull;
  if (list == null || list.isEmpty) return null;
  if (currentId != null) {
    try {
      return list.firstWhere((p) => p['id'] == currentId);
    } catch (_) {}
  }
  return list.first;
});

/// Смена проекта: обновляет currentProjectId и инвалидирует зависимые провайдеры.
void switchProject(WidgetRef ref, String projectId) {
  ref.read(currentProjectIdProvider.notifier).state = projectId;
  ref.invalidate(contentCalendarProvider);
  ref.invalidate(projectProfileProvider);
  // strategyChatProvider и trendCoreProvider инвалидируем при использовании по projectId
}
