import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Linear-inspired theme system with light and dark modes.
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        scheme: AppColors.darkScheme,
        systemOverlay: SystemUiOverlayStyle.light,
      );

  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        scheme: AppColors.lightScheme,
        systemOverlay: SystemUiOverlayStyle.dark,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required AppColorScheme scheme,
    required SystemUiOverlayStyle systemOverlay,
  }) {
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: scheme.base,
      extensions: [scheme],

      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.accent,
        onPrimary: const Color(0xFF09090B),
        secondary: AppColors.accentMuted,
        onSecondary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        surface: scheme.surface,
        onSurface: scheme.textPrimary,
        outline: scheme.border,
      ),

      // ─── App Bar ──────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.base,
        foregroundColor: scheme.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false, // Linear: left-aligned titles
        titleTextStyle: AppTypography.headingSmall.copyWith(
          color: scheme.textPrimary,
        ),
        systemOverlayStyle: systemOverlay.copyWith(
          statusBarColor: Colors.transparent,
        ),
        surfaceTintColor: Colors.transparent,
      ),

      // ─── Bottom Navigation ────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: scheme.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Sora',
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Sora',
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),

      // ─── Cards ────────────────────────────────
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: scheme.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ─── Input Fields ─────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        hintStyle: AppTypography.body.copyWith(color: scheme.textTertiary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),

      // ─── Elevated Buttons ─────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: const Color(0xFF09090B),
          textStyle: AppTypography.label,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
          minimumSize: const Size(44, 44), // 44pt minimum touch target
        ),
      ),

      // ─── Outlined Buttons ─────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.textPrimary,
          textStyle: AppTypography.label,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: BorderSide(color: scheme.border),
          minimumSize: const Size(44, 44),
        ),
      ),

      // ─── Text Buttons ─────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: AppTypography.label,
          minimumSize: const Size(44, 44),
        ),
      ),

      // ─── Bottom Sheet ─────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        dragHandleColor: scheme.border,
        dragHandleSize: const Size(36, 4),
      ),

      // ─── Dialog ───────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.border),
        ),
        titleTextStyle: AppTypography.heading.copyWith(color: scheme.textPrimary),
        contentTextStyle: AppTypography.body.copyWith(color: scheme.textSecondary),
      ),

      // ─── Divider ──────────────────────────────
      dividerTheme: DividerThemeData(
        color: scheme.border,
        thickness: 1,
        space: 1,
      ),

      // ─── Snackbar ─────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.surfaceRaised,
        contentTextStyle: AppTypography.body.copyWith(color: scheme.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: scheme.border),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // ─── Tab Bar ──────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.accent,
        unselectedLabelColor: scheme.textTertiary,
        indicatorColor: AppColors.accent,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(
          fontFamily: 'Sora',
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Sora',
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
      ),

      // ─── Chip ─────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        selectedColor: AppColors.accent.withValues(alpha: 0.15),
        labelStyle: AppTypography.labelSmall.copyWith(color: scheme.textPrimary),
        side: BorderSide(color: scheme.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // ─── Tooltip ──────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.surfaceRaised,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: scheme.border),
        ),
        textStyle: AppTypography.labelSmall.copyWith(color: scheme.textPrimary),
      ),
    );
  }
}
