import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/cge_card.dart';
import '../../../widgets/cge_badge.dart';
import '../../../widgets/cge_avatar.dart';
import '../../../widgets/cge_skeleton.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/tournament_provider.dart';
import '../../../providers/marketplace_provider.dart';
import '../../../providers/community_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _defaultFilters = <String, String?>{
    'category': null,
    'listingType': null,
    'search': null,
  };

  static const _communityFilters = <String, dynamic>{
    'sortBy': 'created_at',
    'limit': 2,
  };

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _formatPrice(int? price) {
    if (price == null || price == 0) return 'Free';
    final str = price.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return '\u20A6$buffer';
  }

  String _listingTypeLabel(String type) {
    switch (type) {
      case 'sell':
        return 'Sell';
      case 'swap':
        return 'Swap';
      case 'sell_or_swap':
        return 'Sell or Swap';
      default:
        return type;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'Live';
      case 'full':
        return 'Full';
      case 'completed':
        return 'Done';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  BadgeColor _statusBadgeColor(String status) {
    switch (status) {
      case 'in_progress':
        return BadgeColor.green;
      case 'open':
        return BadgeColor.cyan;
      case 'full':
        return BadgeColor.gold;
      case 'cancelled':
        return BadgeColor.red;
      default:
        return BadgeColor.cyan;
    }
  }


  String _timeAgo(String createdAt) {
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}w';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.valueOrNull;
    final tournaments = ref.watch(tournamentsProvider(null));
    final listings = ref.watch(listingsProvider(_defaultFilters));
    final posts = ref.watch(communityPostsProvider(_communityFilters));

    final firstName = (user?.userMetadata?['full_name'] as String?)
            ?.split(' ')
            .first ??
        'Gamer';

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ─── Header ───────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/cge_logo.png',
                      height: 32,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        LucideIcons.bell,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        if (user == null) {
                          context.push('/auth');
                        } else {
                          context.go('/profile');
                        }
                      },
                      child: CgeAvatar(
                        imageUrl:
                            user?.userMetadata?['avatar_url'] as String?,
                        name: user?.userMetadata?['full_name'] as String? ??
                            'G',
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Greeting ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  user != null
                      ? '${_greeting()}, $firstName'
                      : '${_greeting()}, welcome',
                  style: AppTypography.headingSmall,
                ),
              ),
            ),

            // ─── Quick Action Chips ───────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _ActionChip(
                        icon: LucideIcons.gamepad2,
                        label: 'Book',
                        onTap: () => context.push('/lounge'),
                      ),
                      const SizedBox(width: 8),
                      _ActionChip(
                        icon: LucideIcons.shoppingBag,
                        label: 'Market',
                        onTap: () => context.go('/marketplace'),
                      ),
                      const SizedBox(width: 8),
                      _ActionChip(
                        icon: LucideIcons.trophy,
                        label: 'Tournaments',
                        onTap: () => context.go('/esports'),
                      ),
                      const SizedBox(width: 8),
                      _ActionChip(
                        icon: LucideIcons.users,
                        label: 'Community',
                        onTap: () => context.push('/community'),
                      ),
                      const SizedBox(width: 8),
                      _ActionChip(
                        icon: LucideIcons.barChart2,
                        label: 'Leaderboard',
                        onTap: () => context.push('/leaderboard'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── Tournaments Section ──────────────────────
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'TOURNAMENTS',
                onSeeAll: () => context.go('/esports'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: tournaments.when(
                  loading: () => const _SectionSkeleton(itemCount: 3),
                  error: (_, __) => _ErrorRow(
                    message: 'Could not load tournaments',
                    onRetry: () => ref.invalidate(tournamentsProvider(null)),
                  ),
                  data: (list) {
                    if (list.isEmpty) {
                      return const _EmptyRow(
                          message: 'No tournaments right now');
                    }
                    final items = list.take(3).toList();
                    return CgeCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (var i = 0; i < items.length; i++) ...[
                            if (i > 0)
                              const Divider(
                                height: 1,
                                color: AppColors.border,
                              ),
                            InkWell(
                              onTap: () =>
                                  context.push('/esports/${items[i].id}'),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            items[i].title,
                                            style: AppTypography.subheading,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${items[i].filled}/${items[i].slots} players  ·  ${_formatPrice(items[i].prize)}',
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    CgeBadge(
                                      label: _statusLabel(items[i].status),
                                      color:
                                          _statusBadgeColor(items[i].status),
                                      fontSize: 11,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // ─── Marketplace Section ──────────────────────
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'MARKETPLACE',
                onSeeAll: () => context.go('/marketplace'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: listings.when(
                  loading: () => const _SectionSkeleton(itemCount: 3),
                  error: (_, __) => _ErrorRow(
                    message: 'Could not load listings',
                    onRetry: () =>
                        ref.invalidate(listingsProvider(_defaultFilters)),
                  ),
                  data: (list) {
                    if (list.isEmpty) {
                      return const _EmptyRow(message: 'No listings yet');
                    }
                    final items = list.take(3).toList();
                    return CgeCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (var i = 0; i < items.length; i++) ...[
                            if (i > 0)
                              const Divider(
                                height: 1,
                                color: AppColors.border,
                              ),
                            InkWell(
                              onTap: () => context
                                  .push('/marketplace/${items[i].id}'),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            items[i].title,
                                            style: AppTypography.subheading,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${_listingTypeLabel(items[i].listingType)}  ·  ${items[i].condition}',
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      items[i].price != null
                                          ? _formatPrice(items[i].price)
                                          : _listingTypeLabel(
                                              items[i].listingType),
                                      style: AppTypography.mono.copyWith(
                                        color: items[i].listingType == 'swap'
                                            ? AppColors.magenta
                                            : AppColors.accent,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // ─── Community Section ────────────────────────
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'COMMUNITY',
                onSeeAll: () => context.push('/community'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: posts.when(
                  loading: () => const _SectionSkeleton(itemCount: 2),
                  error: (_, __) => _ErrorRow(
                    message: 'Could not load posts',
                    onRetry: () => ref
                        .invalidate(communityPostsProvider(_communityFilters)),
                  ),
                  data: (list) {
                    if (list.isEmpty) {
                      return const _EmptyRow(message: 'No posts yet');
                    }
                    final items = list.take(2).toList();
                    return CgeCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (var i = 0; i < items.length; i++) ...[
                            if (i > 0)
                              const Divider(
                                height: 1,
                                color: AppColors.border,
                              ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CgeAvatar(
                                        imageUrl:
                                            items[i].author?.avatarUrl,
                                        name: items[i].author?.fullName ??
                                            'User',
                                        size: 28,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          items[i].author?.fullName ??
                                              'User',
                                          style: AppTypography.label,
                                        ),
                                      ),
                                      Text(
                                        _timeAgo(items[i].createdAt),
                                        style:
                                            AppTypography.labelSmall.copyWith(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    items[i].content,
                                    style: AppTypography.body,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(LucideIcons.heart,
                                          size: 14,
                                          color: AppColors.textMuted),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${items[i].likesCount}',
                                        style: AppTypography.labelSmall
                                            .copyWith(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(LucideIcons.messageCircle,
                                          size: 14,
                                          color: AppColors.textMuted),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${items[i].commentsCount}',
                                        style: AppTypography.labelSmall
                                            .copyWith(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // ─── Giveaway Banner ──────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: CgeCard(
                  onTap: () => context.push('/giveaway'),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.gift,
                          size: 20, color: AppColors.gold),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monthly Giveaway',
                              style: AppTypography.subheading,
                            ),
                            Text(
                              'Book a session to enter',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(LucideIcons.chevronRight,
                          size: 18, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom spacing
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

// ─── Action Chip ──────────────────────────────────────

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.label.copyWith(
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeader({
    required this.title,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 8),
      child: Row(
        children: [
          Text(
            title,
            style: AppTypography.labelSmall.copyWith(
              letterSpacing: 1.2,
              color: AppColors.textMuted,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'See all',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Skeleton Loader ──────────────────────────────────

class _SectionSkeleton extends StatelessWidget {
  final int itemCount;

  const _SectionSkeleton({this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return CgeCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          for (var i = 0; i < itemCount; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CgeSkeleton(height: 14, width: 180),
                      SizedBox(height: 6),
                      CgeSkeleton(height: 10, width: 120),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                CgeSkeleton(height: 22, width: 48, borderRadius: 4),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Error Row ────────────────────────────────────────

class _ErrorRow extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorRow({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return CgeCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(LucideIcons.alertTriangle,
              size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style:
                  AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              'Retry',
              style:
                  AppTypography.label.copyWith(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty Row ────────────────────────────────────────

class _EmptyRow extends StatelessWidget {
  final String message;

  const _EmptyRow({required this.message});

  @override
  Widget build(BuildContext context) {
    return CgeCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: Text(
          message,
          style:
              AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
        ),
      ),
    );
  }
}
