/// Speed formatting utilities.
/// Converts bytes/sec to human-readable strings with auto-scaling units.
class SpeedFormatter {
  SpeedFormatter._();

  /// Format bytes/sec to compact speed string: "1.2 MB/s"
  static String formatSpeed(int bytesPerSec) {
    if (bytesPerSec < 1024 * 1024) {
      final kb = bytesPerSec / 1024.0;
      return '${kb.toStringAsFixed(2)} KB/s';
    } else if (bytesPerSec < 1024 * 1024 * 1024) {
      final mb = bytesPerSec / (1024.0 * 1024);
      return '${mb.toStringAsFixed(2)} MB/s';
    } else {
      final gb = bytesPerSec / (1024.0 * 1024 * 1024);
      return '${gb.toStringAsFixed(2)} GB/s';
    }
  }

  /// Format bytes/sec to just the numeric value: "1.2"
  static String formatSpeedValue(int bytesPerSec) {
    if (bytesPerSec < 1024 * 1024) {
      return (bytesPerSec / 1024.0).toStringAsFixed(2);
    } else if (bytesPerSec < 1024 * 1024 * 1024) {
      return (bytesPerSec / (1024.0 * 1024)).toStringAsFixed(2);
    } else {
      return (bytesPerSec / (1024.0 * 1024 * 1024)).toStringAsFixed(2);
    }
  }

  /// Get the unit string: "B/s", "KB/s", "MB/s", "GB/s"
  static String formatSpeedUnit(int bytesPerSec) {
    if (bytesPerSec < 1024 * 1024) return 'KB/s';
    if (bytesPerSec < 1024 * 1024 * 1024) return 'MB/s';
    return 'GB/s';
  }

  /// Format total bytes to human-readable: "1.5 GB", "234 MB"
  static String formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024.0).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024.0 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024.0 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// Format bytes with split: returns (value, unit) e.g. ("1.5", "GB")
  static (String, String) formatBytesSplit(int bytes) {
    if (bytes < 1024) return (bytes.toString(), 'B');
    if (bytes < 1024 * 1024) {
      return ((bytes / 1024.0).toStringAsFixed(1), 'KB');
    }
    if (bytes < 1024 * 1024 * 1024) {
      return ((bytes / (1024.0 * 1024)).toStringAsFixed(1), 'MB');
    }
    return ((bytes / (1024.0 * 1024 * 1024)).toStringAsFixed(2), 'GB');
  }
}
