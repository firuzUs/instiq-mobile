import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../supabase/supabase_client.dart';

final instagramCacheProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, projectId) async {
  final res = await supabase
      .from('instagram_cache')
      .select()
      .eq('project_id', projectId)
      .maybeSingle();
  return res != null ? Map<String, dynamic>.from(res) : null;
});
