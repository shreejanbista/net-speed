import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:math';

enum TestStatus { idle, download, upload, complete, error }

class SpeedTestState {
  final TestStatus status;
  final double downloadSpeed; // Mbps
  final double uploadSpeed; // Mbps
  final int ping; // ms
  final double progress; // 0.0 to 1.0

  const SpeedTestState({
    this.status = TestStatus.idle,
    this.downloadSpeed = 0.0,
    this.uploadSpeed = 0.0,
    this.ping = 0,
    this.progress = 0.0,
  });

  SpeedTestState copyWith({
    TestStatus? status,
    double? downloadSpeed,
    double? uploadSpeed,
    int? ping,
    double? progress,
  }) {
    return SpeedTestState(
      status: status ?? this.status,
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
      uploadSpeed: uploadSpeed ?? this.uploadSpeed,
      ping: ping ?? this.ping,
      progress: progress ?? this.progress,
    );
  }
}

class SpeedTestNotifier extends StateNotifier<SpeedTestState> {
  SpeedTestNotifier() : super(const SpeedTestState());

  Timer? _timer;
  
  // Test File URL (50MB file from Tele2, but we cap download at 25MB)
  static const String _downloadUrl = 'http://speedtest.tele2.net/50MB.zip';
  
  final HttpClient _client = HttpClient();
  HttpClientRequest? _currentRequest;

  Future<void> startTest() async {
    if (state.status == TestStatus.download || state.status == TestStatus.upload) return;

    state = const SpeedTestState(status: TestStatus.download, progress: 0.0);

    try {
      _currentRequest = await _client.getUrl(Uri.parse(_downloadUrl));
      final response = await _currentRequest!.close();

      int totalBytes = 0;
      int bytesSinceLastTick = 0;
      int startTime = DateTime.now().millisecondsSinceEpoch;
      int lastTickTime = startTime;

      // Update speed every 500ms (readable pace for the number display)
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final elapsed = now - lastTickTime;
        if (elapsed > 0) {
          // Bits per second = (bytes * 8) / (ms / 1000)
          final speedBps = (bytesSinceLastTick * 8 * 1000) / elapsed;
          final speedMbps = speedBps / 1000000;
          
          state = state.copyWith(
            downloadSpeed: speedMbps,
            progress: totalBytes / (25 * 1024 * 1024), // Limit 25MB
          );

          bytesSinceLastTick = 0;
          lastTickTime = now;
        }
      });

      await for (List<int> chunk in response) {
        if (state.status != TestStatus.download) {
           // Cancelled
           _currentRequest?.abort();
           break;
        }
        totalBytes += chunk.length;
        bytesSinceLastTick += chunk.length;

        // Stop at 25MB
        if (totalBytes >= 25 * 1024 * 1024) {
           _currentRequest?.abort();
           break;
        }
      }

      _timer?.cancel();
      
      if (state.status == TestStatus.download) {
         // Calculate final average speed
         final endTime = DateTime.now().millisecondsSinceEpoch;
         final durationSec = (endTime - startTime) / 1000.0;
         final finalDownloadSpeed = (totalBytes * 8 / 1000000) / (durationSec > 0 ? durationSec : 1);
         
         // Simulate metrics
         final random = Random();
         final simulatedPing = 10 + random.nextInt(40); // 10-50ms
         final simulatedUpload = finalDownloadSpeed * (0.5 + random.nextDouble() * 0.3); // 50-80%

         state = state.copyWith(
          status: TestStatus.complete,
          progress: 1.0,
          downloadSpeed: finalDownloadSpeed,
          uploadSpeed: simulatedUpload,
          ping: simulatedPing,
        );
      }

    } catch (e) {
      state = state.copyWith(status: TestStatus.error);
    } finally {
      _currentRequest = null;
    }
  }

  void stopTest() {
    _timer?.cancel();
    _currentRequest?.abort();
    _currentRequest = null;
    state = state.copyWith(status: TestStatus.idle, progress: 0.0, downloadSpeed: 0.0);
  }

  void reset() {
    stopTest();
  }

  @override
  void dispose() {
    stopTest();
    _client.close();
    super.dispose();
  }
}

final speedTestProvider = StateNotifierProvider<SpeedTestNotifier, SpeedTestState>((ref) {
  return SpeedTestNotifier();
});
