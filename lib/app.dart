import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

/// Root app widget. Checks onboarding status and configures theme + routing.
class NetSpeedApp extends ConsumerStatefulWidget {
  const NetSpeedApp({super.key});

  @override
  ConsumerState<NetSpeedApp> createState() => _NetSpeedAppState();
}

class _NetSpeedAppState extends ConsumerState<NetSpeedApp> {
  late Future<bool> _onboardingFuture;

  @override
  void initState() {
    super.initState();
    _onboardingFuture = _checkOnboarding();
  }

  Future<bool> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('onboarding_complete') ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _onboardingFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final router = createRouter(snapshot.data!);

        return MaterialApp.router(
          title: 'NetSpeed',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          routerConfig: router,
        );
      },
    );
  }
}
