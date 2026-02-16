import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/speed_formatter.dart';

/// Stat tile for displaying data usage (download, upload, or total)
class UsageTile extends StatelessWidget {
  final String label;
  final int bytes;
  final Color accentColor;
  final IconData icon;

  const UsageTile({
    super.key,
    required this.label,
    required this.bytes,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final (value, unit) = SpeedFormatter.formatBytesSplit(bytes);
    final theme = Theme.of(context);

    return Container(
      decoration: AppTheme.brutalCard(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 16),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: accentColor,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: theme.textTheme.bodySmall?.copyWith(
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
