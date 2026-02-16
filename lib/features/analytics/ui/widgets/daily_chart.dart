import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/platform/usage_channel.dart';
import '../../../../core/utils/speed_formatter.dart';

/// Daily usage line chart with hourly breakdowns (24 hours).
class DailyChart extends StatelessWidget {
  final List<HourlyUsage> data;

  const DailyChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return _emptyState(context);

    final maxY = data.fold<double>(
      0,
      (max, e) => e.totalBytes > max ? e.totalBytes.toDouble() : max,
    );

    return Container(
      height: 280,
      decoration: AppTheme.brutalCard(),
      padding: const EdgeInsets.fromLTRB(4, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              'TODAY — HOURLY',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.softYellow,
                    letterSpacing: 2,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY / 4 : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border.withOpacity(0.3),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      maxIncluded: false,
                      minIncluded: false,
                      interval: maxY > 0 ? maxY / 3 : 1,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            SpeedFormatter.formatBytes(value.toInt())
                                .replaceAll(' ', '\n'),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 6,
                      getTitlesWidget: (value, meta) {
                        final hour = value.toInt();
                        if (hour % 6 != 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${hour.toString().padLeft(2, '0')}:00',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        return LineTooltipItem(
                          SpeedFormatter.formatBytes(spot.y.toInt()),
                          const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                minX: 0,
                maxX: 23,
                minY: 0,
                lineBarsData: [
                  _lineBar(
                    data.map((e) => FlSpot(
                          e.hour.toDouble(),
                          e.downloadBytes.toDouble(),
                        )).toList(),
                    AppColors.salmon,
                  ),
                  _lineBar(
                    data.map((e) => FlSpot(
                          e.hour.toDouble(),
                          e.uploadBytes.toDouble(),
                        )).toList(),
                    AppColors.periwinkle,
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 300),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _lineBar(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.3,
      color: color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.08),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Container(
      height: 280,
      decoration: AppTheme.brutalCard(),
      child: Center(
        child: Text(
          'NO DATA',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 3,
              ),
        ),
      ),
    );
  }
}
