import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/platform/speed_channel.dart';
import '../../../../core/utils/speed_formatter.dart';
/// Mini real-time line chart showing last 60 seconds of speed activity.
/// Lightweight rendering — uses simple line chart with minimal decorations.
class MiniSpeedChart extends StatelessWidget {
  final List<SpeedReading> history;

  const MiniSpeedChart({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: AppTheme.brutalCard(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'LAST 60S',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                      letterSpacing: 2,
                    ),
              ),
              const Spacer(),
              _legendDot(AppColors.salmon, 'DL'),
              const SizedBox(width: 12),
              _legendDot(AppColors.periwinkle, 'UL'),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: history.length < 2
                ? Center(
                    child: Text(
                      'COLLECTING DATA...',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textMuted,
                            letterSpacing: 1.5,
                          ),
                    ),
                  )
                : _buildChart(),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    final downloadSpots = <FlSpot>[];
    final uploadSpots = <FlSpot>[];

    for (int i = 0; i < history.length; i++) {
      // Convert to KB/s for readable Y-axis
      final dlKb = history[i].downloadSpeed / 1024.0;
      final ulKb = history[i].uploadSpeed / 1024.0;
      downloadSpots.add(FlSpot(i.toDouble(), dlKb));
      uploadSpots.add(FlSpot(i.toDouble(), ulKb));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink(); // Hide 0
                return Text(
                  '${value.toInt()} KB', // Simple KB/s label
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        clipData: const FlClipData.all(),
        minX: 0,
        maxX: 59,
        minY: 0,
        lineBarsData: [
          _line(downloadSpots, AppColors.salmon),
          _line(uploadSpots, AppColors.periwinkle),
        ],
      ),
      duration: const Duration(milliseconds: 150),
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.2,
      color: color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.08),
      ),
    );
  }
}
