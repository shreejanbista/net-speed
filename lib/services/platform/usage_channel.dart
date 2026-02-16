import 'dart:typed_data';
import 'package:flutter/services.dart';

/// Data usage reading from NetworkStatsManager
class UsageData {
  final int downloadBytes;
  final int uploadBytes;
  final int totalBytes;
  final bool hasError;

  const UsageData({
    required this.downloadBytes,
    required this.uploadBytes,
    required this.totalBytes,
    this.hasError = false,
  });

  factory UsageData.fromMap(Map<dynamic, dynamic> map) {
    return UsageData(
      downloadBytes: (map['downloadBytes'] as num?)?.toInt() ?? 0,
      uploadBytes: (map['uploadBytes'] as num?)?.toInt() ?? 0,
      totalBytes: (map['totalBytes'] as num?)?.toInt() ?? 0,
      hasError: (map['error'] as num?)?.toInt() != 0,
    );
  }

  static const zero = UsageData(
    downloadBytes: 0,
    uploadBytes: 0,
    totalBytes: 0,
  );
}

/// Hourly usage data point (for daily chart)
class HourlyUsage {
  final int hour;
  final int downloadBytes;
  final int uploadBytes;

  const HourlyUsage({
    required this.hour,
    required this.downloadBytes,
    required this.uploadBytes,
  });

  int get totalBytes => downloadBytes + uploadBytes;

  factory HourlyUsage.fromMap(Map<dynamic, dynamic> map) {
    return HourlyUsage(
      hour: (map['hour'] as num?)?.toInt() ?? 0,
      downloadBytes: (map['downloadBytes'] as num?)?.toInt() ?? 0,
      uploadBytes: (map['uploadBytes'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Daily usage data point (for weekly/monthly charts)
class DailyUsage {
  final int dayOffset;
  final int downloadBytes;
  final int uploadBytes;

  const DailyUsage({
    required this.dayOffset,
    required this.downloadBytes,
    required this.uploadBytes,
  });

  int get totalBytes => downloadBytes + uploadBytes;

  factory DailyUsage.fromMap(Map<dynamic, dynamic> map) {
    return DailyUsage(
      dayOffset: (map['day'] as num?)?.toInt() ?? 0,
      downloadBytes: (map['downloadBytes'] as num?)?.toInt() ?? 0,
      uploadBytes: (map['uploadBytes'] as num?)?.toInt() ?? 0,
    );
  }
}

/// MethodChannel bridge to query data usage from NetworkStatsManager.
class UsageChannel {
  static const _channel = MethodChannel('com.netspeed/usage');

  /// Get usage for a time range and network type.
  /// networkType: -1 = all, 0 = mobile, 1 = wifi
  /// timeRange: "today", "week", "month"
  static Future<UsageData> getUsage({
    int networkType = -1,
    String timeRange = 'today',
  }) async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'getUsage',
      {'networkType': networkType, 'timeRange': timeRange},
    );
    if (result == null) return UsageData.zero;
    return UsageData.fromMap(result);
  }

  /// Get hourly breakdown for a specific day.
  /// dayOffset: 0 = today, 1 = yesterday, etc.
  static Future<List<HourlyUsage>> getHourlyUsage({
    int networkType = -1,
    int dayOffset = 0,
  }) async {
    final result = await _channel.invokeMethod<List<dynamic>>(
      'getHourlyUsage',
      {'networkType': networkType, 'dayOffset': dayOffset},
    );
    if (result == null) return [];
    return result
        .map((e) => HourlyUsage.fromMap(e as Map<dynamic, dynamic>))
        .toList();
  }

  /// Get daily totals for the last N days.
  static Future<List<DailyUsage>> getDailyUsage({
    int networkType = -1,
    int days = 7,
  }) async {
    final result = await _channel.invokeMethod<List<dynamic>>(
      'getDailyUsage',
      {'networkType': networkType, 'days': days},
    );
    if (result == null) return [];
    return result
        .map((e) => DailyUsage.fromMap(e as Map<dynamic, dynamic>))
        .toList();
  }

  /// Get per-app usage breakdown.
  static Future<List<AppUsage>> getAppUsage({
    int networkType = -1,
    String timeRange = 'today',
  }) async {
    final result = await _channel.invokeMethod<List<dynamic>>(
      'getAppUsage',
      {'networkType': networkType, 'timeRange': timeRange},
    );
    if (result == null) return [];
    return result
        .map((e) => AppUsage.fromMap(e as Map<dynamic, dynamic>))
        .toList();
  }
}

/// Per-app data usage (includes metadata from native PackageManager)
class AppUsage {
  final String packageName;
  final String appName;
  final Uint8List? icon;
  final int uid;
  final int downloadBytes;
  final int uploadBytes;
  final int totalBytes;

  const AppUsage({
    required this.packageName,
    required this.appName,
    this.icon,
    required this.uid,
    required this.downloadBytes,
    required this.uploadBytes,
    required this.totalBytes,
  });

  factory AppUsage.fromMap(Map<dynamic, dynamic> map) {
    return AppUsage(
      packageName: map['packageName'] as String? ?? 'unknown',
      appName: map['appName'] as String? ?? map['packageName'] as String? ?? 'Unknown',
      icon: map['icon'] as Uint8List?,
      uid: (map['uid'] as num?)?.toInt() ?? 0,
      downloadBytes: (map['downloadBytes'] as num?)?.toInt() ?? 0,
      uploadBytes: (map['uploadBytes'] as num?)?.toInt() ?? 0,
      totalBytes: (map['totalBytes'] as num?)?.toInt() ?? 0,
    );
  }
}

