import 'package:flutter/material.dart';

/// NetSpeed color palette — soft neo-brutalism with pastel accents on charcoal.
class AppColors {
  AppColors._();

  // ── Backgrounds ──
  static const background = Color(0xFF1A1A1A);
  static const surface = Color(0xFF242424);
  static const surfaceLight = Color(0xFF2E2E2E);
  static const card = Color(0xFF2A2A2A);

  // ── Pastel Accents ──
  static const salmon = Color(0xFFFA8072);       // Primary — download, CTAs
  static const periwinkle = Color(0xFFCCCCFF);    // Secondary — upload
  static const softYellow = Color(0xFFFDFD96);    // Highlights, badges
  static const cyan = Color(0xFF4DD0E1);          // Speed Test

  // ── Semantic ──
  static const download = salmon;
  static const upload = periwinkle;
  static const accent = salmon;
  static const highlight = softYellow;
  static const success = Color(0xFF81C784);
  static const error = Color(0xFFE57373);
  static const warning = softYellow;

  // ── Text ──
  static const textPrimary = Color(0xFFF0F0F0);
  static const textSecondary = Color(0xFFAAAAAA);
  static const textMuted = Color(0xFF888888);

  // ── Borders & Shadows (neo-brutalism) ──
  static const border = Color(0xFF444444);
  static const borderAccent = salmon;
  static const shadow = Color(0xFF000000);
}
