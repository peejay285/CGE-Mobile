import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/pricing.dart';
import '../../../data/models/marketplace_listing.dart';
import '../../../providers/marketplace_provider.dart';
import '../../../widgets/cge_badge.dart';
import '../../../widgets/cge_input.dart';
import '../../../widgets/cge_skeleton.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedType = 'All';
  String _sortBy = 'Newest';

  static const _typeFilters = ['All', 'Swap', 'Sell', 'Sell or Swap', 'Saved'];
  static const _sortOptions = ['Newest', 'Oldest', 'Price: Low', 'Price: High'];

  Map<String, String?> get _filters => {
        'category': _selectedCategory == 'All' ? null : _selectedCategory,
        'listingType': _selectedType == 'All' || _selectedType == 'Saved'
            ? null
            : _selectedType.toLowerCase().replaceAll(' ', '_'),
        'search': _searchQuery.isEmpty ? null : _searchQuery,
      };

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(listingsProvider(_filters));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.slidersHorizontal, size: 20),
            onPressed: _showSortSheet,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/marketplace/create'),
        backgroundColor: AppColors.cyan,
        child: const Icon(LucideIcons.plus, color: AppColors.base),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: CgeInput(
              hint: 'Search listings...',
              prefixIcon: LucideIcons.search,
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // Category chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _selectedCategory == 'All',
                  onTap: () => setState(() => _selectedCategory = 'All'),
                ),
                ...AppConstants.marketplaceCategories.map((cat) => _FilterChip(
                      label: cat,
                      isSelected: _selectedCategory == cat,
                      onTap: () => setState(() => _selectedCategory = cat),
                    )),
              ],
            ),
          ),

          // Type filter chips
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              children: _typeFilters
                  .map((type) => _FilterChip(
                        label: type,
                        isSelected: _selectedType == type,
                        onTap: () => setState(() => _selectedType = type),
                        color: type == 'Swap'
                            ? AppColors.magenta
                            : type == 'Saved'
                                ? AppColors.red
                                : null,
                      ))
                  .toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Results count + sort
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                listingsAsync.when(
                  data: (listings) => Text(
                    '${listings.length} listings',
                    style: AppTypography.bodySmall,
                  ),
                  loading: () => const CgeSkeleton.text(width: 80),
                  error: (_, __) => Text('--', style: AppTypography.bodySmall),
                ),
                const Spacer(),
                Text(_sortBy, style: AppTypography.labelSmall),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Listings grid
          Expanded(
            child: listingsAsync.when(
              data: (listings) {
                if (listings.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.shoppingBag,
                              size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 16),
                          Text('No listings yet',
                              style: AppTypography.headingSmall,
                              textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to list something!',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.textMuted),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(listingsProvider(_filters).future),
                  color: AppColors.cyan,
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: listings.length,
                    itemBuilder: (context, i) =>
                        _ListingCard(listing: listings[i]),
                  ),
                );
              },
              loading: () => GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: 6,
                itemBuilder: (_, __) => const CgeSkeleton.card(),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.wifiOff,
                          size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 16),
                      Text('Could not load listings',
                          style: AppTypography.label),
                      const SizedBox(height: 8),
                      Text(
                        'Check your connection and try again.',
                        style: AppTypography.labelSmall
                            .copyWith(color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () =>
                            ref.invalidate(listingsProvider(_filters)),
                        icon: const Icon(LucideIcons.refreshCw, size: 16),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sort by', style: AppTypography.subheading),
            const SizedBox(height: 16),
            ..._sortOptions.map((option) => ListTile(
                  title: Text(option, style: AppTypography.body),
                  trailing: _sortBy == option
                      ? const Icon(LucideIcons.check, color: AppColors.cyan)
                      : null,
                  onTap: () {
                    setState(() => _sortBy = option);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }
}

// ─── Filter Chip ─────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.cyan;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.15)
                : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? activeColor : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isSelected ? activeColor : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Listing Card (uses real MarketplaceListing model) ─

class _ListingCard extends StatelessWidget {
  final MarketplaceListing listing;

  const _ListingCard({required this.listing});

  BadgeColor get _typeBadgeColor {
    switch (listing.listingType) {
      case 'swap':
        return BadgeColor.magenta;
      case 'sell_or_swap':
        return BadgeColor.gold;
      default:
        return BadgeColor.cyan;
    }
  }

  String get _typeLabel {
    switch (listing.listingType) {
      case 'swap':
        return 'Swap';
      case 'sell_or_swap':
        return 'Sell/Swap';
      default:
        return 'Sell';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = listing.images.isNotEmpty;

    return GestureDetector(
      onTap: () => context.push('/marketplace/${listing.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(8)),
                      image: hasImage
                          ? DecorationImage(
                              image: NetworkImage(listing.images.first),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: hasImage
                        ? null
                        : const Center(
                            child: Icon(LucideIcons.image,
                                color: AppColors.textMuted, size: 36),
                          ),
                  ),
                  // Save button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.base.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.heart,
                          size: 16, color: AppColors.textMuted),
                    ),
                  ),
                  // Type badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: CgeBadge(
                        label: _typeLabel, color: _typeBadgeColor, fontSize: 9),
                  ),
                ],
              ),
            ),

            // Info area
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      listing.title,
                      style: AppTypography.label.copyWith(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Text(
                          listing.listingType == 'swap'
                              ? 'Swap only'
                              : Pricing.formatPrice(listing.price ?? 0),
                          style: AppTypography.mono.copyWith(
                            fontSize: 12,
                            color: listing.listingType == 'swap'
                                ? AppColors.magenta
                                : AppColors.cyan,
                          ),
                        ),
                        const Spacer(),
                        Icon(LucideIcons.eye,
                            size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Text('${listing.viewsCount}',
                            style: AppTypography.labelSmall
                                .copyWith(fontSize: 10)),
                      ],
                    ),
                    Row(
                      children: [
                        CgeBadge(
                          label: listing.condition,
                          color: BadgeColor.green,
                          fontSize: 9,
                        ),
                        const Spacer(),
                        Icon(LucideIcons.heart,
                            size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Text('${listing.savesCount}',
                            style: AppTypography.labelSmall
                                .copyWith(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
