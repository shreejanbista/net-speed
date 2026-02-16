import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/speed_providers.dart';
import 'widgets/speed_card.dart';
import 'widgets/mini_chart.dart';

/// Main speed dashboard — the home screen.
/// Shows real-time download/upload speed, network type, and a mini chart.
class SpeedDashboardScreen extends ConsumerWidget {
  const SpeedDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speedAsync = ref.watch(speedStreamProvider);
    final history = ref.watch(speedHistoryProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            // Title bar
            Row(
              children: [
                Text(
                  'NETSPEED',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    letterSpacing: 4,
                  ),
                ),
                const Spacer(),
                // Network type badge
                speedAsync.when(
                  data: (reading) => _NetworkBadge(
                    networkType: reading.networkType,
                  ),
                  loading: () => _NetworkBadge(networkType: 'none'),
                  error: (_, __) => _NetworkBadge(networkType: 'none'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'REAL-TIME MONITOR',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 32),

            // Speed cards
            speedAsync.when(
              data: (reading) => Column(
                children: [
                  SpeedCard(
                    label: 'Download',
                    bytesPerSec: reading.downloadSpeed,
                    accentColor: AppColors.salmon,
                    icon: Icons.arrow_downward_rounded,
                  ),
                  const SizedBox(height: 16),
                  SpeedCard(
                    label: 'Upload',
                    bytesPerSec: reading.uploadSpeed,
                    accentColor: AppColors.periwinkle,
                    icon: Icons.arrow_upward_rounded,
                  ),
                ],
              ),
              loading: () => Column(
                children: [
                  SpeedCard(
                    label: 'Download',
                    bytesPerSec: 0,
                    accentColor: AppColors.salmon,
                    icon: Icons.arrow_downward_rounded,
                  ),
                  const SizedBox(height: 16),
                  SpeedCard(
                    label: 'Upload',
                    bytesPerSec: 0,
                    accentColor: AppColors.periwinkle,
                    icon: Icons.arrow_upward_rounded,
                  ),
                ],
              ),
              error: (error, _) => Container(
                decoration: AppTheme.brutalCard(borderColor: AppColors.error),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'SPEED MONITOR ERROR',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Mini real-time chart
            Expanded(
              child: MiniSpeedChart(history: history),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Network type badge (WiFi, Mobile, etc.)
class _NetworkBadge extends StatelessWidget {
  final String networkType;

  const _NetworkBadge({required this.networkType});

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (networkType) {
      'wifi' => (Icons.wifi, 'WIFI', AppColors.softYellow),
      'mobile' => (Icons.cell_tower, 'MOBILE', AppColors.salmon),
      'ethernet' => (Icons.cable, 'ETH', AppColors.periwinkle),
      _ => (Icons.signal_wifi_off, 'OFFLINE', AppColors.textMuted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
