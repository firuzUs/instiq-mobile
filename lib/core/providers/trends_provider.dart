import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../supabase/supabase_client.dart';

final savedTrendsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = supabase.auth.currentUser;
  if (user == null) return [];
  final res = await supabase
      .from('saved_trends')
      .select()
      .eq('user_id', user.id)
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(res ?? []);
});

final trendCoresProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, projectId) async {
  final user = supabase.auth.currentUser;
  if (user == null) return null;
  final res = await supabase
      .from('trend_cores')
      .select()
      .eq('user_id', user.id)
      .eq('project_id', projectId)
      .maybeSingle();
  return res != null ? Map<String, dynamic>.from(res) : null;
});

/// Сохранение тренда (для поиска/радара). После вставки инвалидировать savedTrendsProvider и onboarding.
Future<void> saveTrend(
  String userId,
  String projectId, {
  String? shortcode,
  String? videoUrl,
  String? thumbnailUrl,
  String? caption,
  String? ownerUsername,
  int? views,
  int? likes,
  int? comments,
  double? erPercent,
  int? duration,
  String? musicTitle,
  String? musicArtist,
}) async {
  await supabase.from('saved_trends').insert({
    'user_id': userId,
    'project_id': projectId,
    if (shortcode != null) 'shortcode': shortcode,
    if (videoUrl != null) 'video_url': videoUrl,
    if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
    if (caption != null) 'caption': caption,
    if (ownerUsername != null) 'owner_username': ownerUsername,
    if (views != null) 'views': views,
    if (likes != null) 'likes': likes,
    if (comments != null) 'comments': comments,
    if (erPercent != null) 'er_percent': erPercent,
    if (duration != null) 'duration': duration,
    if (musicTitle != null) 'music_title': musicTitle,
    if (musicArtist != null) 'music_artist': musicArtist,
  });
}
