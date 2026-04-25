import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import 'cge_button.dart';

/// Purposeful empty state: icon, one-line explanation, single CTA.
/// Never just a blank screen.
///
/// Supports both Lucide [IconData] via [iconData] and legacy emoji
/// strings via [icon]. Prefer [iconData] for new code.
class CgeEmptyState extends StatelessWidget {
  /// Legacy emoji string icon. Ignored when [iconData] is provided.
  final String icon;

  /// Lucide icon — preferred over emoji [icon].
  final IconData? iconData;

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const CgeEmptyState({
    super.key,
    this.icon = '',
    this.iconData,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconData != null)
              Icon(iconData, size: 48, color: AppColors.textMuted)
            else if (icon.isNotEmpty)
              Text(icon, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTypography.headingSmall,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              CgeButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
