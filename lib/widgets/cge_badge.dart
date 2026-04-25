import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum BadgeColor { cyan, magenta, gold, green, red }

/// Compact status badge. Consistent status colors across app.
class CgeBadge extends StatelessWidget {
  final String label;
  final BadgeColor color;
  final double fontSize;

  const CgeBadge({
    super.key,
    required this.label,
    this.color = BadgeColor.cyan,
    this.fontSize = 11,
  });

  Color get _color {
    switch (color) {
      case BadgeColor.cyan:
        return AppColors.accent;
      case BadgeColor.magenta:
        return AppColors.magenta;
      case BadgeColor.gold:
        return AppColors.gold;
      case BadgeColor.green:
        return AppColors.success;
      case BadgeColor.red:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Sora',
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          color: _color,
          height: 1.4,
        ),
      ),
    );
  }
}
