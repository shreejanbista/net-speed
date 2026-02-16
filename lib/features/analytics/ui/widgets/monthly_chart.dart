import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/platform/usage_channel.dart';
import '../../../../core/utils/speed_formatter.dart';

/// Monthly trend chart — line chart showing last 30 days.
class MonthlyChart extends StatelessWidget {
  final List<DailyUsage> data;

  const MonthlyChart({super.key, required this.data});

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
              'THIS MONTH — 30 DAY TREND',
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
                      interval: 7,
                      getTitlesWidget: (value, meta) {
                        final dayNum = (30 - value.toInt());
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${dayNum}d',
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
                maxX: (data.length - 1).toDouble(),
                minY: 0,
                lineBarsData: [
                  _lineBar(
                    List.generate(data.length, (i) => FlSpot(
                      i.toDouble(),
                      data[i].totalBytes.toDouble(),
                    )),
                    AppColors.salmon,
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
      curveSmoothness: 0.25,
      color: color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.02),
          ],
        ),
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
