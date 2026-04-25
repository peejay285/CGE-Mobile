import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../data/models/marketplace_listing.dart';

/// Mirror of the React SwapStateTracker — shows the 4-step lifecycle
/// (proposer ship → owner ship → proposer receive → owner receive) for
/// active swap proposals, or terminal-state messaging for cancelled /
/// expired / disputed / completed.
class SwapStateTracker extends StatelessWidget {
  final SwapProposal proposal;
  final EdgeInsets? margin;

  const SwapStateTracker({super.key, required this.proposal, this.margin});

  @override
  Widget build(BuildContext context) {
    final s = proposal.status;

    if (s == 'cancelled' || s == 'expired') {
      return _terminalCard(
        icon: LucideIcons.x,
        color: AppColors.red,
        title: s == 'expired' ? 'Expired' : 'Cancelled',
        body: proposal.cancellationReason,
      );
    }

    if (s == 'disputed') {
      return _terminalCard(
        icon: LucideIcons.alertCircle,
        color: AppColors.gold,
        title: 'Disputed',
        body: proposal.disputeReason,
      );
    }

    if (s == 'completed') {
      return _terminalCard(
        icon: LucideIcons.check,
        color: AppColors.green,
        title: 'Swap completed — both parties confirmed receipt',
      );
    }

    if (s != 'accepted' && s != 'in_transit') {
      return const SizedBox.shrink();
    }

    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _step(
                done: proposal.proposerShippedAt != null,
                icon: LucideIcons.truck,
                label: 'Proposer\nshipped',
              ),
              _step(
                done: proposal.ownerShippedAt != null,
                icon: LucideIcons.truck,
                label: 'Owner\nshipped',
              ),
              _step(
                done: proposal.proposerReceivedAt != null,
                icon: LucideIcons.package,
                label: 'Proposer\nreceived',
              ),
              _step(
                done: proposal.ownerReceivedAt != null,
                icon: LucideIcons.package,
                label: 'Owner\nreceived',
              ),
            ],
          ),
          if (proposal.expiresAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Expires ${DateTime.parse(proposal.expiresAt!).toLocal().toString().split(' ').first}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _step({
    required bool done,
    required IconData icon,
    required String label,
  }) {
    final color = done ? AppColors.cyan : AppColors.textMuted;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? AppColors.cyan.withValues(alpha: 0.15) : null,
              border: Border.all(
                color: done ? AppColors.cyan.withValues(alpha: 0.4) : AppColors.border,
              ),
            ),
            child: Icon(done ? LucideIcons.check : icon, size: 12, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(fontSize: 9, color: color),
          ),
        ],
      ),
    );
  }

  Widget _terminalCard({
    required IconData icon,
    required Color color,
    required String title,
    String? body,
  }) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                if (body != null && body.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 11,
                      color: AppColors.textMuted,
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
