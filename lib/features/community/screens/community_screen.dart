import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/community_post.dart';
import '../../../data/remote/supabase_config.dart';
import '../../../providers/community_provider.dart';
import '../../../widgets/cge_avatar.dart';
import '../../../widgets/cge_badge.dart';
import '../../../widgets/cge_card.dart';
import '../../../widgets/cge_skeleton.dart';
import '../../../widgets/cge_button.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  String _sortBy = 'Recent';
  String _topic = 'All';
  String _search = '';

  static const _sorts = [
    'Recent',
    'Trending',
    'Most Liked',
    'My Posts',
    'Bookmarks',
  ];

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
    'search': _search.trim().isEmpty ? null : _search.trim(),
    'sortBy': _sortByToField(_sortBy),
  };

  Future<void> _refresh() async {
    ref.invalidate(communityPostsProvider(_filters));
  }

  void _promptSignIn(String action) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Please sign in to $action')));
    context.push('/auth');
  }

  Future<void> _showCreatePostSheet() async {
    if (SupabaseConfig.currentUser == null) {
      _promptSignIn('post in the community');
      return;
    }

    final controller = TextEditingController();
    var topic = _topic == 'All' ? 'general' : _topic;
    var submitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Post', style: AppTypography.headingSmall),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                minLines: 4,
                maxLines: 8,
                maxLength: 2000,
                decoration: const InputDecoration(
                  hintText: 'Share something with the CGE community…',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: topic,
                decoration: const InputDecoration(labelText: 'Topic'),
                items: AppConstants.communityTopics
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.replaceAll('-', ' ')),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setSheetState(() => topic = value);
                },
              ),
              const SizedBox(height: 16),
              CgeButton(
                label: 'Publish',
                fullWidth: true,
                isLoading: submitting,
                onPressed: submitting
                    ? null
                    : () async {
                        final content = controller.text.trim();
                        if (content.isEmpty) return;
                        setSheetState(() => submitting = true);
                        try {
                          await ref
                              .read(communityRepositoryProvider)
                              .createPost(content: content, topic: topic);
                          ref.invalidate(communityPostsProvider);
                          if (sheetContext.mounted) {
                            Navigator.of(sheetContext).pop();
                          }
                        } catch (error) {
                          if (sheetContext.mounted) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Could not publish post. Please try again.',
                                ),
                              ),
                            );
                            setSheetState(() => submitting = false);
                          }
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
    controller.dispose();
  }

  Future<void> _showSearchSheet() async {
    final controller = TextEditingController(text: _search);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Search Community', style: AppTypography.headingSmall),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                prefixIcon: Icon(LucideIcons.search),
                hintText: 'Search posts or topics',
              ),
              onSubmitted: (value) =>
                  Navigator.of(sheetContext).pop(value.trim()),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CgeButton(
                    label: 'Search',
                    onPressed: () =>
                        Navigator.of(sheetContext).pop(controller.text.trim()),
                  ),
                ),
                if (_search.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(''),
                    child: const Text('Clear'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (result != null && mounted) {
      setState(() => _search = result);
    }
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
            onPressed: _showSearchSheet,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostSheet,
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
              children: _sorts
                  .map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(s),
                        selected: _sortBy == s,
                        selectedColor: AppColors.cyan.withValues(alpha: 0.2),
                        onSelected: (_) => setState(() => _sortBy = s),
                        side: BorderSide(
                          color: _sortBy == s
                              ? AppColors.cyan
                              : AppColors.border,
                        ),
                      ),
                    ),
                  )
                  .toList(),
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
                ...AppConstants.communityTopics.map(
                  (t) => _TopicChip(
                    label: t.replaceAll('-', ' '),
                    isSelected: _topic == t,
                    onTap: () => setState(() => _topic = t),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          if (_search.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: CgeBadge(
                      label: 'Search: ${_search.trim()}',
                      color: BadgeColor.cyan,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 16),
                    onPressed: () => setState(() => _search = ''),
                  ),
                ],
              ),
            ),

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
      itemBuilder: (_, _) => Padding(
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
            const Icon(
              LucideIcons.wifiOff,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load posts',
              style: AppTypography.label,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again.',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textMuted,
              ),
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
            const Icon(
              LucideIcons.messageSquare,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text('No posts yet', style: AppTypography.label),
            const SizedBox(height: 8),
            Text(
              'Be the first to post in this topic!',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textMuted,
              ),
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

class _PostCard extends ConsumerWidget {
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

  void _promptSignIn(BuildContext context, String action) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Please sign in to $action')));
    context.push('/auth');
  }

  Future<void> _toggleLike(BuildContext context, WidgetRef ref) async {
    if (SupabaseConfig.currentUser == null) {
      _promptSignIn(context, 'like posts');
      return;
    }

    try {
      await ref.read(communityRepositoryProvider).toggleLike(post.id);
      ref.invalidate(communityPostsProvider);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update like. Please try again.'),
        ),
      );
    }
  }

  Future<void> _toggleBookmark(BuildContext context, WidgetRef ref) async {
    if (SupabaseConfig.currentUser == null) {
      _promptSignIn(context, 'bookmark posts');
      return;
    }

    try {
      await ref.read(communityRepositoryProvider).toggleBookmark(post.id);
      ref.invalidate(communityPostsProvider);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update bookmark. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  CgeAvatar(name: displayName, imageUrl: avatarUrl, size: 36),
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
                                style: AppTypography.labelSmall.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          _timeAgo(post.createdAt),
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (post.isPinned)
                    const CgeBadge(
                      label: 'Pinned',
                      color: BadgeColor.gold,
                      fontSize: 9,
                    ),
                  IconButton(
                    icon: const Icon(LucideIcons.moreHorizontal, size: 16),
                    onPressed: () => _showPostActions(context, ref),
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
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Hashtags (displayed as reaction-style chips)
              if (post.hashtags != null && post.hashtags!.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: post.hashtags!
                      .take(5)
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
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
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
              ],

              // Action bar
              Row(
                children: [
                  _ActionButton(
                    icon: post.userHasLiked
                        ? LucideIcons.heartOff
                        : LucideIcons.heart,
                    label: '${post.likesCount}',
                    active: post.userHasLiked,
                    onTap: () => _toggleLike(context, ref),
                  ),
                  const SizedBox(width: 16),
                  _ActionButton(
                    icon: LucideIcons.messageCircle,
                    label: '${post.commentsCount}',
                  ),
                  const SizedBox(width: 16),
                  _ActionButton(
                    icon: LucideIcons.share2,
                    label: '',
                    onTap: () => Share.share(
                      '${post.content}\n\nShared from CGE Community',
                    ),
                  ),
                  const Spacer(),
                  _ActionButton(
                    icon: LucideIcons.bookmark,
                    label: '',
                    active: post.bookmarked ?? false,
                    onTap: () => _toggleBookmark(context, ref),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPostActions(BuildContext context, WidgetRef ref) async {
    if (SupabaseConfig.currentUser == null) {
      _promptSignIn(context, 'report posts');
      return;
    }

    const reasons = <String, String>{
      'spam': 'Spam',
      'harassment': 'Harassment',
      'hate_speech': 'Hate speech',
      'misinformation': 'Misinformation',
      'nsfw': 'Inappropriate content',
      'impersonation': 'Impersonation',
      'other': 'Other',
    };
    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              leading: Icon(LucideIcons.flag, color: AppColors.red),
              title: Text('Report post'),
              subtitle: Text('Tell us what is wrong with this post'),
            ),
            ...reasons.entries.map(
              (entry) => ListTile(
                title: Text(entry.value),
                onTap: () => Navigator.of(context).pop(entry.key),
              ),
            ),
          ],
        ),
      ),
    );
    if (reason == null) return;
    try {
      await ref
          .read(communityRepositoryProvider)
          .reportPost(postId: post.id, reason: reason);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted for review')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not submit report. Please try again.'),
          ),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Action button
// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.magenta : AppColors.textMuted;
    return GestureDetector(
      onTap: onTap,
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
