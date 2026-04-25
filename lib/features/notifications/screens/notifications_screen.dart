import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/cge_card.dart';
import '../../../widgets/cge_empty_state.dart';

// ─── Notification Model (inline, Supabase-ready) ────────

enum NotificationType { booking, marketplace, tournament, community, event }

class AppNotification {
  final int id;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.data,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      data: data,
    );
  }
}

// ─── Provider (placeholder, returns empty list for now) ──

final notificationsProvider = StateProvider<List<AppNotification>>((_) => []);

// ─── Notifications Screen ────────────────────────────────

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                final notifier = ref.read(notificationsProvider.notifier);
                notifier.state = notifications
                    .map((n) => n.copyWith(isRead: true))
                    .toList();
              },
              child: Text(
                'Mark all read',
                style: AppTypography.labelSmall.copyWith(color: AppColors.cyan),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? const CgeEmptyState(
              icon: '\u{1F514}',
              title: 'No notifications yet',
              subtitle:
                  "You'll see booking confirmations, swap proposals, and tournament updates here",
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationTile(
                  notification: notification,
                  onTap: () => _handleTap(context, ref, notification),
                );
              },
            ),
    );
  }

  void _handleTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) {
    // Mark as read on tap
    if (!notification.isRead) {
      final notifier = ref.read(notificationsProvider.notifier);
      final current = ref.read(notificationsProvider);
      notifier.state = current.map((n) {
        if (n.id == notification.id) return n.copyWith(isRead: true);
        return n;
      }).toList();
    }

    // Navigate based on type (placeholders for now)
    final data = notification.data;
    switch (notification.type) {
      case NotificationType.booking:
        if (data != null && data['bookingId'] != null) {
          context.push('/lounge');
        }
        break;
      case NotificationType.marketplace:
        if (data != null && data['listingId'] != null) {
          context.push('/marketplace/${data['listingId']}');
        }
        break;
      case NotificationType.tournament:
        if (data != null && data['tournamentId'] != null) {
          context.push('/esports/${data['tournamentId']}');
        }
        break;
      case NotificationType.community:
        if (data != null && data['postId'] != null) {
          context.push('/community/${data['postId']}');
        }
        break;
      case NotificationType.event:
        if (data != null && data['eventId'] != null) {
          context.push('/events/${data['eventId']}');
        }
        break;
    }
  }
}

// ─── Notification Tile ───────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  IconData get _typeIcon {
    switch (notification.type) {
      case NotificationType.booking:
        return LucideIcons.calendar;
      case NotificationType.marketplace:
        return LucideIcons.tag;
      case NotificationType.tournament:
        return LucideIcons.trophy;
      case NotificationType.community:
        return LucideIcons.users;
      case NotificationType.event:
        return LucideIcons.partyPopper;
    }
  }

  Color get _typeColor {
    switch (notification.type) {
      case NotificationType.booking:
        return AppColors.cyan;
      case NotificationType.marketplace:
        return AppColors.gold;
      case NotificationType.tournament:
        return AppColors.magenta;
      case NotificationType.community:
        return AppColors.green;
      case NotificationType.event:
        return AppColors.magenta;
    }
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: CgeCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_typeIcon, size: 18, color: _typeColor),
              ),
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
                            notification.title,
                            style: AppTypography.subheading.copyWith(
                              fontSize: 14,
                              fontWeight: notification.isRead
                                  ? FontWeight.w400
                                  : FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatRelativeTime(notification.createdAt),
                          style: AppTypography.labelSmall.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: AppTypography.bodySmall.copyWith(
                        color: notification.isRead
                            ? AppColors.textMuted
                            : AppColors.text.withValues(alpha: 0.8),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Unread dot
              if (!notification.isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: AppColors.cyan,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
