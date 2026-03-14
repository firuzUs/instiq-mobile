import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/supabase/supabase_client.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/content_plan/content_plan_screen.dart';
import '../screens/trends/trends_screen.dart';
import '../screens/stats/stats_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/strategy_chat/strategy_chat_screen.dart';
import '../screens/content_plan/generate_content_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/onboarding/blueprint_screen.dart';
import '../screens/paywall/paywall_screen.dart';
import '../screens/shell/main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final session = supabase.auth.currentSession;
      final isAuth = session != null;
      final isAuthRoute = state.matchedLocation == '/auth' || state.matchedLocation.startsWith('/auth');
      if (!isAuth && !isAuthRoute) return '/auth';
      if (isAuth && isAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (_, __) => const AuthScreen(),
      ),
      GoRoute(
        path: '/chat',
        builder: (_, __) => const StrategyChatScreen(),
      ),
      GoRoute(
        path: '/generate-content',
        builder: (_, __) => const GenerateContentScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/blueprint',
        builder: (_, __) => const BlueprintScreen(),
      ),
      GoRoute(
        path: '/paywall',
        builder: (_, __) => const PaywallScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                pageBuilder: (_, __) => const NoTransitionPage(child: HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/content',
                pageBuilder: (_, __) => const NoTransitionPage(child: ContentPlanScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/trends',
                pageBuilder: (_, __) => const NoTransitionPage(child: TrendsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stats',
                pageBuilder: (_, __) => const NoTransitionPage(child: StatsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (_, __) => const NoTransitionPage(child: ProfileScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
