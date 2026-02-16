import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/speed_test_provider.dart';
import 'widgets/speed_gauge.dart';

class SpeedTestScreen extends ConsumerWidget {
  const SpeedTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(speedTestProvider);
    final theme = Theme.of(context);

    // Max speed for gauge scaling (e.g. 100 Mbps or 1000 Mbps?)
    // Adapt based on speed? For now fixed 100.
    const double maxGaugeSpeed = 100.0;

    return SafeArea(
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              'SPEED TEST',
              style: theme.textTheme.headlineLarge?.copyWith(
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'CHECK YOUR CONNECTION',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 3,
              ),
            ),
            const Spacer(),
            
            // Gauge
            SpeedGauge(
              value: state.downloadSpeed / maxGaugeSpeed,
              maxSpeed: maxGaugeSpeed,
              unit: 'Mbps',
              status: state.status == TestStatus.download
                  ? 'DOWNLOAD'
                  : state.status == TestStatus.complete
                      ? 'COMPLETE'
                      : 'IDLE',
            ),
            
            const Spacer(),

            // Results Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                   _ResultItem(
                     label: 'DOWNLOAD',
                     value: state.status == TestStatus.download 
                         ? '0.0' 
                         : state.downloadSpeed.toStringAsFixed(1),
                     unit: 'Mbps',
                     color: AppColors.cyan,
                   ),
                   // Upload not implemented yet, placeholder
                   _ResultItem(
                     label: 'UPLOAD',
                     value: state.uploadSpeed.toStringAsFixed(1),
                     unit: 'Mbps',
                     color: AppColors.periwinkle,
                   ),
                   _ResultItem(
                     label: 'PING',
                     value: state.ping == 0 ? '--' : state.ping.toString(),
                     unit: 'ms',
                     color: AppColors.softYellow,
                   ),
                ],
              ),
            ),

            const Spacer(),

            // Start Button
            Padding(
              padding: const EdgeInsets.only(bottom: 120), // Above nav bar
              child: SizedBox(
                width: 200,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (state.status == TestStatus.download) {
                      ref.read(speedTestProvider.notifier).stopTest();
                    } else {
                      ref.read(speedTestProvider.notifier).startTest();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.status == TestStatus.download
                        ? AppColors.error // Red for stop
                        : AppColors.cyan,
                    foregroundColor: AppColors.background,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    state.status == TestStatus.download ? 'STOP TEST' : 'START TEST',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _ResultItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.speed_rounded, color: color, size: 20), // Or varied icons
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          unit,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
