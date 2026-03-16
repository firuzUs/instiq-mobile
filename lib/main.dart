import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/supabase/supabase_client.dart';
import 'core/analytics/session_tracker.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  await SessionTracker.instance.start();
  runApp(const ProviderScope(child: InstIQApp()));
}

class InstIQApp extends ConsumerWidget {
  const InstIQApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'InstIQ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
