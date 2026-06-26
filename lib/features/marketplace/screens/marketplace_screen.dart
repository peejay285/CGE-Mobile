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
import '../../../providers/auth_provider.dart';
import '../../../providers/geolocation_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../widgets/cge_badge.dart';
import '../../../widgets/cge_empty_state.dart';
import '../../../widgets/cge_input.dart';
import '../../../widgets/cge_skeleton.dart';
import '../../../widgets/cge_visual_banner.dart';

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
  String? _selectedState;
  bool _stateDefaulted = false;
  bool _nearMe = false;

  static const _typeFilters = ['All', 'Swap', 'Sell', 'Sell or Swap', 'Saved'];
  static const _sortOptions = ['Newest', 'Oldest', 'Price: Low', 'Price: High'];

  @override
  void initState() {
    super.initState();
    // Default the state filter to the current user's profile state on first
    // load. Don't override later if they explicitly clear it.
    Future.microtask(() async {
      if (_stateDefaulted) return;
      final user = ref.read(authProvider).valueOrNull;
      if (user == null) return;
      try {
        final profile = await AuthRepository().getProfile();
        if (!mounted || _stateDefaulted) return;
        if (profile?.locationState != null) {
          setState(() {
            _selectedState = profile!.locationState;
            _stateDefaulted = true;
          });
        }
      } catch (_) {
        /* ignore — leave filter as "All states" */
      }
    });
  }

  Map<String, String?> get _filters => {
    'category': _selectedCategory == 'All' ? null : _selectedCategory,
    'listingType': _selectedType == 'All' || _selectedType == 'Saved'
        ? null
        : _selectedType.toLowerCase().replaceAll(' ', '_'),
    'search': _searchQuery.isEmpty ? null : _searchQuery,
    'locationState': _selectedState,
  };

  void _openCreateListing() {
    final user = ref.read(authProvider).valueOrNull;
    if (user != null) {
      context.push('/marketplace/create');
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(LucideIcons.shieldCheck, size: 36, color: AppColors.cyan),
              const SizedBox(height: 14),
              Text('Sign in before listing', style: AppTypography.subheading),
              const SizedBox(height: 8),
              Text(
                'Listings need a verified CGE profile so buyers and swap partners know who they are dealing with.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/auth');
                },
                child: const Text('Sign in or create account'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Keep browsing'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
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
        onPressed: _openCreateListing,
        backgroundColor: AppColors.cyan,
        child: const Icon(LucideIcons.plus, color: Color(0xFF061019)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: CgeVisualBanner(
              imageAsset: 'assets/images/market-hero.jpg',
              eyebrow: 'CGE Market',
              title: 'Trade gaming gear with your community.',
              subtitle: 'Buy, sell or swap with players near you.',
              actionLabel: 'Create listing',
              actionIcon: LucideIcons.plus,
              onAction: _openCreateListing,
              height: 184,
            ),
          ),
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
                ...AppConstants.marketplaceCategories.map(
                  (cat) => _FilterChip(
                    label: cat,
                    isSelected: _selectedCategory == cat,
                    onTap: () => setState(() => _selectedCategory = cat),
                  ),
                ),
              ],
            ),
          ),

          // Type filter chips
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              children: [
                ..._typeFilters.map(
                  (type) => _FilterChip(
                    label: type,
                    isSelected: _selectedType == type,
                    onTap: () => setState(() => _selectedType = type),
                    color: type == 'Swap'
                        ? AppColors.magenta
                        : type == 'Saved'
                        ? AppColors.red
                        : null,
                  ),
                ),
                _FilterChip(
                  label: 'Near me',
                  icon: LucideIcons.navigation,
                  isSelected: _nearMe,
                  color: AppColors.cyan,
                  onTap: () async {
                    if (_nearMe) {
                      setState(() => _nearMe = false);
                      return;
                    }
                    final geo = ref.read(geolocationProvider);
                    if (!geo.hasCoords) {
                      await ref.read(geolocationProvider.notifier).request();
                    }
                    if (!context.mounted) return;
                    final updated = ref.read(geolocationProvider);
                    if (updated.hasCoords) {
                      setState(() => _nearMe = true);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Location unavailable — enable it in your device settings to use Near me.',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          // State filter dropdown
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: colors.surfaceRaised,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedState != null
                      ? AppColors.cyan.withAlpha(80)
                      : colors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.mapPin,
                    size: 16,
                    color: _selectedState != null
                        ? AppColors.cyan
                        : colors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _selectedState,
                        hint: Text(
                          'All states',
                          style: AppTypography.body.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        isExpanded: true,
                        dropdownColor: colors.surfaceRaised,
                        style: AppTypography.body.copyWith(
                          color: colors.textPrimary,
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              'All states',
                              style: AppTypography.body.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                          ...AppConstants.nigerianStates.map(
                            (s) => DropdownMenuItem<String?>(
                              value: s,
                              child: Text(s),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _selectedState = v),
                      ),
                    ),
                  ),
                ],
              ),
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
                  error: (_, _) => Text('--', style: AppTypography.bodySmall),
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
                          Icon(
                            LucideIcons.shoppingBag,
                            size: 48,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No listings yet',
                            style: AppTypography.headingSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to list something!',
                            style: AppTypography.bodySmall.copyWith(
                              color: colors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final geo = ref.watch(geolocationProvider);
                final ordered = (_nearMe && geo.hasCoords)
                    ? (List<MarketplaceListing>.from(listings)..sort((a, b) {
                        final da =
                            (a.locationLat != null && a.locationLng != null)
                            ? haversineKm(
                                geo.lat!,
                                geo.lng!,
                                a.locationLat!,
                                a.locationLng!,
                              )
                            : double.infinity;
                        final db =
                            (b.locationLat != null && b.locationLng != null)
                            ? haversineKm(
                                geo.lat!,
                                geo.lng!,
                                b.locationLat!,
                                b.locationLng!,
                              )
                            : double.infinity;
                        return da.compareTo(db);
                      }))
                    : listings;
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.refresh(listingsProvider(_filters).future),
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
                    itemCount: ordered.length,
                    itemBuilder: (context, i) =>
                        _ListingCard(listing: ordered[i]),
                  ),
                );
              },
              loading: () => _ListingsLoadingState(
                onRetry: () => ref.invalidate(listingsProvider(_filters)),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.wifiOff,
                        size: 48,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Could not load listings',
                        style: AppTypography.label,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check your connection and try again.',
                        style: AppTypography.labelSmall.copyWith(
                          color: colors.textSecondary,
                        ),
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
                          foregroundColor: const Color(0xFF061019),
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
            ..._sortOptions.map(
              (option) => ListTile(
                title: Text(option, style: AppTypography.body),
                trailing: _sortBy == option
                    ? const Icon(LucideIcons.check, color: AppColors.cyan)
                    : null,
                onTap: () {
                  setState(() => _sortBy = option);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingsLoadingState extends StatefulWidget {
  final VoidCallback onRetry;

  const _ListingsLoadingState({required this.onRetry});

  @override
  State<_ListingsLoadingState> createState() => _ListingsLoadingStateState();
}

class _ListingsLoadingStateState extends State<_ListingsLoadingState> {
  late final Future<void> _slowLoadNotice;

  @override
  void initState() {
    super.initState();
    _slowLoadNotice = Future<void>.delayed(const Duration(seconds: 4));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _slowLoadNotice,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: 6,
            itemBuilder: (_, _) => const CgeSkeleton.card(),
          );
        }

        return CgeEmptyState(
          iconData: LucideIcons.loader,
          title: 'Still loading listings',
          subtitle:
              'Marketplace data is taking longer than usual. You can wait, pull to refresh, or try again.',
          actionLabel: 'Try again',
          onAction: widget.onRetry,
        );
      },
    );
  }
}

// ─── Filter Chip ─────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;
  final IconData? icon;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final activeColor = color ?? AppColors.cyan;
    final fg = isSelected ? activeColor : colors.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.15)
                : colors.surfaceRaised,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? activeColor : colors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: fg),
                const SizedBox(width: 4),
              ],
              Text(label, style: AppTypography.labelSmall.copyWith(color: fg)),
            ],
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
    final colors = AppColors.of(context);
    final hasImage = listing.images.isNotEmpty;

    return GestureDetector(
      onTap: () => context.push('/marketplace/${listing.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.border),
          boxShadow: Theme.of(context).brightness == Brightness.light
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
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
                      color: colors.surfaceRaised,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(17),
                      ),
                      image: hasImage
                          ? DecorationImage(
                              image: NetworkImage(listing.images.first),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: hasImage
                        ? null
                        : Center(
                            child: Icon(
                              LucideIcons.image,
                              color: colors.textSecondary,
                              size: 36,
                            ),
                          ),
                  ),
                  // Save button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colors.base.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        LucideIcons.heart,
                        size: 16,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  // Type badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: CgeBadge(
                      label: _typeLabel,
                      color: _typeBadgeColor,
                      fontSize: 9,
                    ),
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
                        Icon(
                          LucideIcons.eye,
                          size: 12,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${listing.viewsCount}',
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 10,
                          ),
                        ),
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
                        Icon(
                          LucideIcons.heart,
                          size: 12,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${listing.savesCount}',
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 10,
                          ),
                        ),
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
