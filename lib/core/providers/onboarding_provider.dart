import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../supabase/supabase_client.dart';
import 'profile_provider.dart';

/// Проверка завершения шагов Creator Journey по FLUTTER_DEV_BRIEF и US-2.
final onboardingProgressProvider = FutureProvider<OnboardingProgress>((ref) async {
  final profile = await ref.read(profileProvider.future);
  final user = supabase.auth.currentUser;
  if (user == null || profile == null) {
    return OnboardingProgress(step1: false, step2: false, step3: false, step4: false);
  }

  final step1 = _isStep1Done(profile);
  final projectId = await _getFirstProjectId(user.id);
  if (projectId == null) {
    return OnboardingProgress(step1: step1, step2: false, step3: false, step4: false);
  }

  final step2 = await _isStep2Done(projectId);
  final step3 = await _isStep3Done(projectId);
  final step4 = await _isStep4Done(user.id);

  return OnboardingProgress(
    step1: step1,
    step2: step2,
    step3: step3,
    step4: step4,
  );
});

bool _isStep1Done(Map<String, dynamic> profile) {
  final bio = profile['bio'] as String?;
  return bio != null && bio.length >= 100 && bio.length <= 3000;
}

Future<String?> _getFirstProjectId(String userId) async {
  final res = await supabase
      .from('projects')
      .select('id')
      .eq('user_id', userId)
      .order('created_at')
      .limit(1)
      .maybeSingle();
  return res?['id'] as String?;
}

Future<bool> _isStep2Done(String projectId) async {
  final res = await supabase
      .from('author_blueprints')
      .select('id')
      .eq('project_id', projectId)
      .maybeSingle();
  return res != null;
}

Future<bool> _isStep3Done(String projectId) async {
  final res = await supabase
      .from('content_calendar')
      .select('id')
      .eq('project_id', projectId)
      .limit(1)
      .maybeSingle();
  return res != null;
}

Future<bool> _isStep4Done(String userId) async {
  final saved = await supabase
      .from('saved_trends')
      .select('id')
      .eq('user_id', userId)
      .limit(1)
      .maybeSingle();
  if (saved != null) return true;
  final cores = await supabase
      .from('trend_cores')
      .select('id')
      .eq('user_id', userId)
      .limit(1)
      .maybeSingle();
  return cores != null;
}

class OnboardingProgress {
  final bool step1;
  final bool step2;
  final bool step3;
  final bool step4;

  OnboardingProgress({
    required this.step1,
    required this.step2,
    required this.step3,
    required this.step4,
  });

  bool get allDone => step1 && step2 && step3 && step4;
}
