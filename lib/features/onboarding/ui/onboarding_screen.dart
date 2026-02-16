import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/platform/service_channel.dart';

/// First-launch onboarding flow.
/// Explains and requests permissions one at a time with context.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                children: List.generate(_totalPages, (i) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i <= _currentPage
                            ? AppColors.salmon
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),

            // Skip button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text(
                  'SKIP',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _WelcomePage(onNext: _nextPage),
                  _NotificationPage(onNext: _nextPage),
                  _UsageAccessPage(onNext: _nextPage),
                  _BatteryPage(onNext: _nextPage),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _OnboardingPage(
      icon: Icons.speed,
      iconColor: AppColors.salmon,
      title: 'NETSPEED',
      subtitle: 'REAL-TIME MONITOR',
      description:
          'Monitor your internet speed in real-time with a persistent '
          'notification showing download and upload speeds. Track your '
          'data usage and view detailed analytics.',
      buttonText: 'GET STARTED',
      onAction: onNext,
    );
  }
}

class _NotificationPage extends StatelessWidget {
  final VoidCallback onNext;
  const _NotificationPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _OnboardingPage(
      icon: Icons.notifications_active,
      iconColor: AppColors.periwinkle,
      title: 'NOTIFICATIONS',
      subtitle: 'SPEED IN YOUR STATUS BAR',
      description:
          'We need notification permission to show a persistent speed '
          'indicator in your status bar. This runs as a lightweight '
          'foreground service with minimal battery usage.',
      buttonText: 'ALLOW NOTIFICATIONS',
      onAction: () async {
        // Request notification permission via platform channel
        const platform = MethodChannel('com.netspeed/service');
        try {
          await platform.invokeMethod('requestNotificationPermission');
        } catch (_) {
          // Permission request may not be supported on older versions
        }
        onNext();
      },
    );
  }
}

class _UsageAccessPage extends StatelessWidget {
  final VoidCallback onNext;
  const _UsageAccessPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _OnboardingPage(
      icon: Icons.data_usage,
      iconColor: AppColors.softYellow,
      title: 'USAGE ACCESS',
      subtitle: 'DATA CONSUMPTION TRACKING',
      description:
          'To track your data usage, NetSpeed needs the Usage Access permission. '
          'This is a system-level permission that must be granted in Settings. '
          'Tap below to open Settings, find NetSpeed, and enable access.',
      buttonText: 'OPEN SETTINGS',
      onAction: () async {
        await ServiceChannel.openUsageSettings();
        // Give user time to grant permission in settings
        await Future.delayed(const Duration(seconds: 1));
        onNext();
      },
      secondaryButtonText: 'SKIP FOR NOW',
      onSecondary: onNext,
    );
  }
}

class _BatteryPage extends StatelessWidget {
  final VoidCallback onNext;
  const _BatteryPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _OnboardingPage(
      icon: Icons.battery_saver,
      iconColor: AppColors.salmon,
      title: 'BATTERY',
      subtitle: 'KEEP MONITORING ALIVE',
      description:
          'Some devices aggressively kill background apps. To ensure '
          'reliable speed monitoring, disable battery optimization for '
          'NetSpeed. Don\'t worry — we use adaptive polling and no wake locks '
          'to keep battery usage minimal.',
      buttonText: 'OPEN BATTERY SETTINGS',
      onAction: () async {
        await ServiceChannel.openBatterySettings();
        await Future.delayed(const Duration(seconds: 1));
        onNext();
      },
      secondaryButtonText: 'FINISH SETUP',
      onSecondary: onNext,
    );
  }
}

/// Reusable onboarding page template
class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String description;
  final String buttonText;
  final VoidCallback onAction;
  final String? secondaryButtonText;
  final VoidCallback? onSecondary;

  const _OnboardingPage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.buttonText,
    required this.onAction,
    this.secondaryButtonText,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: iconColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.5),
                  offset: const Offset(4, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 36),
          ),
          const SizedBox(height: 32),

          // Title
          Text(
            title,
            style: theme.textTheme.displaySmall?.copyWith(
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 32),

          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),

          const Spacer(flex: 3),

          // Primary button
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: AppTheme.brutalAccentCard(),
                child: Center(
                  child: Text(
                    buttonText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.salmon,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Secondary button (optional)
          if (secondaryButtonText != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onSecondary,
              child: Text(
                secondaryButtonText!,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
