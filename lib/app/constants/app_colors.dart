import 'package:flutter/material.dart';

/// Bảng màu Design System Kinetic Sprint từ dự án Google Stitch (ScrumFlow Agile Management UI).
///
/// Phối hợp giữa sắc xanh tím công nghệ (Electric Indigo), xanh lam (Cyan/Teal)
/// trên nền Canvas sáng siêu sạch (#FAF8FF), kết hợp độ tương phản cao và bóng đổ ambient dịu nhẹ.
class AppColors {
  AppColors._();

  // ── Stitch Kinetic Sprint Tokens ────────────────────────────
  static const Color primary = Color(0xFF3525CD);
  static const Color primaryContainer = Color(0xFF4F46E5);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFDAD7FF);

  static const Color secondary = Color(0xFF006591);
  static const Color secondaryContainer = Color(0xFF39B8FD);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF004666);

  static const Color tertiary = Color(0xFF3130C0);
  static const Color tertiaryContainer = Color(0xFF4B4DD8);

  // ── Surface & Canvas ────────────────────────────────────────
  static const Color background = Color(0xFFFAF8FF);
  static const Color canvas = Color(0xFFFAF8FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFDAE2FD);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F3FF);
  static const Color surfaceContainer = Color(0xFFEAEDFF);
  static const Color surfaceContainerHigh = Color(0xFFE2E7FF);
  static const Color surfaceContainerHighest = Color(0xFFDAE2FD);

  // ── Text & Typography ───────────────────────────────────────
  static const Color onSurface = Color(0xFF131B2E);
  static const Color onSurfaceVariant = Color(0xFF464555);
  static const Color outline = Color(0xFF777587);
  static const Color outlineVariant = Color(0xFFC7C4D8);

  // ── Status ──────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF0284C7);

  // ── Role Badges ─────────────────────────────────────────────
  static const Color rolePO = Color(0xFF7C3AED); // Tím Hoàng Gia
  static const Color rolePOBg = Color(0xFFF3E8FF);
  static const Color roleSM = Color(0xFF2563EB); // Xanh Lam Đậm
  static const Color roleSMBg = Color(0xFFDBEAFE);
  static const Color roleDev = Color(0xFF059669); // Xanh Lục Bảo
  static const Color roleDevBg = Color(0xFFD1FAE5);
  static const Color roleQA = Color(0xFFE11D48); // Hồng San Hô
  static const Color roleQABg = Color(0xFFFFE4E6);

  // ── Gradients ───────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3525CD), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardAccentGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF39B8FD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Tương thích ngược (Backward Compatibility) ──────────────
  static const Color primaryDark = Color(0xFF3525CD);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color secondaryDark = Color(0xFF004666);
  static const Color secondaryLight = Color(0xFFBAE6FD);
  static const Color scaffoldBackground = Color(0xFFFAF8FF);
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF131B2E);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color inputFill = Color(0xFFF8FAFC);
  static const Color inputBorder = Color(0xFFE2E8F0);
  static const Color inputFocusBorder = Color(0xFF4F46E5);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color overlay = Color(0x660F172A);
  static const Color googleButtonBackground = Color(0xFFFFFFFF);
  static const Color googleButtonText = Color(0xFF334155);
}
