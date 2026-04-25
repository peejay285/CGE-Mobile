import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/cge_card.dart';
import '../../../widgets/cge_empty_state.dart';

final giveawayProvider = StateProvider<Map<String, dynamic>>((ref) => {
      'prize': 'PS5 DualSense Controller',
      'description': 'Brand new wireless controller in Cosmic Red',
      'entries': 0,
      'totalEntries': 0,
      'drawDate':
          DateTime(DateTime.now().year, DateTime.now().month + 1, 0).toIso8601String(),
    });

class GiveawayScreen extends ConsumerStatefulWidget {
  const GiveawayScreen({super.key});

  @override
  ConsumerState<GiveawayScreen> createState() => _GiveawayScreenState();
}

class _GiveawayScreenState extends ConsumerState<GiveawayScreen> {
  late Timer _countdownTimer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateCountdown(),
    );
  }

  void _updateCountdown() {
    final data = ref.read(giveawayProvider);
    final drawDate = DateTime.parse(data['drawDate'] as String);
    final now = DateTime.now();
    setState(() {
      _timeRemaining = drawDate.difference(now);
      if (_timeRemaining.isNegative) {
        _timeRemaining = Duration.zero;
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    super.dispose();
  }

  String _formatCountdown() {
    final days = _timeRemaining.inDays;
    final hours = _timeRemaining.inHours % 24;
    final minutes = _timeRemaining.inMinutes % 60;
    final seconds = _timeRemaining.inSeconds % 60;
    return '${days}d ${hours.toString().padLeft(2, '0')}h '
        '${minutes.toString().padLeft(2, '0')}m '
        '${seconds.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(giveawayProvider);
    final prize = data['prize'] as String;
    final description = data['description'] as String;
    final entries = data['entries'] as int;
    final drawDate = DateTime.parse(data['drawDate'] as String);

    final monthName = _monthName(drawDate.month);

    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(
        backgroundColor: AppColors.base,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
        title: Text('Monthly Giveaway', style: AppTypography.headingSmall),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gold gradient banner
            _buildBanner(),
            const SizedBox(height: 20),

            // Prize card
            _buildPrizeCard(prize, description),
            const SizedBox(height: 24),

            // How to Enter
            Text('How to Enter', style: AppTypography.heading),
            const SizedBox(height: 12),
            _buildStep(1, 'Book a session', 'Earn 1 entry per booking',
                LucideIcons.calendar),
            const SizedBox(height: 10),
            _buildStep(2, 'Complete a swap', 'Earn 2 entries per successful swap',
                LucideIcons.repeat2),
            const SizedBox(height: 10),
            _buildStep(3, 'Win a tournament', 'Earn 5 entries',
                LucideIcons.trophy),
            const SizedBox(height: 24),

            // Your entries
            Text('Your Entries', style: AppTypography.heading),
            const SizedBox(height: 12),
            _buildEntriesCard(entries),
            const SizedBox(height: 24),

            // Entry history
            Text('Entry History', style: AppTypography.heading),
            const SizedBox(height: 12),
            const CgeEmptyState(
              icon: '\u{1F4DC}',
              title: 'No entries yet',
              subtitle: 'Book sessions, complete swaps, or win tournaments to earn entries!',
            ),
            const SizedBox(height: 24),

            // Draw date footer
            Center(
              child: Text(
                'Draw Date: Last day of $monthName',
                style: AppTypography.bodySmall.copyWith(color: AppColors.gold),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.3),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '\u{1F3C6}',
            style: TextStyle(fontSize: 40),
          ),
          const SizedBox(height: 8),
          Text(
            'Win Big This Month!',
            style: AppTypography.heading.copyWith(color: AppColors.base),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.base.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatCountdown(),
              style: AppTypography.monoLarge.copyWith(
                color: AppColors.base,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrizeCard(String prize, String description) {
    return CgeCard(
      showGlow: true,
      glowColor: AppColors.gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PRIZE', style: AppTypography.labelSmall.copyWith(color: AppColors.gold)),
          const SizedBox(height: 8),
          Text(prize, style: AppTypography.subheadingLarge),
          const SizedBox(height: 4),
          Text(
            description,
            style: AppTypography.body.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          // Prize image placeholder
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.image, size: 40, color: AppColors.gold.withValues(alpha: 0.5)),
                const SizedBox(height: 8),
                Text(
                  'Prize Image',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.gold.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String title, String subtitle, IconData icon) {
    return CgeCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '$number',
                style: AppTypography.monoLarge.copyWith(
                  color: AppColors.gold,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.subheading),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.bodySmall),
              ],
            ),
          ),
          Icon(icon, size: 20, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _buildEntriesCard(int entries) {
    return CgeCard(
      child: Center(
        child: Column(
          children: [
            Text(
              '$entries',
              style: AppTypography.monoLarge.copyWith(
                fontSize: 48,
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$entries entries this month',
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month - 1];
  }
}
