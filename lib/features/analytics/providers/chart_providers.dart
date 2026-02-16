import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/platform/usage_channel.dart';
import '../../data_usage/providers/usage_providers.dart';

/// Hourly usage for the daily chart (today)
final hourlyUsageProvider =
    FutureProvider.autoDispose<List<HourlyUsage>>((ref) async {
  final filter = ref.watch(networkFilterProvider);
  final networkType = switch (filter) {
    NetworkFilter.all => -1,
    NetworkFilter.wifi => 1,
    NetworkFilter.mobile => 0,
  };
  return UsageChannel.getHourlyUsage(
    networkType: networkType,
    dayOffset: 0,
  );
});

/// Daily usage for the weekly chart (last 7 days)
final weeklyChartProvider =
    FutureProvider.autoDispose<List<DailyUsage>>((ref) async {
  final filter = ref.watch(networkFilterProvider);
  final networkType = switch (filter) {
    NetworkFilter.all => -1,
    NetworkFilter.wifi => 1,
    NetworkFilter.mobile => 0,
  };
  return UsageChannel.getDailyUsage(networkType: networkType, days: 7);
});

/// Daily usage for the monthly chart (last 30 days)
final monthlyChartProvider =
    FutureProvider.autoDispose<List<DailyUsage>>((ref) async {
  final filter = ref.watch(networkFilterProvider);
  final networkType = switch (filter) {
    NetworkFilter.all => -1,
    NetworkFilter.wifi => 1,
    NetworkFilter.mobile => 0,
  };
  return UsageChannel.getDailyUsage(networkType: networkType, days: 30);
});
