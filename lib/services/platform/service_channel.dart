import 'package:flutter/services.dart';

/// MethodChannel bridge to start/stop foreground service,
/// manage auto-start, and handle permissions.
class ServiceChannel {
  static const _channel = MethodChannel('com.netspeed/service');

  /// Start the speed monitor foreground service
  static Future<bool> startService() async {
    final result = await _channel.invokeMethod<bool>('startService');
    return result ?? false;
  }

  /// Stop the speed monitor foreground service
  static Future<bool> stopService() async {
    final result = await _channel.invokeMethod<bool>('stopService');
    return result ?? false;
  }

  /// Check if service is currently running
  static Future<bool> isServiceRunning() async {
    final result = await _channel.invokeMethod<bool>('isServiceRunning');
    return result ?? false;
  }

  /// Enable/disable auto-start on boot
  static Future<bool> setAutoStart(bool enabled) async {
    final result = await _channel.invokeMethod<bool>(
      'setAutoStart',
      {'enabled': enabled},
    );
    return result ?? false;
  }

  /// Check if usage stats permission is granted
  static Future<bool> hasUsagePermission() async {
    final result = await _channel.invokeMethod<bool>('hasUsagePermission');
    return result ?? false;
  }

  /// Open system usage access settings
  static Future<void> openUsageSettings() async {
    await _channel.invokeMethod<bool>('openUsageSettings');
  }

  /// Open battery optimization settings
  static Future<void> openBatterySettings() async {
    await _channel.invokeMethod<bool>('openBatterySettings');
  }
}
