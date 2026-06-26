import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/conversation.dart';
import '../../../data/remote/supabase_config.dart';
import '../../../providers/messages_provider.dart';
import '../../../widgets/cge_avatar.dart';
import '../../../widgets/cge_skeleton.dart';
import '../../../widgets/cge_empty_state.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  /// Local list for real-time appended messages
  final List<Message> _realtimeMessages = [];
  RealtimeChannel? _channel;
  bool _isSending = false;

  String get _currentUserId => SupabaseConfig.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _markConversationRead();
    _subscribeToMessages();
  }

  void _markConversationRead() {
    ref.read(messagesRepositoryProvider).markAsRead(widget.conversationId);
  }

  void _subscribeToMessages() {
    _channel = ref.read(messagesRepositoryProvider).subscribeToMessages(
      widget.conversationId,
      (newRecord) {
        if (!mounted) return;
        final msg = Message.fromJson(Map<String, dynamic>.from(newRecord));
        // Only append if it's not from us (our sent messages are added locally)
        // or if it wasn't already added locally
        if (msg.senderId != _currentUserId) {
          setState(() => _realtimeMessages.add(msg));
          _scrollToBottom();
        }
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    _messageController.clear();
    setState(() => _isSending = true);

    try {
      final sent = await ref
          .read(messagesRepositoryProvider)
          .sendMessage(conversationId: widget.conversationId, content: text);
      if (mounted) {
        setState(() => _realtimeMessages.add(sent));
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _showChatActions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.checkCheck),
              title: const Text('Mark conversation as read'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _markConversationRead();
                ref.invalidate(messagesProvider(widget.conversationId));
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.refreshCw),
              title: const Text('Refresh messages'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                ref.invalidate(messagesProvider(widget.conversationId));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Chat'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.moreVertical, size: 20),
            onPressed: _showChatActions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages area
          Expanded(
            child: messagesAsync.when(
              loading: () => _buildLoadingSkeleton(),
              error: (err, _) => CgeEmptyState(
                icon: '!',
                title: 'Failed to load messages',
                subtitle: err.toString(),
                actionLabel: 'Retry',
                onAction: () =>
                    ref.invalidate(messagesProvider(widget.conversationId)),
              ),
              data: (fetchedMessages) {
                final allMessages = [
                  ...fetchedMessages,
                  ..._realtimeMessages.where(
                    (rt) => !fetchedMessages.any((fm) => fm.id == rt.id),
                  ),
                ];

                if (allMessages.isEmpty) {
                  return const CgeEmptyState(
                    icon: '💬',
                    title: 'No messages yet',
                    subtitle:
                        'Send the first message to start the conversation.',
                  );
                }

                // Scroll to bottom on first load
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: allMessages.length,
                  itemBuilder: (context, i) {
                    final msg = allMessages[i];
                    final isMe = msg.senderId == _currentUserId;
                    final showAvatar =
                        i == 0 || allMessages[i - 1].senderId != msg.senderId;

                    return _MessageBubble(
                      message: msg,
                      isMe: isMe,
                      showAvatar: showAvatar,
                    );
                  },
                );
              },
            ),
          ),

          // Message input
          _MessageInput(
            controller: _messageController,
            focusNode: _focusNode,
            onSend: _sendMessage,
            isSending: _isSending,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          5,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: i.isEven
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.end,
              children: [
                if (i.isEven) ...[
                  const CgeSkeleton.avatar(size: 28),
                  const SizedBox(width: 8),
                ],
                CgeSkeleton(
                  width: 180 + (i * 10).toDouble(),
                  height: 44,
                  borderRadius: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Message Bubble ─────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showAvatar;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showAvatar,
  });

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '$hour:$min $amPm';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: showAvatar ? 12 : 4,
        left: isMe ? 48 : 0,
        right: isMe ? 0 : 48,
      ),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar) ...[
            const CgeAvatar(name: 'User', size: 28),
            const SizedBox(width: 8),
          ] else if (!isMe) ...[
            const SizedBox(width: 36),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.cyan.withValues(alpha: 0.15)
                        : AppColors.surfaceAlt,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    border: Border.all(
                      color: isMe
                          ? AppColors.cyan.withValues(alpha: 0.3)
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: AppTypography.body.copyWith(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.createdAt),
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.isRead
                            ? LucideIcons.checkCheck
                            : LucideIcons.check,
                        size: 12,
                        color: message.isRead
                            ? AppColors.cyan
                            : AppColors.textMuted,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Message Input ──────────────────────────────────

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final bool isSending;

  const _MessageInput({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    this.isSending = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              controller: controller,
              focusNode: focusNode,
              style: AppTypography.body,
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: AppTypography.body.copyWith(
                  color: AppColors.textMuted,
                ),
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
              icon: isSending
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
              onPressed: isSending ? null : onSend,
            ),
          ),
        ],
      ),
    );
  }
}
