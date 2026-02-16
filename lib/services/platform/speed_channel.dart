import 'dart:async';
import 'package:flutter/services.dart';

/// Speed reading data class
class SpeedReading {
  final int downloadSpeed; // bytes/sec
  final int uploadSpeed;   // bytes/sec
  final int totalRxBytes;
  final int totalTxBytes;
  final String networkType; // "wifi", "mobile", "ethernet", "none"

  const SpeedReading({
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.totalRxBytes,
    required this.totalTxBytes,
    required this.networkType,
  });

  factory SpeedReading.fromMap(Map<dynamic, dynamic> map) {
    return SpeedReading(
      downloadSpeed: (map['downloadSpeed'] as num?)?.toInt() ?? 0,
      uploadSpeed: (map['uploadSpeed'] as num?)?.toInt() ?? 0,
      totalRxBytes: (map['totalRxBytes'] as num?)?.toInt() ?? 0,
      totalTxBytes: (map['totalTxBytes'] as num?)?.toInt() ?? 0,
      networkType: (map['networkType'] as String?) ?? 'none',
    );
  }

  static const zero = SpeedReading(
    downloadSpeed: 0,
    uploadSpeed: 0,
    totalRxBytes: 0,
    totalTxBytes: 0,
    networkType: 'none',
  );
}

/// EventChannel bridge to native TrafficStats speed stream.
/// 
/// Lifecycle-aware: the Dart consumer should pause/resume listening
/// based on app lifecycle state. The native side uses adaptive polling
/// (1s screen-on, 4s screen-off).
class SpeedChannel {
  static const _channel = EventChannel('com.netspeed/speed');
  static Stream<SpeedReading>? _stream;

  /// Get the speed reading stream. Lazily created, shared across listeners.
  static Stream<SpeedReading> get speedStream {
    _stream ??= _channel
        .receiveBroadcastStream()
        .map((event) => SpeedReading.fromMap(event as Map<dynamic, dynamic>));
    return _stream!;
  }
}
