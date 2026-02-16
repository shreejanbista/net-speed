# NetSpeed - Android Speed Monitor

NetSpeed is a lightweight, accurate internet speed monitor and data usage tracker for Android, built with Flutter.

## Features
- **Real-Time Monitoring**: Shows download/upload speeds in the status bar (via foreground service).
- **Data Usage**: Tracks daily, weekly, and monthly data consumption (WiFi & Mobile).
- **Analytics**: Detailed charts for usage trends.
- **Battery Efficient**: Uses adaptive polling (1s active / 4s idle) and zero wake locks.

## Getting Started

### Prerequisites
- Flutter SDK installed
- Android device or emulator (Android 10+ recommended)

### Installation

1.  **Clone/Open the project**:
    ```bash
    cd /home/shreez/Documents/Projects/NetSpeed
    ```

2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Run on device**:
    Connect your Android device via USB (ensure USB Debugging is ON) or start an emulator.
    ```bash
    flutter run
    ```
    
    *Note: The first build might take a few minutes.*

4.  **Install APK directly**:
    If you don't want to use `flutter run`, you can install the pre-built APK:
    ```bash
    adb install build/app/outputs/flutter-apk/app-debug.apk
    ```

## Permissions

On first launch, you must grant:
1.  **Notification Permission**: To show the speed indicator in the status bar.
2.  **Usage Access**: To track data consumption (Settings > Usage Access > NetSpeed > Allow).

## Architecture

- **State Management**: Riverpod
- **Navigation**: GoRouter
- **Native**: Kotlin (MethodChannel/EventChannel) for TrafficStats & NetworkStatsManager.
