import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Colors.white;
  static const Color cardBorder = Color(0xFFE5E7EB);

  // Primaries & Accents
  static const Color primary = Color(
    0xFF1E293B,
  ); // Muted graphite / slate primary
  static const Color primaryLight = Color(0xFF334155);
  static const Color accent = Color(0xFF2563EB); // Royal Blue accent

  // Texts
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Status & Semantic Colors (Matches reference app)
  static const Color success = Color(
    0xFF16A34A,
  ); // Green for zero balance / active
  static const Color successBackground = Color(0xFFDCFCE7);

  static const Color warning = Color(0xFFD97706);
  static const Color warningBackground = Color(0xFFFEF3C7);

  static const Color error = Color(0xFFDC2626); // Red for outstanding balance
  static const Color errorBackground = Color(0xFFFEE2E2);

  static const Color activeChip = Color(0xFF10B981);
  static const Color inactiveChip = Color(0xFF6B7280);

  // Divider
  static const Color divider = Color(0xFFF1F5F9);
}
