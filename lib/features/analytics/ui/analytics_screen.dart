import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../data_usage/providers/usage_providers.dart';
import '../../data_usage/ui/widgets/usage_tile.dart';
import '../providers/chart_providers.dart';
import 'widgets/daily_chart.dart';
import 'widgets/weekly_chart.dart';
import 'widgets/monthly_chart.dart';

/// Analytics screen offering a unified view of charts and usage totals.
/// Merges previous DataUsageScreen functionality here.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filter = ref.watch(networkFilterProvider);

    return DefaultTabController(
      length: 3,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                children: [
                  Text(
                    'ANALYTICS',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      letterSpacing: 4,
                    ),
                  ),
                  const Spacer(),
                  // WiFi/Mobile Toggle on top bar
                  _MiniFilterToggle(
                    current: filter,
                    onChanged: (f) =>
                        ref.read(networkFilterProvider.notifier).state = f,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'USAGE & CHARTS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 3,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: AppTheme.brutalCard(),
              child: TabBar(
                indicatorColor: AppColors.salmon,
                indicatorWeight: 3,
                labelColor: AppColors.salmon,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.5,
                ),
                dividerHeight: 0,
                tabs: const [
                  Tab(text: 'DAILY'),
                  Tab(text: 'WEEKLY'),
                  Tab(text: 'MONTHLY'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Content
            Expanded(
              child: TabBarView(
                children: [
                  _DailyTab(),
                  _WeeklyTab(),
                  _MonthlyTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayUsageProvider);
    final chartAsync = ref.watch(hourlyUsageProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        _UsageSummary(
          title: 'TODAY\'S TOTAL',
          usageAsync: todayAsync,
        ),
        const SizedBox(height: 20),
        chartAsync.when(
          data: (data) => DailyChart(data: data),
          loading: () => _chartLoader(),
          error: (_, __) => _chartError(context),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _WeeklyTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekAsync = ref.watch(weekUsageProvider);
    final chartAsync = ref.watch(weeklyChartProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        _UsageSummary(
          title: 'THIS WEEK',
          usageAsync: weekAsync,
        ),
        const SizedBox(height: 20),
        chartAsync.when(
          data: (data) => WeeklyChart(data: data),
          loading: () => _chartLoader(),
          error: (_, __) => _chartError(context),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _MonthlyTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthAsync = ref.watch(monthUsageProvider);
    final chartAsync = ref.watch(monthlyChartProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        _UsageSummary(
          title: 'THIS MONTH',
          usageAsync: monthAsync,
        ),
        const SizedBox(height: 20),
        chartAsync.when(
          data: (data) => MonthlyChart(data: data),
          loading: () => _chartLoader(),
          error: (_, __) => _chartError(context),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Compact toggle for WiFi/Mobile/All
class _MiniFilterToggle extends StatelessWidget {
  final NetworkFilter current;
  final ValueChanged<NetworkFilter> onChanged;

  const _MiniFilterToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // We can cycle through them or show a popup. 
    // User asked for "wifi mobile toggle on the top". 
    // A simple cycle button or grouped toggle is best.
    
    // Let's use a segmented-like row.
    return Container(
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleItem(NetworkFilter.wifi, Icons.wifi),
          const VerticalDivider(width: 1, color: AppColors.border),
          _toggleItem(NetworkFilter.mobile, Icons.cell_tower),
          const VerticalDivider(width: 1, color: AppColors.border),
          _toggleItem(NetworkFilter.all, Icons.layers),
        ],
      ),
    );
  }

  Widget _toggleItem(NetworkFilter filter, IconData icon) {
    final isSelected = current == filter;
    return GestureDetector(
      onTap: () => onChanged(filter),
      child: Container(
        width: 36,
        color: isSelected ? AppColors.salmon.withOpacity(0.2) : Colors.transparent,
        child: Icon(
          icon,
          size: 16,
          color: isSelected ? AppColors.salmon : AppColors.textMuted,
        ),
      ),
    );
  }
}

class _UsageSummary extends StatelessWidget {
  final String title;
  final AsyncValue<dynamic> usageAsync;

  const _UsageSummary({required this.title, required this.usageAsync});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.softYellow,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        usageAsync.when(
          data: (usage) => Row(
            children: [
              Expanded(
                child: UsageTile(
                  label: 'Download',
                  bytes: usage.downloadBytes,
                  accentColor: AppColors.salmon,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: UsageTile(
                  label: 'Upload',
                  bytes: usage.uploadBytes,
                  accentColor: AppColors.periwinkle,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
          loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

Widget _chartLoader() {
  return const Center(
    child: SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: AppColors.salmon,
      ),
    ),
  );
}

Widget _chartError(BuildContext context) {
  return Center(
    child: Container(
      decoration: AppTheme.brutalCard(borderColor: AppColors.error),
      padding: const EdgeInsets.all(20),
      child: Text(
        'CHART DATA ERROR',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.error,
              letterSpacing: 1.5,
            ),
      ),
    ),
  );
}
