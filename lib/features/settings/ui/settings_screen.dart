import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/platform/service_channel.dart';

/// Settings providers
final serviceEnabledProvider = StateProvider<bool>((ref) => false);
final autoStartProvider = StateProvider<bool>((ref) => false);

/// Settings screen with service controls, auto-start, and battery optimization.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final running = await ServiceChannel.isServiceRunning();
    final prefs = await SharedPreferences.getInstance();
    final autoStart = prefs.getBool('auto_start_on_boot') ?? false;

    if (mounted) {
      ref.read(serviceEnabledProvider.notifier).state = running;
      ref.read(autoStartProvider.notifier).state = autoStart;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceEnabled = ref.watch(serviceEnabledProvider);
    final autoStart = ref.watch(autoStartProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        children: [
          const SizedBox(height: 24),
          Text(
            'SETTINGS',
            style: theme.textTheme.headlineLarge?.copyWith(letterSpacing: 4),
          ),
          const SizedBox(height: 8),
          Text(
            'CONFIGURATION',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 32),

          // Status bar indicator toggle
          _SettingCard(
            title: 'STATUS BAR INDICATOR',
            subtitle: 'Show speed in notification bar',
            icon: Icons.speed,
            accentColor: AppColors.salmon,
            trailing: Switch(
              value: serviceEnabled,
              onChanged: _isLoading
                  ? null
                  : (value) async {
                      if (value) {
                        await ServiceChannel.startService();
                      } else {
                        await ServiceChannel.stopService();
                      }
                      ref.read(serviceEnabledProvider.notifier).state = value;
                    },
            ),
          ),
          const SizedBox(height: 12),

          // Auto-start on boot
          _SettingCard(
            title: 'AUTO-START ON BOOT',
            subtitle: 'Start monitoring when device boots',
            icon: Icons.restart_alt,
            accentColor: AppColors.periwinkle,
            trailing: Switch(
              value: autoStart,
              onChanged: _isLoading
                  ? null
                  : (value) async {
                      await ServiceChannel.setAutoStart(value);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('auto_start_on_boot', value);
                      ref.read(autoStartProvider.notifier).state = value;
                    },
            ),
          ),
          const SizedBox(height: 24),

          // Battery section
          Text(
            'BATTERY & PERMISSIONS',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.softYellow,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 12),

          // Usage access
          _SettingCard(
            title: 'USAGE ACCESS',
            subtitle: 'Required for data usage tracking',
            icon: Icons.data_usage,
            accentColor: AppColors.salmon,
            trailing: IconButton(
              icon: const Icon(
                Icons.open_in_new,
                size: 18,
                color: AppColors.textMuted,
              ),
              onPressed: () => ServiceChannel.openUsageSettings(),
            ),
          ),
          const SizedBox(height: 12),

          // Battery optimization
          _SettingCard(
            title: 'BATTERY OPTIMIZATION',
            subtitle: 'Disable to prevent background kills',
            icon: Icons.battery_saver,
            accentColor: AppColors.periwinkle,
            trailing: IconButton(
              icon: const Icon(
                Icons.open_in_new,
                size: 18,
                color: AppColors.textMuted,
              ),
              onPressed: () => ServiceChannel.openBatterySettings(),
            ),
          ),
          const SizedBox(height: 24),

          // Info card
          Container(
            decoration: AppTheme.brutalCard(
              borderColor: AppColors.softYellow.withOpacity(0.4),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.softYellow,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'NetSpeed uses minimal battery by adapting its polling interval. '
                    'When your screen is off, updates slow to every 4 seconds. '
                    'No wake locks are used.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Reset stats
          _SettingCard(
            title: 'RESET STATISTICS',
            subtitle: 'Clear all locally cached data',
            icon: Icons.delete_outline,
            accentColor: AppColors.error,
            trailing: IconButton(
              icon: Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
              ),
              onPressed: () => _showResetDialog(context),
            ),
          ),
          const SizedBox(height: 32),

          // Version
          Center(
            child: Text(
              'NETSPEED V1.0.0',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.border, width: 2),
        ),
        title: Text(
          'RESET DATA?',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.error,
              ),
        ),
        content: Text(
          'This will clear all locally cached usage data. System data is not affected.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'CANCEL',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              // Preserve onboarding complete flag
              await prefs.setBool('onboarding_complete', true);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(
              'RESET',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Widget trailing;

  const _SettingCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: AppTheme.brutalCard(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    letterSpacing: 1.5,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
