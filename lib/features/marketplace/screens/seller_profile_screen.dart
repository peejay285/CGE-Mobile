import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/profile.dart';
import '../../../data/models/review.dart';
import '../../../data/remote/supabase_config.dart';
import '../../../providers/review_provider.dart';
import '../../../widgets/cge_card.dart';
import '../../../widgets/cge_button.dart';
import '../../../widgets/cge_badge.dart';
import '../../../widgets/cge_skeleton.dart';
import '../../../widgets/cge_empty_state.dart';
import '../../../widgets/cge_avatar.dart';

class SellerProfileScreen extends ConsumerWidget {
  final String sellerId;
  const SellerProfileScreen({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(sellerProfileProvider(sellerId));
    final reviewsAsync = ref.watch(sellerReviewsProvider(sellerId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Profile'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: profileAsync.when(
        loading: () => const _ProfileSkeleton(),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.wifiOff,
                color: AppColors.textMuted,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text('Failed to load profile', style: AppTypography.body),
              const SizedBox(height: 12),
              CgeButton(
                label: 'Retry',
                onPressed: () =>
                    ref.invalidate(sellerProfileProvider(sellerId)),
              ),
            ],
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return const CgeEmptyState(
              icon: '👤',
              title: 'Seller not found',
              subtitle: 'This profile may have been removed',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Seller header
              _SellerHeader(profile: profile),
              const SizedBox(height: 24),

              // Trust stats
              _TrustStats(profile: profile),
              const SizedBox(height: 24),

              // Reviews section
              Row(
                children: [
                  Text('Reviews', style: AppTypography.heading),
                  const SizedBox(width: 8),
                  if (profile.ratingCount != null && profile.ratingCount! > 0)
                    CgeBadge(
                      label: '${profile.ratingCount}',
                      color: BadgeColor.cyan,
                    ),
                ],
              ),
              const SizedBox(height: 12),

              reviewsAsync.when(
                loading: () => const _ReviewsSkeleton(),
                error: (e, _) => CgeCard(
                  child: Center(
                    child: Text(
                      'Failed to load reviews',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
                data: (reviews) {
                  if (reviews.isEmpty) {
                    return const CgeEmptyState(
                      icon: '⭐',
                      title: 'No reviews yet',
                      subtitle: 'This seller hasn\'t received any reviews',
                    );
                  }

                  return Column(
                    children: reviews
                        .map((r) => _ReviewCard(review: r))
                        .toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildReviewFab(context, ref),
    );
  }

  Widget? _buildReviewFab(BuildContext context, WidgetRef ref) {
    final currentUser = SupabaseConfig.currentUser;
    if (currentUser == null || currentUser.id == sellerId) return null;

    return FloatingActionButton.extended(
      onPressed: () => _showReviewDialog(context, ref),
      backgroundColor: AppColors.cyan,
      icon: const Icon(LucideIcons.star, color: AppColors.base),
      label: Text(
        'Write Review',
        style: AppTypography.label.copyWith(color: AppColors.base),
      ),
    );
  }

  void _showReviewDialog(BuildContext context, WidgetRef ref) {
    int selectedRating = 5;
    final commentController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Rate this seller', style: AppTypography.subheading),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Star rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final starNum = i + 1;
                  return IconButton(
                    onPressed: () =>
                        setDialogState(() => selectedRating = starNum),
                    icon: Icon(
                      starNum <= selectedRating
                          ? LucideIcons.star
                          : LucideIcons.star,
                      color: starNum <= selectedRating
                          ? AppColors.gold
                          : AppColors.border,
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              // Comment
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share your experience (optional)',
                  hintStyle: AppTypography.body.copyWith(
                    color: AppColors.textMuted,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.cyan),
                  ),
                ),
                style: AppTypography.body,
              ),
            ],
          ),
          actions: [
            CgeButton(
              label: 'Cancel',
              variant: CgeButtonVariant.ghost,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            CgeButton(
              label: 'Submit',
              isLoading: isSubmitting,
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Reviews are submitted from the completed listing or swap.',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Seller Header ──────────────────────────────

class _SellerHeader extends StatelessWidget {
  final Profile profile;
  const _SellerHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    return CgeCard(
      child: Column(
        children: [
          Row(
            children: [
              CgeAvatar(
                imageUrl: profile.avatarUrl,
                name: profile.fullName,
                size: 64,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          profile.fullName,
                          style: AppTypography.subheading,
                          overflow: TextOverflow.ellipsis,
                        ),
                        _TrustBadge(level: profile.trustLevel ?? 'new'),
                        if (profile.isIdVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.cyan.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.shieldCheck,
                                  size: 9,
                                  color: AppColors.cyan,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Verified',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.cyan,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (profile.premiumTier == 'premium')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.crown,
                                  size: 9,
                                  color: AppColors.gold,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Premium',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.gold,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (profile.gamertag != null)
                      Text(
                        '@${profile.gamertag}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.cyan,
                        ),
                      ),
                    const SizedBox(height: 4),
                    // Star rating
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          final starNum = i + 1;
                          final rating = profile.avgRating ?? 0;
                          return Icon(
                            LucideIcons.star,
                            size: 16,
                            color: starNum <= rating
                                ? AppColors.gold
                                : AppColors.border,
                          );
                        }),
                        const SizedBox(width: 6),
                        Text(
                          '${profile.avgRating?.toStringAsFixed(1) ?? '0.0'} (${profile.ratingCount ?? 0})',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (profile.bio != null) ...[
            const SizedBox(height: 12),
            Text(
              profile.bio!,
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Trust Badge ──────────────────────────────

class _TrustBadge extends StatelessWidget {
  final String level;
  const _TrustBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (level) {
      'power' => (BadgeColor.gold, '⚡ Power Seller'),
      'trusted' => (BadgeColor.green, '✓ Trusted'),
      'verified' => (BadgeColor.cyan, '✓ Verified'),
      _ => (BadgeColor.red, 'New'),
    };

    return CgeBadge(label: label, color: color);
  }
}

// ─── Trust Stats ──────────────────────────────

class _TrustStats extends StatelessWidget {
  final Profile profile;
  const _TrustStats({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          icon: LucideIcons.tag,
          label: 'Listings',
          value: '${profile.totalListings ?? 0}',
          color: AppColors.cyan,
        ),
        const SizedBox(width: 8),
        _StatCard(
          icon: LucideIcons.shoppingBag,
          label: 'Sales',
          value: '${profile.totalSales ?? 0}',
          color: AppColors.magenta,
        ),
        const SizedBox(width: 8),
        _StatCard(
          icon: LucideIcons.repeat,
          label: 'Swaps',
          value: '${profile.totalSwaps ?? 0}',
          color: AppColors.gold,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CgeCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value, style: AppTypography.monoLarge),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Review Card ──────────────────────────────

class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CgeCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CgeAvatar(
                  imageUrl: review.reviewer?.avatarUrl,
                  name: review.reviewer?.fullName ?? 'User',
                  size: 36,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.reviewer?.fullName ?? 'Anonymous',
                        style: AppTypography.label,
                      ),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (i) => Icon(
                              LucideIcons.star,
                              size: 12,
                              color: i < review.rating
                                  ? AppColors.gold
                                  : AppColors.border,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _timeAgo(review.createdAt),
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (review.review != null && review.review!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review.review!, style: AppTypography.body),
            ],
          ],
        ),
      ),
    );
  }

  String _timeAgo(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo ago';
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'now';
    } catch (_) {
      return '';
    }
  }
}

// ─── Skeletons ──────────────────────────────

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 120, child: CgeSkeleton.card()),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: SizedBox(height: 80, child: CgeSkeleton.card()),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: SizedBox(height: 80, child: CgeSkeleton.card()),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: SizedBox(height: 80, child: CgeSkeleton.card()),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...List.generate(
            3,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: SizedBox(height: 80, child: CgeSkeleton.card()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewsSkeleton extends StatelessWidget {
  const _ReviewsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: SizedBox(height: 80, child: CgeSkeleton.card()),
        ),
      ),
    );
  }
}
