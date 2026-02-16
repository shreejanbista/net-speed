import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/theme/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Fix screen flicker/color shift by enforcing system UI style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Transparent status bar
      statusBarIconBrightness: Brightness.light, // White icons
      systemNavigationBarColor: AppColors.background, // Match app bg
      systemNavigationBarIconBrightness: Brightness.light, // White nav icons
    ),
  );

  runApp(
    const ProviderScope(
      child: NetSpeedApp(),
    ),
  );
}
