import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../supabase/supabase_client.dart';

/// Параметры для загрузки контента (projectId, weekStart, weekEnd).
typedef ContentCalendarParams = (String?, String, String);

/// Загрузка контента за период для текущего проекта.
final contentCalendarProvider = FutureProvider.family<List<Map<String, dynamic>>, ContentCalendarParams>((ref, params) async {
  final (projectId, weekStart, weekEnd) = params;
  final user = supabase.auth.currentUser;
  if (user == null || projectId == null) return [];
  final res = await supabase
      .from('content_calendar')
      .select()
      .eq('user_id', user.id)
      .eq('project_id', projectId)
      .gte('planned_date', weekStart)
      .lte('planned_date', weekEnd)
      .order('planned_date')
      .order('sequence_order');
  return List<Map<String, dynamic>>.from(res ?? []);
});
