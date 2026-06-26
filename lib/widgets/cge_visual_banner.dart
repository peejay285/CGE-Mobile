import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

String cgeGameArtwork(String game) {
  final value = game.toLowerCase();
  if (value.contains('tekken') || value.contains('fighter')) {
    return 'assets/images/tekken-8.jpg';
  }
  if (value.contains('fc') ||
      value.contains('fifa') ||
      value.contains('football')) {
    return 'assets/images/fc-25.jpg';
  }
  return 'assets/images/lounge-hero.jpg';
}

class CgeVisualBanner extends StatelessWidget {
  final String imageAsset;
  final String eyebrow;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData actionIcon;
  final double height;

  const CgeVisualBanner({
    super.key,
    required this.imageAsset,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.actionIcon = LucideIcons.arrowUpRight,
    this.height = 210,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(
          image: AssetImage(imageAsset),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.electricBlue.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x22030A18), Color(0xEE07111F)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: Text(
                  eyebrow.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: AppTypography.heading.copyWith(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                height: 1.18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.78),
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: const Color(0xFF061019),
                  minimumSize: const Size(44, 42),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                icon: Icon(actionIcon, size: 16),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CgeTintedIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const CgeTintedIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, size: size * 0.46, color: color),
    );
  }
}
