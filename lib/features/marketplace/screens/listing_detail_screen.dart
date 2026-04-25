import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/pricing.dart';
import '../../../data/models/marketplace_listing.dart';
import '../../../providers/marketplace_provider.dart';
import '../../../widgets/cge_button.dart';
import '../../../widgets/cge_badge.dart';
import '../../../widgets/cge_card.dart';
import '../../../widgets/cge_avatar.dart';
import '../../../widgets/cge_skeleton.dart';

// Provider to fetch a single listing by ID
final listingDetailProvider =
    FutureProvider.family<MarketplaceListing?, String>((ref, id) async {
  return ref.read(marketplaceRepositoryProvider).getListingById(id);
});

class ListingDetailScreen extends ConsumerStatefulWidget {
  final String listingId;

  const ListingDetailScreen({super.key, required this.listingId});

  @override
  ConsumerState<ListingDetailScreen> createState() =>
      _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  int _currentImageIndex = 0;
  bool _isSaved = false;
  bool _viewRecorded = false;

  @override
  void initState() {
    super.initState();
    _recordView();
  }

  Future<void> _recordView() async {
    if (_viewRecorded) return;
    _viewRecorded = true;
    try {
      await ref
          .read(marketplaceRepositoryProvider)
          .recordView(widget.listingId);
    } catch (_) {
      // Silently fail — view tracking is non-critical
    }
  }

  Future<void> _toggleSave() async {
    try {
      final saved = await ref
          .read(marketplaceRepositoryProvider)
          .toggleSave(widget.listingId);
      setState(() => _isSaved = saved);
      // Refresh the listing detail to update saves count
      ref.invalidate(listingDetailProvider(widget.listingId));
      ref.invalidate(savedListingsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  String _formatListingType(String type) {
    switch (type) {
      case 'swap':
        return 'Swap';
      case 'sell':
        return 'Sell';
      case 'sell_or_swap':
        return 'Sell or Swap';
      default:
        return type;
    }
  }

  BadgeColor _typeBadgeColor(String type) {
    switch (type) {
      case 'swap':
        return BadgeColor.magenta;
      case 'sell':
        return BadgeColor.cyan;
      default:
        return BadgeColor.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingAsync = ref.watch(listingDetailProvider(widget.listingId));

    return listingAsync.when(
      loading: () => _buildLoadingSkeleton(),
      error: (error, _) => _buildErrorState(error),
      data: (listing) {
        if (listing == null) return _buildNotFoundState();

        // Initialize saved state from listing data on first load
        if (!_viewRecorded) {
          _isSaved = listing.userHasSaved;
        }

        return _buildContent(listing);
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            leading: _CircleBackButton(onTap: () => context.pop()),
            flexibleSpace: const FlexibleSpaceBar(
              background: CgeSkeleton(height: 300, borderRadius: 0),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  CgeSkeleton.text(width: 250),
                  SizedBox(height: 12),
                  CgeSkeleton.text(width: 150),
                  SizedBox(height: 12),
                  CgeSkeleton.text(width: 100),
                  SizedBox(height: 24),
                  CgeSkeleton(height: 80),
                  SizedBox(height: 24),
                  CgeSkeleton(height: 60),
                  SizedBox(height: 24),
                  CgeSkeleton(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('😵', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text('Failed to load listing',
                  style: AppTypography.subheading),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style:
                    AppTypography.body.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              CgeButton(
                label: 'Retry',
                onPressed: () => ref.invalidate(
                    listingDetailProvider(widget.listingId)),
                icon: LucideIcons.refreshCw,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('Listing not found', style: AppTypography.subheading),
            const SizedBox(height: 8),
            Text(
              'This listing may have been removed.',
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(MarketplaceListing listing) {
    final imageCount = listing.images.isNotEmpty ? listing.images.length : 1;
    final displayType = _formatListingType(listing.listingType);
    final seller = listing.seller;
    final showSwap =
        listing.listingType == 'swap' || listing.listingType == 'sell_or_swap';
    final showPrice =
        listing.listingType == 'sell' || listing.listingType == 'sell_or_swap';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Image gallery with back button
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            leading: _CircleBackButton(onTap: () => context.pop()),
            actions: [
              _CircleActionButton(
                icon: _isSaved ? LucideIcons.heartOff : LucideIcons.heart,
                color: _isSaved ? AppColors.magenta : AppColors.text,
                onTap: _toggleSave,
              ),
              _CircleActionButton(
                icon: LucideIcons.share2,
                onTap: () {},
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image gallery (swipeable)
                  PageView.builder(
                    itemCount: imageCount,
                    onPageChanged: (i) =>
                        setState(() => _currentImageIndex = i),
                    itemBuilder: (context, i) {
                      if (listing.images.isNotEmpty) {
                        return Image.network(
                          listing.images[i],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(
                              i, imageCount),
                        );
                      }
                      return _imagePlaceholder(i, imageCount);
                    },
                  ),
                  // Image dots
                  if (imageCount > 1)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          imageCount,
                          (i) => Container(
                            width: _currentImageIndex == i ? 20 : 8,
                            height: 8,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: _currentImageIndex == i
                                  ? AppColors.cyan
                                  : AppColors.text.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + type badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child:
                            Text(listing.title, style: AppTypography.heading),
                      ),
                      const SizedBox(width: 8),
                      CgeBadge(
                          label: displayType,
                          color: _typeBadgeColor(listing.listingType)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Price + condition
                  Row(
                    children: [
                      if (showPrice && listing.price != null)
                        Text(
                          Pricing.formatPrice(listing.price!),
                          style: AppTypography.mono.copyWith(
                            color: AppColors.cyan,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      if (showPrice && listing.price != null)
                        const SizedBox(width: 12),
                      CgeBadge(
                        label: listing.condition,
                        color: BadgeColor.green,
                        fontSize: 10,
                      ),
                      const SizedBox(width: 8),
                      CgeBadge(
                        label: listing.category,
                        color: BadgeColor.cyan,
                        fontSize: 10,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Views + saves
                  Row(
                    children: [
                      Icon(LucideIcons.eye,
                          size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${listing.viewsCount} views',
                        style: AppTypography.labelSmall,
                      ),
                      const SizedBox(width: 16),
                      Icon(LucideIcons.heart,
                          size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${listing.savesCount} saves',
                        style: AppTypography.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Description
                  if (listing.description != null &&
                      listing.description!.isNotEmpty) ...[
                    Text('Description', style: AppTypography.subheading),
                    const SizedBox(height: 8),
                    Text(
                      listing.description!,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textMuted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Swap wants
                  if (listing.swapForTags.isNotEmpty) ...[
                    Text('Open to swap for',
                        style: AppTypography.subheading),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: listing.swapForTags
                          .map((tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.magenta
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.magenta
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: AppTypography.label.copyWith(
                                    color: AppColors.magenta,
                                    fontSize: 12,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Seller card
                  if (seller != null) ...[
                    Text('Seller', style: AppTypography.subheading),
                    const SizedBox(height: 10),
                    CgeCard(
                      child: Row(
                        children: [
                          CgeAvatar(
                            name: seller.fullName,
                            imageUrl: seller.avatarUrl,
                            size: 48,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      seller.fullName,
                                      style: AppTypography.subheading
                                          .copyWith(fontSize: 14),
                                    ),
                                    if (seller.trustLevel != null) ...[
                                      const SizedBox(width: 6),
                                      CgeBadge(
                                        label: seller.trustLevel!,
                                        color: BadgeColor.green,
                                        fontSize: 9,
                                      ),
                                    ],
                                  ],
                                ),
                                if (seller.gamertag != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '@${seller.gamertag}',
                                    style:
                                        AppTypography.labelSmall.copyWith(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (seller.avgRating != null) ...[
                                      Icon(LucideIcons.star,
                                          size: 12,
                                          color: AppColors.gold),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${seller.avgRating!.toStringAsFixed(1)} (${seller.ratingCount ?? 0} reviews)',
                                        style: AppTypography.labelSmall
                                            .copyWith(fontSize: 11),
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                    Text(
                                      'Member since ${_formatDate(seller.createdAt)}',
                                      style:
                                          AppTypography.labelSmall.copyWith(
                                        color: AppColors.textMuted,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(LucideIcons.chevronRight,
                              size: 16, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Bottom spacing for action bar
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      // Action buttons
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: CgeButton(
                label: 'Message Seller',
                onPressed: () =>
                    context.push('/messages/${listing.sellerId}'),
                variant: CgeButtonVariant.secondary,
                icon: LucideIcons.messageCircle,
              ),
            ),
            if (showSwap) ...[
              const SizedBox(width: 10),
              Expanded(
                child: CgeButton(
                  label: 'Propose Swap',
                  onPressed: () => context.push(
                    '/marketplace/${widget.listingId}/swap?title=${Uri.encodeComponent(listing.title)}',
                  ),
                  variant: CgeButtonVariant.magenta,
                  icon: LucideIcons.repeat,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder(int index, int total) {
    return Container(
      color: AppColors.surfaceAlt,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.image, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 8),
          Text(
            'Image ${index + 1} of $total',
            style: AppTypography.labelSmall,
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return isoDate;
    }
  }
}

// ─── Helper Widgets ─────────────────────────────────

class _CircleBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CircleBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.base.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.arrowLeft, size: 20),
        ),
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;

  const _CircleActionButton({
    required this.icon,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.base.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color ?? AppColors.text),
        ),
      ),
    );
  }
}
