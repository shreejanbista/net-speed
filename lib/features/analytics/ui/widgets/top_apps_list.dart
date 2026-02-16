import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/speed_formatter.dart';
import '../../providers/app_usage_provider.dart';
import '../../../../services/platform/service_channel.dart';

enum _SortOrder { highToLow, lowToHigh }

class TopAppsList extends ConsumerStatefulWidget {
  final String timeRange;

  const TopAppsList({super.key, required this.timeRange});

  @override
  ConsumerState<TopAppsList> createState() => _TopAppsListState();
}

class _TopAppsListState extends ConsumerState<TopAppsList> with WidgetsBindingObserver {
  static const _pageSize = 6;
  int _visibleCount = _pageSize;
  _SortOrder _sortOrder = _SortOrder.highToLow;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(appUsageProvider(widget.timeRange));
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncApps = ref.watch(appUsageProvider(widget.timeRange));
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row: label + sort toggle
        Row(
          children: [
            Text(
              'TOP APPS',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.softYellow,
                letterSpacing: 2,
              ),
            ),
            const Spacer(),
            _SortToggle(
              order: _sortOrder,
              onChanged: (o) => setState(() {
                _sortOrder = o;
                _visibleCount = _pageSize; // reset pagination on sort change
              }),
            ),
          ],
        ),
        const SizedBox(height: 12),
        asyncApps.when(
          data: (apps) {
            if (apps.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No usage data found.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              );
            }

            // Apply sort
            final sorted = List<AppUsageItem>.from(apps);
            if (_sortOrder == _SortOrder.lowToHigh) {
              sorted.sort((a, b) => a.totalBytes.compareTo(b.totalBytes));
            }
            // highToLow is already the default from the provider

            final maxUsage = sorted
                .fold<int>(0, (max, a) => a.totalBytes > max ? a.totalBytes : max)
                .toDouble();
            final totalCount = sorted.length;
            final visible = sorted.take(_visibleCount).toList();

            return Column(
              children: [
                // App cards
                ...List.generate(visible.length, (index) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: index < visible.length - 1 ? 10 : 0),
                    child: _AppUsageCard(
                      app: visible[index],
                      maxUsage: maxUsage,
                      rank: index + 1,
                    ),
                  );
                }),

                // Show More / Show Less
                if (totalCount > _pageSize) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (_visibleCount < totalCount)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _visibleCount = (_visibleCount + _pageSize).clamp(0, totalCount);
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: AppTheme.brutalCard(),
                              child: Center(
                                child: Text(
                                  'SHOW MORE (${totalCount - _visibleCount} left)',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.salmon,
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (_visibleCount > _pageSize && _visibleCount < totalCount)
                        const SizedBox(width: 8),
                      if (_visibleCount > _pageSize)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _visibleCount = _pageSize;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: AppTheme.brutalCard(),
                              child: Center(
                                child: Text(
                                  'SHOW LESS',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.textMuted,
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.salmon),
            ),
          ),
          error: (e, s) {
            if (e is UsagePermissionException) {
              return _PermissionCard();
            }
            return Center(
              child: Text(
                'Error loading apps',
                style: theme.textTheme.labelMedium?.copyWith(color: AppColors.error),
              ),
            );
          },
        ),
      ],
    );
  }
}

// --- Sort Toggle ---

class _SortToggle extends StatelessWidget {
  final _SortOrder order;
  final ValueChanged<_SortOrder> onChanged;

  const _SortToggle({required this.order, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _item(_SortOrder.highToLow, Icons.arrow_downward, 'HIGH'),
          const VerticalDivider(width: 1, color: AppColors.border),
          _item(_SortOrder.lowToHigh, Icons.arrow_upward, 'LOW'),
        ],
      ),
    );
  }

  Widget _item(_SortOrder value, IconData icon, String label) {
    final selected = order == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        color: selected ? AppColors.salmon.withOpacity(0.2) : Colors.transparent,
        child: Row(
          children: [
            Icon(icon, size: 12, color: selected ? AppColors.salmon : AppColors.textMuted),
            const SizedBox(width: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: selected ? AppColors.salmon : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Permission Card ---

class _PermissionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.brutalAccentCard(accentColor: AppColors.softYellow),
      child: Column(
        children: [
          const Icon(Icons.lock_open_rounded, size: 40, color: AppColors.softYellow),
          const SizedBox(height: 12),
          Text(
            'PERMISSION NEEDED',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'To see which apps are using data, please grant Usage Access permission.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ServiceChannel.openUsageSettings(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.softYellow,
              foregroundColor: AppColors.background,
            ),
            child: const Text('GRANT ACCESS'),
          ),
        ],
      ),
    );
  }
}

// --- App Usage Card ---

class _AppUsageCard extends StatelessWidget {
  final AppUsageItem app;
  final double maxUsage;
  final int rank;

  const _AppUsageCard({required this.app, required this.maxUsage, this.rank = 0});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = maxUsage > 0 ? app.totalBytes / maxUsage : 0.0;

    final total = SpeedFormatter.formatBytes(app.totalBytes);
    final down = SpeedFormatter.formatBytes(app.downloadBytes);
    final up = SpeedFormatter.formatBytes(app.uploadBytes);

    return Container(
      decoration: AppTheme.brutalCard(),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              // Rank badge
              SizedBox(
                width: 20,
                child: Text(
                  '#$rank',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Icon
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 36,
                  height: 36,
                  color: AppColors.surface,
                  child: app.icon != null
                      ? Image.memory(app.icon!, fit: BoxFit.cover, width: 36, height: 36)
                      : const Icon(Icons.android, size: 18, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(width: 10),

              // Name and Bar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.appName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 5),
                    Stack(
                      children: [
                        Container(
                          height: 5,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: percent.clamp(0.01, 1.0),
                          child: Container(
                            height: 5,
                            decoration: BoxDecoration(
                              color: AppColors.salmon,
                              borderRadius: BorderRadius.circular(2.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Total Usage
              Text(
                total,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _stat(theme, Icons.arrow_downward, down, AppColors.cyan),
              _stat(theme, Icons.arrow_upward, up, AppColors.periwinkle),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(ThemeData theme, IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(
          text,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
