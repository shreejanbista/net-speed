import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class SpeedGauge extends StatefulWidget {
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
  State<SpeedGauge> createState() => _SpeedGaugeState();
}

class _SpeedGaugeState extends State<SpeedGauge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _oldValue = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(begin: 0.0, end: widget.value)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant SpeedGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _oldValue = _animation.value;
      _animation = Tween<double>(begin: _oldValue, end: widget.value)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final animatedValue = _animation.value.clamp(0.0, 1.0);
        return SizedBox(
          width: 250,
          height: 250,
          child: CustomPaint(
            painter: _GaugePainter(
              percent: animatedValue,
              primaryColor: widget.status == 'UPLOAD' ? AppColors.periwinkle : AppColors.cyan,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (widget.value * widget.maxSpeed).toStringAsFixed(1),
                    style: GoogleFonts.spaceMono(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    widget.unit,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.status != 'IDLE')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (widget.status == 'UPLOAD'
                                ? AppColors.periwinkle
                                : AppColors.cyan)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: widget.status == 'UPLOAD'
                              ? AppColors.periwinkle
                              : AppColors.cyan,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
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

    for (int i = 1; i < 10; i++) {
      final angle = startAngle + (sweepAngle * (i / 10));
      final tickStart = Offset(
        center.dx + (radius - 10) * cos(angle),
        center.dy + (radius - 10) * sin(angle),
      );
      final tickEnd = Offset(
        center.dx + (radius + 10) * cos(angle),
        center.dy + (radius + 10) * sin(angle),
      );
      canvas.drawLine(tickStart, tickEnd, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.percent != percent || oldDelegate.primaryColor != primaryColor;
  }
}
