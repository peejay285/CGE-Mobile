import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/conversation.dart';
import '../../../providers/messages_provider.dart';
import '../../../widgets/cge_avatar.dart';
import '../../../widgets/cge_empty_state.dart';
import '../../../widgets/cge_error_state.dart';
import '../../../widgets/cge_skeleton.dart';
import '../../../widgets/cge_visual_banner.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: CgeVisualBanner(
              imageAsset: 'assets/images/community-hero.jpg',
              eyebrow: 'Your circle',
              title: 'Keep the game going.',
              subtitle: 'Chat safely with buyers, sellers and fellow players.',
              height: 154,
            ),
          ),
          Expanded(
            child: conversationsAsync.when(
              loading: () => const _ConversationListSkeleton(),
              error: (error, _) => CgeErrorState(
                message: 'Could not load messages',
                onRetry: () => ref.invalidate(conversationsProvider),
              ),
              data: (conversations) => conversations.isEmpty
                  ? CgeEmptyState(
                      iconData: LucideIcons.messageCircle,
                      title: 'Your inbox is ready',
                      subtitle:
                          'Start a conversation from a marketplace listing.',
                      actionLabel: 'Browse marketplace',
                      onAction: () => context.go('/marketplace'),
                    )
                  : RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(conversationsProvider),
                      color: AppColors.cyan,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                        itemCount: conversations.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return _ConversationTile(
                            conversation: conversations[index],
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;

  const _ConversationTile({required this.conversation});

  String _displayName() {
    if (conversation.otherUser != null) {
      final name = conversation.otherUser!.fullName.trim();
      return name.isNotEmpty ? name : 'User';
    }
    return 'User';
  }

  String _formatTime(String? isoDate) {
    if (isoDate == null) return '';
    final dt = DateTime.tryParse(isoDate)?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final name = _displayName();
    final lastMsg = conversation.lastMessage;
    final time = _formatTime(lastMsg?.createdAt ?? conversation.updatedAt);
    final hasUnread = conversation.unreadCount > 0;

    return InkWell(
      onTap: () => context.push('/messages/${conversation.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            // Avatar
            CgeAvatar(name: name, size: 48),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: AppTypography.subheading.copyWith(
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(time, style: AppTypography.labelSmall),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (conversation.listingTitle != null) ...[
                    Row(
                      children: [
                        Icon(
                          LucideIcons.shoppingBag,
                          size: 12,
                          color: AppColors.cyan,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            conversation.listingTitle!,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.cyan,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    lastMsg?.content ?? 'No messages yet',
                    style: AppTypography.bodySmall.copyWith(
                      color: hasUnread
                          ? colors.textPrimary
                          : colors.textSecondary,
                      fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Unread badge
            if (hasUnread) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cyan,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${conversation.unreadCount}',
                  style: AppTypography.labelSmall.copyWith(
                    color: const Color(0xFF061019),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConversationListSkeleton extends StatelessWidget {
  const _ConversationListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 4,
      separatorBuilder: (_, _) =>
          const Divider(indent: 76, endIndent: 16, height: 1),
      itemBuilder: (_, _) => const _ConversationTileSkeleton(),
    );
  }
}

class _ConversationTileSkeleton extends StatelessWidget {
  const _ConversationTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const CgeSkeleton.avatar(size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CgeSkeleton.text(width: 120),
                    const Spacer(),
                    CgeSkeleton.text(width: 40),
                  ],
                ),
                const SizedBox(height: 6),
                const CgeSkeleton.text(width: 200),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
