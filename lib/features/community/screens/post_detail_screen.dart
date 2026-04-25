import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/community_post.dart';
import '../../../providers/community_provider.dart';
import '../../../widgets/cge_avatar.dart';
import '../../../widgets/cge_badge.dart';
import '../../../widgets/cge_skeleton.dart';
import '../../../widgets/cge_empty_state.dart';

/// Inline provider to fetch a single post by ID.
/// Uses communityPostsProvider with no filters, then finds the matching post.
final postDetailProvider =
    FutureProvider.family<CommunityPost?, String>((ref, postId) async {
  final repo = ref.read(communityRepositoryProvider);
  // Fetch recent posts — the post should be in there.
  // For a more targeted fetch, a getPostById method would be ideal.
  final posts = await repo.getPosts(limit: 50);
  try {
    return posts.firstWhere((p) => p.id == postId);
  } catch (_) {
    return null;
  }
});

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  final _focusNode = FocusNode();

  // Local optimistic state
  bool? _likeOverride;
  bool? _bookmarkOverride;
  int _likeCountDelta = 0;
  bool _isSubmittingComment = false;

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    final currentlyLiked = _likeOverride ??
        ref.read(postDetailProvider(widget.postId)).valueOrNull?.userHasLiked ??
        false;

    // Optimistic update
    setState(() {
      _likeOverride = !currentlyLiked;
      _likeCountDelta += currentlyLiked ? -1 : 1;
    });

    try {
      await ref.read(communityRepositoryProvider).toggleLike(widget.postId);
    } catch (e) {
      // Revert on failure
      if (mounted) {
        setState(() {
          _likeOverride = currentlyLiked;
          _likeCountDelta += currentlyLiked ? 1 : -1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to toggle like: $e')),
        );
      }
    }
  }

  Future<void> _toggleBookmark() async {
    final currentlyBookmarked = _bookmarkOverride ??
        ref
            .read(postDetailProvider(widget.postId))
            .valueOrNull
            ?.bookmarked ??
        false;

    setState(() => _bookmarkOverride = !currentlyBookmarked);

    try {
      await ref
          .read(communityRepositoryProvider)
          .toggleBookmark(widget.postId);
    } catch (e) {
      if (mounted) {
        setState(() => _bookmarkOverride = currentlyBookmarked);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to toggle bookmark: $e')),
        );
      }
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSubmittingComment) return;

    _commentController.clear();
    _focusNode.unfocus();
    setState(() => _isSubmittingComment = true);

    try {
      await ref.read(communityRepositoryProvider).addComment(
        postId: widget.postId,
        content: text,
      );
      // Refresh comments
      ref.invalidate(postCommentsProvider(widget.postId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment posted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingComment = false);
    }
  }

  String _timeAgo(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final diff = DateTime.now().toUtc().difference(dt);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'just now';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(postDetailProvider(widget.postId));
    final commentsAsync = ref.watch(postCommentsProvider(widget.postId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Post'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.moreHorizontal, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: postAsync.when(
        loading: () => _buildLoadingSkeleton(),
        error: (err, _) => CgeEmptyState(
          icon: '!',
          title: 'Failed to load post',
          subtitle: err.toString(),
          actionLabel: 'Retry',
          onAction: () =>
              ref.invalidate(postDetailProvider(widget.postId)),
        ),
        data: (post) {
          if (post == null) {
            return const CgeEmptyState(
              icon: '!',
              title: 'Post not found',
              subtitle: 'This post may have been deleted.',
            );
          }

          final isLiked = _likeOverride ?? post.userHasLiked;
          final isBookmarked = _bookmarkOverride ?? (post.bookmarked ?? false);
          final likeCount = post.likesCount + _likeCountDelta;
          final authorName = post.author?.fullName ?? 'Unknown';
          final authorTag = post.author?.gamertag ?? '';

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Author row
                    Row(
                      children: [
                        CgeAvatar(
                          name: authorName,
                          size: 44,
                          imageUrl: post.author?.avatarUrl,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authorName,
                                style: AppTypography.subheading
                                    .copyWith(fontSize: 14),
                              ),
                              Text(
                                '${authorTag.isNotEmpty ? '@$authorTag · ' : ''}${_timeAgo(post.createdAt)}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (post.topic != null)
                          CgeBadge(
                              label: post.topic!,
                              color: BadgeColor.cyan,
                              fontSize: 10),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Post content
                    Text(
                      post.content,
                      style: AppTypography.body.copyWith(height: 1.6),
                    ),

                    // Post image
                    if (post.imageUrl != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          post.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ],

                    // Hashtags
                    if (post.hashtags != null &&
                        post.hashtags!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        children: post.hashtags!
                            .map((tag) => Text(
                                  tag.startsWith('#') ? tag : '#$tag',
                                  style: AppTypography.label.copyWith(
                                    color: AppColors.cyan,
                                    fontSize: 12,
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Action bar
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.border),
                          bottom: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _ActionButton(
                            icon: isLiked
                                ? LucideIcons.heartOff
                                : LucideIcons.heart,
                            label: '$likeCount',
                            color: isLiked
                                ? AppColors.magenta
                                : AppColors.textMuted,
                            onTap: _toggleLike,
                          ),
                          _ActionButton(
                            icon: LucideIcons.messageCircle,
                            label: commentsAsync.when(
                              data: (c) => '${c.length}',
                              loading: () => '${post.commentsCount}',
                              error: (_, __) => '${post.commentsCount}',
                            ),
                            onTap: () => _focusNode.requestFocus(),
                          ),
                          _ActionButton(
                            icon: LucideIcons.share2,
                            label: 'Share',
                            onTap: () {},
                          ),
                          _ActionButton(
                            icon: isBookmarked
                                ? LucideIcons.bookmarkMinus
                                : LucideIcons.bookmark,
                            label: isBookmarked ? 'Saved' : 'Save',
                            color: isBookmarked
                                ? AppColors.gold
                                : AppColors.textMuted,
                            onTap: _toggleBookmark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Comments section
                    commentsAsync.when(
                      loading: () => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Comments', style: AppTypography.subheading),
                          const SizedBox(height: 12),
                          ...List.generate(
                            3,
                            (_) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  CgeSkeleton.avatar(size: 32),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CgeSkeleton.text(width: 120),
                                        SizedBox(height: 6),
                                        CgeSkeleton.text(width: 200),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      error: (err, _) => Text(
                        'Failed to load comments: $err',
                        style: AppTypography.body
                            .copyWith(color: AppColors.red),
                      ),
                      data: (comments) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Comments (${comments.length})',
                            style: AppTypography.subheading,
                          ),
                          const SizedBox(height: 12),
                          if (comments.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Center(
                                child: Text(
                                  'No comments yet. Be the first!',
                                  style: AppTypography.body
                                      .copyWith(color: AppColors.textMuted),
                                ),
                              ),
                            )
                          else
                            ...comments.map(
                                (comment) => _CommentCard(
                                      comment: comment,
                                      timeAgo: _timeAgo(comment.createdAt),
                                    )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Comment input
              Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 8,
                  top: 8,
                  bottom: MediaQuery.of(context).padding.bottom + 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        focusNode: _focusNode,
                        style: AppTypography.body,
                        maxLines: 3,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: AppTypography.body
                              .copyWith(color: AppColors.textMuted),
                          filled: true,
                          fillColor: AppColors.surfaceAlt,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: AppColors.cyan),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: _isSubmittingComment
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.base,
                                ),
                              )
                            : const Icon(LucideIcons.send, size: 18),
                        color: AppColors.base,
                        onPressed:
                            _isSubmittingComment ? null : _submitComment,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              CgeSkeleton.avatar(size: 44),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CgeSkeleton.text(width: 140),
                    SizedBox(height: 6),
                    CgeSkeleton.text(width: 100),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const CgeSkeleton(height: 14),
          const SizedBox(height: 8),
          const CgeSkeleton(height: 14, width: 300),
          const SizedBox(height: 8),
          const CgeSkeleton(height: 14, width: 250),
          const SizedBox(height: 24),
          const CgeSkeleton(height: 40),
        ],
      ),
    );
  }
}

// ─── Action Button ──────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color ?? AppColors.textMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color ?? AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Comment Card ───────────────────────────────────

class _CommentCard extends StatelessWidget {
  final PostComment comment;
  final String timeAgo;

  const _CommentCard({required this.comment, required this.timeAgo});

  @override
  Widget build(BuildContext context) {
    final authorName = comment.author?.fullName ?? 'Unknown';
    final authorTag = comment.author?.gamertag;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CgeAvatar(
            name: authorName,
            size: 32,
            imageUrl: comment.author?.avatarUrl,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      authorName,
                      style: AppTypography.label.copyWith(fontSize: 12),
                    ),
                    if (authorTag != null && authorTag.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        '@$authorTag',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      timeAgo,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style:
                      AppTypography.body.copyWith(fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
