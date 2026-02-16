import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/platform/usage_channel.dart';
import '../../../services/platform/service_channel.dart';
import '../../data_usage/providers/usage_providers.dart';

class UsagePermissionException implements Exception {}

/// App usage data model combined with display info
class AppUsageItem {
  final String packageName;
  final String appName;
  final Uint8List? icon;
  final int downloadBytes;
  final int uploadBytes;
  final int totalBytes;

  const AppUsageItem({
    required this.packageName,
    required this.appName,
    this.icon,
    required this.downloadBytes,
    required this.uploadBytes,
    required this.totalBytes,
  });
}

/// Provider for list of apps sorted by usage for the given time range
final appUsageProvider =
    FutureProvider.autoDispose.family<List<AppUsageItem>, String>((ref, timeRange) async {
  
  // 0. Check Permission
  final hasPermission = await ServiceChannel.hasUsagePermission();
  if (!hasPermission) {
    throw UsagePermissionException();
  }

  final filter = ref.watch(networkFilterProvider);
  final networkType = switch (filter) {
    NetworkFilter.all => -1,
    NetworkFilter.wifi => 1,
    NetworkFilter.mobile => 0,
  };

  // 1. Fetch raw usage from Android (includes appName + icon from native side)
  final rawList = await UsageChannel.getAppUsage(
    networkType: networkType,
    timeRange: timeRange,
  );

  if (rawList.isEmpty) return [];

  // 2. Map to AppUsageItem (metadata already resolved natively)
  final List<AppUsageItem> result = [];
  
  for (var usage in rawList) {
    if (usage.totalBytes <= 0) continue;

    result.add(AppUsageItem(
      packageName: usage.packageName,
      appName: usage.appName,
      icon: usage.icon,
      downloadBytes: usage.downloadBytes,
      uploadBytes: usage.uploadBytes,
      totalBytes: usage.totalBytes,
    ));
  }
  
  // Sort descending by total
  result.sort((a, b) => b.totalBytes.compareTo(a.totalBytes));

  return result;
});
