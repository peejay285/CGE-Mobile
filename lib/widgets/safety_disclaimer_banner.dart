import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

/// Tier 1 of the marketplace trust ladder. Displays a brand-safety disclaimer
/// that makes the platform's role explicit and provides a checklist for safe
/// peer-to-peer trades.
///
/// Two variants:
///   - `compact`: a single-line shield-icon strip for inline placement (e.g.
///     near the action bar on a listing detail screen).
///   - `expanded` (default): a tappable card that expands to show the full tip
///     list. Use on screens where the user is about to commit to a swap.
class SafetyDisclaimerBanner extends StatefulWidget {
  final SafetyDisclaimerVariant variant;
  final EdgeInsets? margin;

  const SafetyDisclaimerBanner({
    super.key,
    this.variant = SafetyDisclaimerVariant.expanded,
    this.margin,
  });

  @override
  State<SafetyDisclaimerBanner> createState() => _SafetyDisclaimerBannerState();
}

class _SafetyDisclaimerBannerState extends State<SafetyDisclaimerBanner> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    if (widget.variant == SafetyDisclaimerVariant.compact) {
      return Container(
        margin: widget.margin,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(LucideIcons.shield, size: 14, color: AppColors.cyan),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: AppTypography.body.copyWith(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    height: 1.45,
                  ),
                  children: [
                    TextSpan(
                      text: 'Safety: ',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    TextSpan(text: AppConstants.safetyShort),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.shield,
                      size: 16, color: AppColors.cyan),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppConstants.safetyTitle,
                          style: AppTypography.body.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppConstants.safetyIntro,
                          style: AppTypography.body.copyWith(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      LucideIcons.chevronDown,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border:
                    Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < AppConstants.safetyTips.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    RichText(
                      text: TextSpan(
                        style: AppTypography.body.copyWith(
                          fontSize: 11,
                          height: 1.5,
                        ),
                        children: [
                          TextSpan(
                            text: '${AppConstants.safetyTips[i].heading}. ',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                          TextSpan(
                            text: AppConstants.safetyTips[i].body,
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

enum SafetyDisclaimerVariant { compact, expanded }
