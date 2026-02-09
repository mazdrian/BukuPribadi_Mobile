import 'package:flutter/material.dart';

/// Color Theme Configuration
/// Based on Color Theory: Split-Complementary Color Scheme
///
/// Primary (Deep Blue): Trust, professionalism, stability
/// Secondary (Coral): Energy, enthusiasm, action
/// Accent (Teal): Growth, success, progress
///
/// All colors selected with WCAG AA accessibility standards in mind

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF2C3E50);
  static const Color primaryLight = Color(0xFF34495E);
  static const Color primaryDark = Color(0xFF1A252F);

  // Secondary Colors
  static const Color secondary = Color(0xFFE74C3C);
  static const Color secondaryLight = Color(0xFFEC7063);
  static const Color secondaryDark = Color(0xFFC0392B);

  // Accent Colors
  static const Color accent = Color(0xFF16A085);
  static const Color accentLight = Color(0xFF1ABC9C);
  static const Color accentDark = Color(0xFF117A65);

  // Status Colors
  static const Color success = Color(0xFF27AE60);
  static const Color successLight = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF39C12);
  static const Color warningLight = Color(0xFFF5B041);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  // Neutral Colors
  static const Color background = Color(0xFFECF0F1);
  static const Color backgroundDark = Color(0xFFBDC3C7);
  static const Color surface = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textLight = Color(0xFF95A5A6);
  static const Color white = Color(0xFFFFFFFF);

  // Border & Shadow
  static const Color border = Color(0xFFDFE6E9);
  static const Color borderDark = Color(0xFFB2BEC3);
  static const Color shadow = Color(0xFF000000);
}

/// Status color mapping
class StatusColors {
  static const Map<String, StatusColorConfig> configs = {
    'pending': StatusColorConfig(
      bg: Color(0xFFFFF3E0),
      border: Color(0xFFF39C12),
      text: Color(0xFFE67E22),
    ),
    'active': StatusColorConfig(
      bg: Color(0xFFE8F8F5),
      border: Color(0xFF16A085),
      text: Color(0xFF117A65),
    ),
    'completed': StatusColorConfig(
      bg: Color(0xFFE8F5E9),
      border: Color(0xFF27AE60),
      text: Color(0xFF1E8449),
    ),
    'cancelled': StatusColorConfig(
      bg: Color(0xFFFFEBEE),
      border: Color(0xFFE74C3C),
      text: Color(0xFFC0392B),
    ),
  };

  static StatusColorConfig getConfig(String status) {
    return configs[status] ?? configs['pending']!;
  }
}

class StatusColorConfig {
  final Color bg;
  final Color border;
  final Color text;

  const StatusColorConfig({
    required this.bg,
    required this.border,
    required this.text,
  });
}

/// Spacing scale (8pt grid system)
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Border radius scale
class AppBorderRadius {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double round = 999;
}

/// Font sizes
class AppFontSize {
  static const double xs = 12;
  static const double sm = 14;
  static const double md = 16;
  static const double lg = 18;
  static const double xl = 24;
  static const double xxl = 32;
  static const double display = 48;
}

/// App Theme
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        background: AppColors.background,
        error: AppColors.error,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: AppFontSize.display,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: AppFontSize.xxl,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: AppFontSize.lg,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: AppFontSize.md,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: AppFontSize.sm,
          color: AppColors.textSecondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }
}
