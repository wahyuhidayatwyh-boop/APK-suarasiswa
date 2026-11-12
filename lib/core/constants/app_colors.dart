import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Red Palette - Refined & Modern
  static const Color primary = Color(0xFFD92D20);
  static const Color darkRed = Color(0xFFB42318);
  static const Color lightRed = Color(0xFFFEF3F2);
  static const Color redBorder = Color(0xFFFECDCA);
  static const Color redActive = Color(0xFF912018);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color errorBorder = Color(0xFFFECACA);

  // Background & Modern Surfaces
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // Slate Neutral Hierarchy
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate50 = Color(0xFFF8FAFC);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textInverse = Colors.white;

  // Borders & Dividers - Ultra subtle & modern
  static const Color border = Color(0xFFF1F5F9);
  static const Color borderStrong = Color(0xFFE2E8F0);
  static const Color borderFocus = Color(0xFFCBD5E1);

  // Status & Utility Colors (Soft modern pastel containers + deep text)
  static const Color success = Color(0xFF10B981);
  static const Color successDark = Color(0xFF059669);
  static const Color successLight = Color(0xFFECFDF5);
  static const Color successBorder = Color(0xFFA7F3D0);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFDE68A);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoDark = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFEFF6FF);
  static const Color infoBorder = Color(0xFFBFDBFE);

  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleDark = Color(0xFF7C3AED);
  static const Color purpleLight = Color(0xFFF5F3FF);
  static const Color purpleBorder = Color(0xFFDDD6FE);

  // Dark Premium Surfaces (Charcoal / Near Black like reference image)
  static const Color darkBg = Color(0xFF0F131A);
  static const Color darkCard = Color(0xFF181C26);
  static const Color darkCardElevated = Color(0xFF222736);
  static const Color darkBorder = Color(0xFF2E3547);
  static const Color darkTextMuted = Color(0xFF94A3B8);

  // Modern Gradients (Brand Crimson & Dark Charcoal)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE5392D), Color(0xFFB42318)],
  );

  static const LinearGradient crimsonCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE52E20), Color(0xFF8F1912)],
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E222D), Color(0xFF10131A)],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFD92D20), Color(0xFFB42318)],
  );

  // Glassmorphism Tokens
  static Color get glassSurface => Colors.white.withOpacity(0.85);
  static Color get glassSurfaceMuted => Colors.white.withOpacity(0.65);
  static Color get glassBorder => Colors.white.withOpacity(0.6);
  static Color get glassDarkBorder => Colors.white.withOpacity(0.12);

  // 3D & Dimensional Elevation Levels
  static List<BoxShadow> get elevation1 => [
        BoxShadow(
          color: const Color(0xFF0F172A).withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get elevation2 => [
        BoxShadow(
          color: const Color(0xFF0F172A).withOpacity(0.06),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: const Color(0xFF0F172A).withOpacity(0.02),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get elevation3 => [
        BoxShadow(
          color: const Color(0xFF0F172A).withOpacity(0.09),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: const Color(0xFF0F172A).withOpacity(0.03),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ];

  static List<BoxShadow> get darkCardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get redCardShadow => [
        BoxShadow(
          color: const Color(0xFFD92D20).withOpacity(0.32),
          blurRadius: 22,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get floatingShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withOpacity(0.10),
          blurRadius: 26,
          offset: const Offset(0, 8),
        ),
      ];

  // Backward compatibility
  static List<BoxShadow> get cardShadow => elevation1;
  static List<BoxShadow> get elevatedCardShadow => elevation2;

  // Shimmer
  static const Color shimmerBase = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF8FAFC);
}
