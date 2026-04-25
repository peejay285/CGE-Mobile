import 'package:flutter/material.dart';

/// Semantic color tokens — never hardcode hex values in components.
/// Use AppColors.of(context) to get theme-aware colors.
class AppColors {
  AppColors._();

  // ─── Dark Mode Palette ──────────────────────────────
  static const _darkBase = Color(0xFF09090B);
  static const _darkSurface = Color(0xFF111113);
  static const _darkSurfaceRaised = Color(0xFF1A1A1E);
  static const _darkBorder = Color(0xFF27272A);
  static const _darkTextPrimary = Color(0xFFFAFAFA);
  static const _darkTextSecondary = Color(0xFF8B8B96);
  static const _darkTextTertiary = Color(0xFF52525B);

  // ─── Light Mode Palette ──────────────────────────────
  static const _lightBase = Color(0xFFFFFFFF);
  static const _lightSurface = Color(0xFFF4F4F5);
  static const _lightSurfaceRaised = Color(0xFFFFFFFF);
  static const _lightBorder = Color(0xFFE4E4E7);
  static const _lightTextPrimary = Color(0xFF09090B);
  static const _lightTextSecondary = Color(0xFF71717A);
  static const _lightTextTertiary = Color(0xFFA1A1AA);

  // ─── Accent (single primary accent) ──────────────────
  static const accent = Color(0xFF00D4E6); // CGE cyan — CTAs, active states only
  static const accentMuted = Color(0xFF0891B2);

  // ─── Status Colors (accessible, consistent) ──────────
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);

  // ─── Brand Colors (used sparingly) ───────────────────
  static const magenta = Color(0xFFEC4899);
  static const gold = Color(0xFFEAB308);

  // ─── Semantic Getters (legacy support during migration) ───
  // These map to dark mode for backward compatibility.
  // New code should use ThemeExtension via AppColors.of(context).
  static const base = _darkBase;
  static const surface = _darkSurface;
  static const surfaceAlt = _darkSurfaceRaised;
  static const border = _darkBorder;
  static const text = _darkTextPrimary;
  static const textMuted = _darkTextSecondary;
  static const cyan = accent;
  static const green = success;
  static const red = error;

  // ─── Theme Extension ──────────────────────────────
  static AppColorScheme of(BuildContext context) {
    return Theme.of(context).extension<AppColorScheme>()!;
  }

  static const darkScheme = AppColorScheme(
    base: _darkBase,
    surface: _darkSurface,
    surfaceRaised: _darkSurfaceRaised,
    border: _darkBorder,
    textPrimary: _darkTextPrimary,
    textSecondary: _darkTextSecondary,
    textTertiary: _darkTextTertiary,
  );

  static const lightScheme = AppColorScheme(
    base: _lightBase,
    surface: _lightSurface,
    surfaceRaised: _lightSurfaceRaised,
    border: _lightBorder,
    textPrimary: _lightTextPrimary,
    textSecondary: _lightTextSecondary,
    textTertiary: _lightTextTertiary,
  );
}

/// Theme extension for semantic colors accessible via Theme.of(context)
@immutable
class AppColorScheme extends ThemeExtension<AppColorScheme> {
  final Color base;
  final Color surface;
  final Color surfaceRaised;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  const AppColorScheme({
    required this.base,
    required this.surface,
    required this.surfaceRaised,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
  });

  @override
  AppColorScheme copyWith({
    Color? base,
    Color? surface,
    Color? surfaceRaised,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
  }) {
    return AppColorScheme(
      base: base ?? this.base,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
    );
  }

  @override
  AppColorScheme lerp(AppColorScheme? other, double t) {
    if (other is! AppColorScheme) return this;
    return AppColorScheme(
      base: Color.lerp(base, other.base, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
    );
  }
}
