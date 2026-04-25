import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/cge_card.dart';

class _Message {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  const _Message({
    required this.role,
    required this.content,
    required this.timestamp,
  });
}

class ConciergeScreen extends ConsumerStatefulWidget {
  const ConciergeScreen({super.key});

  @override
  ConsumerState<ConciergeScreen> createState() => _ConciergeScreenState();
}

class _ConciergeScreenState extends ConsumerState<ConciergeScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_Message> _messages = [];
  bool _isTyping = false;

  static const _suggestedPrompts = [
    'What games are available in VIP?',
    'Help me find a swap for my PS5 controller',
    "When's the next tournament?",
    'Recommend a drink combo',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _getResponse(String prompt) {
    final lower = prompt.toLowerCase();

    if (lower.contains('game') || lower.contains('play')) {
      return 'We have FIFA, Call of Duty, Fortnite, and more! The Main Lounge has '
          'PS5 & Xbox, VIP has private PS5 setups, and our VR Zone features Beat '
          'Saber and Half-Life Alyx. Want me to help you book a session?';
    }
    if (lower.contains('swap') || lower.contains('trade')) {
      return 'Head to the Marketplace tab to browse swap listings. You can filter '
          "by category and condition. Pro tip: items marked 'Swap or Sell' give you "
          'the most flexibility!';
    }
    if (lower.contains('tournament') || lower.contains('compete')) {
      return 'Check the Esports tab for upcoming tournaments! We run weekly FIFA '
          'and Call of Duty tournaments with cash prizes. Entry fees start at \u20A6500.';
    }
    if (lower.contains('drink') || lower.contains('food') || lower.contains('snack')) {
      return 'Our top combo is Chapman + Puff Puff (\u20A61,800 total). We also '
          'have Zobo, Fanta, Chin Chin, and Meat Pie. You can add these when booking '
          'a session!';
    }
    if (lower.contains('book') || lower.contains('session') || lower.contains('reserve')) {
      return "To book a session: tap 'Book Session' on the home screen, pick your "
          'zone (Main \u20A61,500/hr, VIP \u20A65,000/hr, VR \u20A62,000/15min), '
          'choose your game, date, and time, then add optional drinks. Easy!';
    }

    return "I'm your CGE assistant! I can help you book sessions, find "
        'marketplace deals, check tournament schedules, or recommend drinks. '
        'What would you like to know?';
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = _Message(
      role: 'user',
      content: text.trim(),
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });
    _textController.clear();
    _scrollToBottom();

    // Simulate delay
    await Future.delayed(const Duration(milliseconds: 500));

    final response = _getResponse(text);
    final assistantMessage = _Message(
      role: 'assistant',
      content: response,
      timestamp: DateTime.now(),
    );

    if (!mounted) return;
    setState(() {
      _messages.add(assistantMessage);
      _isTyping = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(
        backgroundColor: AppColors.base,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('\u{1F916} ', style: TextStyle(fontSize: 20)),
            Text('AI Concierge', style: AppTypography.headingSmall),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _messages.isEmpty ? _buildSuggestedPrompts() : _buildMessagesList(),
          ),

          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildSuggestedPrompts() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('\u{1F916}', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('CGE Concierge', style: AppTypography.heading),
            const SizedBox(height: 8),
            Text(
              'Ask me anything about the lounge!',
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            ..._suggestedPrompts.map((prompt) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: CgeCard(
                    onTap: () => _sendMessage(prompt),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(LucideIcons.sparkles, size: 16, color: AppColors.cyan),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(prompt, style: AppTypography.body),
                        ),
                        Icon(LucideIcons.chevronRight,
                            size: 16, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        // Typing indicator
        if (index == _messages.length && _isTyping) {
          return _buildTypingIndicator();
        }
        final message = _messages[index];
        return message.role == 'user'
            ? _buildUserMessage(message)
            : _buildAssistantMessage(message);
      },
    );
  }

  Widget _buildUserMessage(_Message message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 48),
      child: Align(
        alignment: Alignment.centerRight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
                border: Border.all(
                  color: AppColors.cyan.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(message.content, style: AppTypography.body),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: AppTypography.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssistantMessage(_Message message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Robot avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text('\u{1F916}', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Text(message.content, style: AppTypography.body),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: AppTypography.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text('\u{1F916}', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              style: AppTypography.body,
              decoration: InputDecoration(
                hintText: 'Ask anything...',
                hintStyle: AppTypography.body.copyWith(color: AppColors.textMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.cyan),
                ),
                filled: true,
                fillColor: AppColors.surfaceAlt,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendMessage(_textController.text),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.send, size: 18, color: AppColors.base),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

/// Animated typing dots indicator
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.2;
            final t = (_controller.value - delay).clamp(0.0, 1.0);
            final opacity = (0.3 + 0.7 * (0.5 + 0.5 * math.sin(t * 2 * math.pi)));
            return Padding(
              padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.cyan,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

}
