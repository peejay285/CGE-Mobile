import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import 'cge_button.dart';

/// Consistent error state widget for use across the app.
/// Clean centered layout with icon, message, and optional retry button.
class CgeErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const CgeErrorState({
    super.key,
    this.message = 'Something went wrong',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.alertCircle, size: 40, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              CgeButton(
                label: 'Retry',
                variant: CgeButtonVariant.secondary,
                icon: LucideIcons.refreshCw,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
