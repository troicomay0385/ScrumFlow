import 'package:flutter/material.dart';

/// Bảng màu tập trung cho toàn bộ ứng dụng ScrumFlow.
///
/// Sử dụng palette tối hiện đại kết hợp gradient tím-xanh,
/// tạo cảm giác chuyên nghiệp và premium.
class AppColors {
  AppColors._();

  // ── Brand colors ───────────────────────────────────────────
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF4A42D4);
  static const Color primaryLight = Color(0xFF9D97FF);

  static const Color secondary = Color(0xFF00BFA6);
  static const Color secondaryDark = Color(0xFF008C7A);
  static const Color secondaryLight = Color(0xFF5DF2D6);

  // ── Gradient ───────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Surface & Background ───────────────────────────────────
  static const Color scaffoldBackground = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E2C);
  static const Color surfaceLight = Color(0xFF2A2A3D);
  static const Color cardBackground = Color(0xFF1E1E2C);

  // ── Text ───────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFEEEEEE);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textHint = Color(0xFF757575);

  // ── Status ─────────────────────────────────────────────────
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);

  // ── Input fields ───────────────────────────────────────────
  static const Color inputFill = Color(0xFF2A2A3D);
  static const Color inputBorder = Color(0xFF3D3D56);
  static const Color inputFocusBorder = Color(0xFF6C63FF);

  // ── Divider & overlay ──────────────────────────────────────
  static const Color divider = Color(0xFF2A2A3D);
  static const Color overlay = Color(0x80000000);

  // ── Google button ──────────────────────────────────────────
  static const Color googleButtonBackground = Color(0xFFFFFFFF);
  static const Color googleButtonText = Color(0xFF757575);
}
