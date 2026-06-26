import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/pricing.dart';
import '../../../data/models/marketplace_listing.dart';
import '../../../providers/marketplace_provider.dart';
import '../../../widgets/cge_card.dart';
import '../../../widgets/cge_badge.dart';
import '../../../widgets/cge_skeleton.dart';
import '../../../widgets/cge_empty_state.dart';
import '../../../widgets/cge_button.dart';

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(myListingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus, size: 20),
            onPressed: () => context.push('/marketplace/create'),
          ),
        ],
      ),
      body: listingsAsync.when(
        loading: () => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: List.generate(
              3,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: CgeSkeleton(height: 120, borderRadius: 16),
              ),
            ),
          ),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertTriangle,
                  size: 48, color: AppColors.red),
              const SizedBox(height: 16),
              Text('Failed to load listings',
                  style: AppTypography.headingSmall),
              const SizedBox(height: 8),
              Text('$error',
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              CgeButton(
                label: 'Retry',
                onPressed: () => ref.invalidate(myListingsProvider),
              ),
            ],
          ),
        ),
        data: (listings) {
          if (listings.isEmpty) {
            return CgeEmptyState(
              icon: '\u{1F3F7}',
              title: 'No listings yet',
              subtitle: 'List your first item!',
              actionLabel: 'Create Listing',
              onAction: () => context.push('/marketplace/create'),
            );
          }

          return RefreshIndicator(
            color: AppColors.cyan,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              ref.invalidate(myListingsProvider);
              await ref.read(myListingsProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: listings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final listing = listings[index];
                return _ListingCard(
                  listing: listing,
                  onTap: () => context.push('/marketplace/${listing.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final MarketplaceListing listing;
  final VoidCallback onTap;

  const _ListingCard({required this.listing, required this.onTap});

  BadgeColor get _statusColor {
    switch (listing.status) {
      case 'active':
        return BadgeColor.green;
      case 'sold':
        return BadgeColor.gold;
      case 'archived':
        return BadgeColor.red;
      default:
        return BadgeColor.cyan;
    }
  }

  String get _priceLabel {
    if (listing.listingType == 'swap') return 'Swap';
    if (listing.price != null) return Pricing.formatPrice(listing.price!);
    if (listing.buyoutPrice != null) {
      return Pricing.formatPrice(listing.buyoutPrice!);
    }
    return 'Free';
  }

  BadgeColor get _priceColor {
    if (listing.listingType == 'swap') return BadgeColor.magenta;
    return BadgeColor.cyan;
  }

  @override
  Widget build(BuildContext context) {
    return CgeCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(16)),
            child: SizedBox(
              width: 100,
              height: 100,
              child: listing.images.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: listing.images.first,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        color: AppColors.surfaceAlt,
                        child: const Icon(LucideIcons.image,
                            color: AppColors.textMuted),
                      ),
                      errorWidget: (_, _, _) => Container(
                        color: AppColors.surfaceAlt,
                        child: const Icon(LucideIcons.image,
                            color: AppColors.textMuted),
                      ),
                    )
                  : Container(
                      color: AppColors.surfaceAlt,
                      child: const Center(
                        child: Icon(LucideIcons.image,
                            size: 32, color: AppColors.textMuted),
                      ),
                    ),
            ),
          ),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          listing.title,
                          style:
                              AppTypography.subheading.copyWith(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CgeBadge(
                        label: listing.status.toUpperCase(),
                        color: _statusColor,
                        fontSize: 9,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Category + condition badges
                  Row(
                    children: [
                      CgeBadge(
                        label: listing.category,
                        color: BadgeColor.cyan,
                        fontSize: 10,
                      ),
                      const SizedBox(width: 6),
                      CgeBadge(
                        label: listing.condition,
                        color: BadgeColor.gold,
                        fontSize: 10,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Price + stats
                  Row(
                    children: [
                      CgeBadge(
                        label: _priceLabel,
                        color: _priceColor,
                        fontSize: 11,
                      ),
                      const Spacer(),
                      const Icon(LucideIcons.eye,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text('${listing.viewsCount}',
                          style: AppTypography.bodySmall.copyWith(fontSize: 11)),
                      const SizedBox(width: 10),
                      const Icon(LucideIcons.heart,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text('${listing.savesCount}',
                          style: AppTypography.bodySmall.copyWith(fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
