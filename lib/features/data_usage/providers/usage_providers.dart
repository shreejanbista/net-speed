import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/platform/usage_channel.dart';

/// Network type filter for usage data
enum NetworkFilter { all, wifi, mobile }

/// Currently selected network filter
final networkFilterProvider = StateProvider<NetworkFilter>((ref) => NetworkFilter.all);

int _networkTypeValue(NetworkFilter filter) {
  switch (filter) {
    case NetworkFilter.all: return -1;
    case NetworkFilter.wifi: return 1;
    case NetworkFilter.mobile: return 0;
  }
}

/// Today's usage data
final todayUsageProvider = FutureProvider.autoDispose<UsageData>((ref) async {
  final filter = ref.watch(networkFilterProvider);
  return UsageChannel.getUsage(
    networkType: _networkTypeValue(filter),
    timeRange: 'today',
  );
});

/// This week's usage data
final weekUsageProvider = FutureProvider.autoDispose<UsageData>((ref) async {
  final filter = ref.watch(networkFilterProvider);
  return UsageChannel.getUsage(
    networkType: _networkTypeValue(filter),
    timeRange: 'week',
  );
});

/// This month's usage data
final monthUsageProvider = FutureProvider.autoDispose<UsageData>((ref) async {
  final filter = ref.watch(networkFilterProvider);
  return UsageChannel.getUsage(
    networkType: _networkTypeValue(filter),
    timeRange: 'month',
  );
});
