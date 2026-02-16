import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/speed_formatter.dart';

/// Neo-brutalist speed card displaying download or upload speed.
/// Large typography with animated value transitions.
class SpeedCard extends StatelessWidget {
  final String label;
  final int bytesPerSec;
  final Color accentColor;
  final IconData icon;

  const SpeedCard({
    super.key,
    required this.label,
    required this.bytesPerSec,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final value = SpeedFormatter.formatSpeedValue(bytesPerSec);
    final unit = SpeedFormatter.formatSpeedUnit(bytesPerSec);
    final theme = Theme.of(context);

    return Container(
      decoration: AppTheme.brutalCard(borderColor: accentColor),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 18),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: accentColor,
                  letterSpacing: 2.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: bytesPerSec.toDouble()),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Text(
                    SpeedFormatter.formatSpeedValue(value.toInt()),
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.0,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  unit,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
