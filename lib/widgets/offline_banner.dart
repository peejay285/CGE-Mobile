import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/network/connectivity_provider.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityProvider);

    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      offset: isOnline ? const Offset(0, -1) : Offset.zero,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isOnline ? 0.0 : 1.0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.red.withValues(alpha: 0.15),
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.wifiOff, size: 16, color: AppColors.red),
                const SizedBox(width: 8),
                Text(
                  "You're offline. Changes will sync when connected.",
                  style: AppTypography.labelSmall.copyWith(color: AppColors.red),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
