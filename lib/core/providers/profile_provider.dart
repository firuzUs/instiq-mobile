import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../supabase/supabase_client.dart';

final profileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = supabase.auth.currentUser;
  if (user == null) return null;
  final res = await supabase
      .from('profiles')
      .select()
      .eq('user_id', user.id)
      .maybeSingle();
  return res;
});
