import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/speed_monitor/ui/speed_dashboard_screen.dart';

import '../../features/analytics/ui/analytics_screen.dart';
import '../../features/settings/ui/settings_screen.dart';
import '../../features/speed_test/ui/speed_test_screen.dart';
import '../../features/onboarding/ui/onboarding_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/widgets/floating_nav_bar.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(bool showOnboarding) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: showOnboarding ? '/onboarding' : '/',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const SpeedDashboardScreen(),
            ),
          ]),

          StatefulShellBranch(routes: [
            GoRoute(
              path: '/speed-test',
              builder: (context, state) => const SpeedTestScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/analytics',
              builder: (context, state) => const AnalyticsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
}

/// App shell with bottom navigation bar
class _AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _AppShell({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      extendBody: true, // Content behind navbar
      bottomNavigationBar: FloatingNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
