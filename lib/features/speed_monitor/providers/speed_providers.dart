import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/platform/speed_channel.dart';

/// Current speed reading provider — streams from native EventChannel.
/// Lifecycle-aware: only active while a listener exists.
final speedStreamProvider = StreamProvider.autoDispose<SpeedReading>((ref) {
  return SpeedChannel.speedStream;
});

/// Last 60 speed readings for the mini real-time chart.
/// Kept in memory — no persistence needed.
final speedHistoryProvider =
    StateNotifierProvider.autoDispose<SpeedHistoryNotifier, List<SpeedReading>>(
  (ref) {
    final notifier = SpeedHistoryNotifier();
    final subscription = ref.listen(speedStreamProvider, (prev, next) {
      next.whenData((reading) => notifier.addReading(reading));
    });
    return notifier;
  },
);

class SpeedHistoryNotifier extends StateNotifier<List<SpeedReading>> {
  SpeedHistoryNotifier() : super([]);

  static const maxHistory = 60; // 60 seconds of history

  void addReading(SpeedReading reading) {
    final newList = [...state, reading];
    if (newList.length > maxHistory) {
      newList.removeRange(0, newList.length - maxHistory);
    }
    state = newList;
  }

  void clear() => state = [];
}
