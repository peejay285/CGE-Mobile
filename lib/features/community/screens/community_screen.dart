import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/community_post.dart';
import '../../../providers/community_provider.dart';
import '../../../widgets/cge_avatar.dart';
import '../../../widgets/cge_badge.dart';
import '../../../widgets/cge_card.dart';
import '../../../widgets/cge_skeleton.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  String _sortBy = 'Recent';
  String _topic = 'All';

  static const _sorts = ['Recent', 'Trending', 'Most Liked', 'My Posts', 'Bookmarks'];

  /// Maps UI sort labels to provider filter values.
  String _sortByToField(String sort) {
    switch (sort) {
      case 'Trending':
        return 'likes_count';
      case 'Most Liked':
        return 'likes_count';
      default:
        return 'created_at';
    }
  }

  Map<String, dynamic> get _filters => {
        'topic': _topic == 'All' ? null : _topic,
        'sortBy': _sortByToField(_sortBy),
  };

  Future<void> _refresh() async {
    ref.invalidate(communityPostsProvider(_filters));
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(communityPostsProvider(_filters));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.search, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.accent,
        child: const Icon(LucideIcons.edit, color: AppColors.text),
      ),
      body: Column(
        children: [
          // Sort tabs
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _sorts.map((s) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(s),
                  selected: _sortBy == s,
                  selectedColor: AppColors.cyan.withValues(alpha: 0.2),
                  onSelected: (_) => setState(() => _sortBy = s),
                  side: BorderSide(
                    color: _sortBy == s ? AppColors.cyan : AppColors.border,
                  ),
                ),
              )).toList(),
            ),
          ),

          // Topic filter
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              children: [
                _TopicChip(
                  label: 'All',
                  isSelected: _topic == 'All',
                  onTap: () => setState(() => _topic = 'All'),
                ),
                ...AppConstants.communityTopics.map((t) => _TopicChip(
                  label: t.replaceAll('-', ' '),
                  isSelected: _topic == t,
                  onTap: () => setState(() => _topic = t),
                )),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Posts feed
          Expanded(
            child: postsAsync.when(
              loading: () => const _PostFeedSkeleton(),
              error: (error, _) => _ErrorFeed(onRetry: _refresh),
              data: (posts) => RefreshIndicator(
                color: AppColors.cyan,
                onRefresh: _refresh,
                child: posts.isEmpty
                    ? const _EmptyFeed()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: posts.length,
                        itemBuilder: (context, i) => _PostCard(post: posts[i]),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feed state widgets
// ---------------------------------------------------------------------------

class _PostFeedSkeleton extends StatelessWidget {
  const _PostFeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 4,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: CgeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CgeSkeleton.avatar(size: 36),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      CgeSkeleton.text(width: 120),
                      SizedBox(height: 6),
                      CgeSkeleton.text(width: 80),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const CgeSkeleton.text(),
              const SizedBox(height: 6),
              const CgeSkeleton.text(width: 200),
              const SizedBox(height: 12),
              const CgeSkeleton(height: 14, width: 180),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorFeed extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _ErrorFeed({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.wifiOff, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'Failed to load posts',
              style: AppTypography.label,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again.',
              style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.messageSquare, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('No posts yet', style: AppTypography.label),
            const SizedBox(height: 8),
            Text(
              'Be the first to post in this topic!',
              style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Topic chip
// ---------------------------------------------------------------------------

class _TopicChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TopicChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.magenta.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.magenta : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isSelected ? AppColors.magenta : AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Post card
// ---------------------------------------------------------------------------

class _PostCard extends StatelessWidget {
  final CommunityPost post;

  const _PostCard({required this.post});

  String _timeAgo(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final author = post.author;
    final displayName = author?.fullName ?? 'Unknown';
    final gamertag = author?.gamertag ?? '';
    final avatarUrl = author?.avatarUrl;

    return GestureDetector(
      onTap: () => context.push('/community/${post.id}'),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: CgeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author row
              Row(
                children: [
                  CgeAvatar(
                    name: displayName,
                    imageUrl: avatarUrl,
                    size: 36,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              displayName,
                              style: AppTypography.label.copyWith(fontSize: 13),
                            ),
                            if (gamertag.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(
                                '@$gamertag',
                                style: AppTypography.labelSmall.copyWith(fontSize: 11),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          _timeAgo(post.createdAt),
                          style: AppTypography.labelSmall.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  if (post.isPinned)
                    const CgeBadge(label: 'Pinned', color: BadgeColor.gold, fontSize: 9),
                  IconButton(
                    icon: const Icon(LucideIcons.moreHorizontal, size: 16),
                    onPressed: () {},
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Content
              Text(post.content, style: AppTypography.body),

              // Image preview
              if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    post.imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Hashtags (displayed as reaction-style chips)
              if (post.hashtags != null && post.hashtags!.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: post.hashtags!.take(5).map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '#$tag',
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 11,
                        color: AppColors.cyan,
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 8),
              ],

              // Action bar
              Row(
                children: [
                  _ActionButton(
                    icon: post.userHasLiked ? LucideIcons.heartOff : LucideIcons.heart,
                    label: '${post.likesCount}',
                    active: post.userHasLiked,
                  ),
                  const SizedBox(width: 16),
                  _ActionButton(
                    icon: LucideIcons.messageCircle,
                    label: '${post.commentsCount}',
                  ),
                  const SizedBox(width: 16),
                  const _ActionButton(icon: LucideIcons.share2, label: ''),
                  const Spacer(),
                  _ActionButton(
                    icon: LucideIcons.bookmark,
                    label: '',
                    active: post.bookmarked ?? false,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action button
// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.magenta : AppColors.textMuted;
    return GestureDetector(
      onTap: () {},
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(label, style: AppTypography.labelSmall.copyWith(color: color)),
          ],
        ],
      ),
    );
  }
}
