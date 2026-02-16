import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SpeedGauge extends StatelessWidget {
  final double value; // 0.0 to 1.0 (percent of max speed)
  final double maxSpeed; // e.g., 100 Mbps
  final String unit; // Mbps
  final String status; // 'IDLE', 'DOWNLOAD', 'UPLOAD'

  const SpeedGauge({
    super.key,
    required this.value,
    this.maxSpeed = 100,
    this.unit = 'Mbps',
    this.status = 'IDLE',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 250,
      child: CustomPaint(
        painter: _GaugePainter(
          percent: value.clamp(0.0, 1.0),
          primaryColor: status == 'UPLOAD' ? AppColors.periwinkle : AppColors.cyan,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                (value * maxSpeed).toStringAsFixed(1),
                style: const TextStyle(
                  fontFamily: 'SpaceMono', // Assuming font family, or just standard bold
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              if (status != 'IDLE')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (status == 'UPLOAD' ? AppColors.periwinkle : AppColors.cyan)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: status == 'UPLOAD' ? AppColors.periwinkle : AppColors.cyan,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double percent;
  final Color primaryColor;

  _GaugePainter({required this.percent, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // Background Arc
    final bgPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.butt;

    // Start angle: 135 degrees (bottom left)
    // Sweep angle: 270 degrees
    const startAngle = 135 * pi / 180;
    const sweepAngle = 270 * pi / 180;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Active Arc
    final activePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * percent,
      false,
      activePaint,
    );

    // Ticks
    final tickPaint = Paint()
      ..color = AppColors.background
      ..strokeWidth = 2;
    
    // Draw divider ticks every 10%
    for (int i = 1; i < 10; i++) {
        final angle = startAngle + (sweepAngle * (i / 10));
        final tickStart = Offset(
            center.dx + (radius - 10) * cos(angle),
            center.dy + (radius - 10) * sin(angle)
        );
        final tickEnd = Offset(
            center.dx + (radius + 10) * cos(angle),
            center.dy + (radius + 10) * sin(angle)
        );
        canvas.drawLine(tickStart, tickEnd, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.percent != percent || oldDelegate.primaryColor != primaryColor;
  }
}
