import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/marketplace_provider.dart';
import '../../../widgets/cge_button.dart';
import '../../../widgets/cge_card.dart';
import '../../../widgets/cge_badge.dart';
import '../../../widgets/cge_skeleton.dart';
import '../../../widgets/cge_empty_state.dart';
import '../../../widgets/safety_disclaimer_banner.dart';

class SwapProposalScreen extends ConsumerStatefulWidget {
  final String listingId;
  final String listingTitle;

  const SwapProposalScreen({
    super.key,
    required this.listingId,
    required this.listingTitle,
  });

  @override
  ConsumerState<SwapProposalScreen> createState() =>
      _SwapProposalScreenState();
}

class _SwapProposalScreenState extends ConsumerState<SwapProposalScreen> {
  int? _selectedIndex;
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_selectedIndex == null) return;

    final myListings = ref.read(myListingsProvider).valueOrNull;
    if (myListings == null || _selectedIndex! >= myListings.length) return;

    final offeredListing = myListings[_selectedIndex!];

    setState(() => _isSubmitting = true);

    try {
      await ref.read(marketplaceRepositoryProvider).createSwapProposal(
            listingId: widget.listingId,
            offeredListingId: offeredListing.id,
            message: _messageController.text.trim().isNotEmpty
                ? _messageController.text.trim()
                : null,
          );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🤝', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  'Swap Proposal Sent!',
                  style: AppTypography.heading.copyWith(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'The seller will review your proposal and get back to you.',
                  style: AppTypography.body
                      .copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                CgeButton(
                  label: 'Done',
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    context.pop(); // go back
                  },
                  fullWidth: true,
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send proposal: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myListingsAsync = ref.watch(myListingsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Propose Swap'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Target listing
                Text('Swapping for', style: AppTypography.label),
                const SizedBox(height: 8),
                CgeCard(
                  showGlow: true,
                  glowColor: AppColors.magenta,
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(LucideIcons.image,
                            size: 24, color: AppColors.textMuted),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.listingTitle,
                              style: AppTypography.subheading
                                  .copyWith(fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            const CgeBadge(
                              label: 'Swap',
                              color: BadgeColor.magenta,
                              fontSize: 10,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Swap icon
                Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.magenta.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.magenta.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(LucideIcons.arrowUpDown,
                        size: 18, color: AppColors.magenta),
                  ),
                ),
                const SizedBox(height: 24),

                // Select your item
                Text('Select your item to offer',
                    style: AppTypography.label),
                const SizedBox(height: 4),
                Text(
                  'Choose one of your active listings',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),

                // My listings (async)
                myListingsAsync.when(
                  loading: () => Column(
                    children: List.generate(
                      3,
                      (_) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: CgeSkeleton(height: 76, borderRadius: 14),
                      ),
                    ),
                  ),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Text(
                            'Failed to load your listings',
                            style: AppTypography.subheading,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error.toString(),
                            style: AppTypography.body
                                .copyWith(color: AppColors.textMuted),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          CgeButton(
                            label: 'Retry',
                            onPressed: () =>
                                ref.invalidate(myListingsProvider),
                            icon: LucideIcons.refreshCw,
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (listings) {
                    // Filter to only swappable listings
                    final swappable = listings
                        .where((l) =>
                            l.status == 'active' &&
                            (l.listingType == 'swap' ||
                                l.listingType == 'sell_or_swap'))
                        .toList();

                    if (swappable.isEmpty) {
                      return CgeEmptyState(
                        icon: '📦',
                        title: 'No active listings',
                        subtitle:
                            'Create a listing first to propose a swap',
                        actionLabel: 'Create Listing',
                        onAction: () =>
                            context.push('/marketplace/create'),
                      );
                    }

                    return Column(
                      children: [
                        ...swappable.asMap().entries.map((entry) {
                          final i = entry.key;
                          final listing = entry.value;
                          final isSelected = _selectedIndex == i;

                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedIndex = i),
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.magenta
                                        .withValues(alpha: 0.08)
                                    : AppColors.surface,
                                borderRadius:
                                    BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.magenta
                                      : AppColors.border,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Thumbnail
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceAlt,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      border: Border.all(
                                          color: AppColors.border),
                                    ),
                                    child: listing.images.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(
                                                    7),
                                            child: Image.network(
                                              listing.images.first,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (_, __, ___) =>
                                                      const Icon(
                                                LucideIcons.image,
                                                size: 20,
                                                color: AppColors
                                                    .textMuted,
                                              ),
                                            ),
                                          )
                                        : const Icon(
                                            LucideIcons.image,
                                            size: 20,
                                            color:
                                                AppColors.textMuted),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          listing.title,
                                          style: AppTypography.label
                                              .copyWith(fontSize: 13),
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            CgeBadge(
                                              label:
                                                  listing.condition,
                                              color: BadgeColor.green,
                                              fontSize: 9,
                                            ),
                                            const SizedBox(width: 6),
                                            CgeBadge(
                                              label:
                                                  listing.category,
                                              color: BadgeColor.cyan,
                                              fontSize: 9,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Selection indicator
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? AppColors.magenta
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.magenta
                                            : AppColors.border,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(LucideIcons.check,
                                            size: 14,
                                            color: Colors.white)
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 16),

                        // Optional message
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Add a message (optional)',
                              style: AppTypography.label),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _messageController,
                          style: AppTypography.body,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText:
                                'Tell the seller why you want to swap...',
                            hintStyle: AppTypography.body
                                .copyWith(color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.surfaceAlt,
                            contentPadding:
                                const EdgeInsets.all(14),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: AppColors.magenta),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Submit button — only show when listings loaded and non-empty
          if (myListingsAsync.hasValue &&
              myListingsAsync.value!
                  .where((l) =>
                      l.status == 'active' &&
                      (l.listingType == 'swap' ||
                          l.listingType == 'sell_or_swap'))
                  .isNotEmpty)
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border:
                    Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Safety disclaimer (Tier 1 of trust ladder)
                  const SafetyDisclaimerBanner(
                    margin: EdgeInsets.only(bottom: 12),
                  ),
                  CgeButton(
                    label: 'Send Swap Proposal',
                    onPressed: _selectedIndex != null ? _submit : null,
                    fullWidth: true,
                    variant: CgeButtonVariant.magenta,
                    icon: LucideIcons.repeat,
                    isLoading: _isSubmitting,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
