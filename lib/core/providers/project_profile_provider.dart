import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../supabase/supabase_client.dart';

/// Профиль проекта: ниша, цели и т.д. из project_profiles.
final projectProfileProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, projectId) async {
  final res = await supabase
      .from('project_profiles')
      .select()
      .eq('project_id', projectId)
      .maybeSingle();
  return res != null ? Map<String, dynamic>.from(res) : null;
});
