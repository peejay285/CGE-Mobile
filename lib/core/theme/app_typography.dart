import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Linear-style typography system
/// Font scale: Display 28 / Title 20 / Body 15 / Caption 12
/// Weights: Regular (400) and Medium (500) only — never Bold in UI chrome.
/// Single typeface family: Sora. Mono: JetBrains Mono for prices/codes.
class AppTypography {
  AppTypography._();

  // ─── Display (28px, Medium, 1.4 line height) ─────────
  static const display = TextStyle(
    fontFamily: 'Sora',
    fontSize: 28,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
    height: 1.4,
    letterSpacing: -0.3,
  );

  // ─── Title (20px, Medium, 1.4 line height) ───────────
  static const heading = TextStyle(
    fontFamily: 'Sora',
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
    height: 1.4,
    letterSpacing: -0.2,
  );

  static const headingSmall = TextStyle(
    fontFamily: 'Sora',
    fontSize: 17,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
    height: 1.4,
  );

  // ─── Subheading (16px, Medium) ───────────────────────
  static const subheading = TextStyle(
    fontFamily: 'Sora',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
    height: 1.4,
  );

  static const subheadingLarge = TextStyle(
    fontFamily: 'Sora',
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
    height: 1.4,
  );

  // ─── Body (15px, Regular, 1.6 line height) ───────────
  static const body = TextStyle(
    fontFamily: 'Sora',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
    height: 1.6,
  );

  static const bodyLarge = TextStyle(
    fontFamily: 'Sora',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
    height: 1.6,
  );

  static const bodySmall = TextStyle(
    fontFamily: 'Sora',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.6,
  );

  // ─── Caption (12px, Regular) ─────────────────────────
  static const label = TextStyle(
    fontFamily: 'Sora',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
    height: 1.4,
  );

  static const labelSmall = TextStyle(
    fontFamily: 'Sora',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.4,
  );

  // ─── Mono (prices, codes, stats) ─────────────────────
  static const mono = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
    height: 1.4,
  );

  static const monoLarge = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.accent,
    height: 1.4,
  );

  // ─── Legacy aliases ──────────────────────────────────
  static const displaySmall = heading;
}
