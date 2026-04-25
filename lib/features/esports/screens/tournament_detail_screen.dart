import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/pricing.dart';
import '../../../data/models/tournament.dart';
import '../../../providers/tournament_provider.dart';
import '../../../widgets/cge_button.dart';
import '../../../widgets/cge_badge.dart';
import '../../../widgets/cge_card.dart';
import '../../../widgets/cge_avatar.dart';
import '../../../widgets/cge_skeleton.dart';
import '../../../widgets/cge_empty_state.dart';

class TournamentDetailScreen extends ConsumerStatefulWidget {
  final String tournamentId;

  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<TournamentDetailScreen> createState() =>
      _TournamentDetailScreenState();
}

class _TournamentDetailScreenState
    extends ConsumerState<TournamentDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isRegistered = false;
  bool _isCheckedIn = false;
  bool _isLoading = false;

  int? get _parsedId => int.tryParse(widget.tournamentId);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  BadgeColor _statusBadgeColor(String status) {
    switch (status) {
      case 'open':
        return BadgeColor.green;
      case 'in_progress':
        return BadgeColor.magenta;
      case 'completed':
        return BadgeColor.cyan;
      default:
        return BadgeColor.cyan;
    }
  }

  Future<void> _register(Tournament tournament) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(tournamentRepositoryProvider).register(tournament.id);
      if (mounted) {
        setState(() {
          _isRegistered = true;
          _isLoading = false;
        });
        // Refresh tournament data to reflect updated filled count
        ref.invalidate(tournamentDetailProvider(_parsedId!));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registered successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e')),
        );
      }
    }
  }

  Future<void> _checkIn(Tournament tournament) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(tournamentRepositoryProvider).checkIn(tournament.id);
      if (mounted) {
        setState(() {
          _isCheckedIn = true;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checked in! Good luck!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Check-in failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = _parsedId;
    if (id == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, size: 20),
            onPressed: () => context.pop(),
          ),
          title: const Text('Tournament'),
        ),
        body: const CgeEmptyState(
          icon: '!',
          title: 'Invalid tournament ID',
          subtitle: 'Could not parse the tournament identifier.',
        ),
      );
    }

    final tournamentAsync = ref.watch(tournamentDetailProvider(id));

    return tournamentAsync.when(
      loading: () => _buildLoadingScaffold(),
      error: (err, _) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, size: 20),
            onPressed: () => context.pop(),
          ),
          title: const Text('Tournament'),
        ),
        body: CgeEmptyState(
          icon: '!',
          title: 'Failed to load tournament',
          subtitle: err.toString(),
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(tournamentDetailProvider(id)),
        ),
      ),
      data: (tournament) {
        if (tournament == null) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(LucideIcons.arrowLeft, size: 20),
                onPressed: () => context.pop(),
              ),
              title: const Text('Tournament'),
            ),
            body: const CgeEmptyState(
              icon: '!',
              title: 'Tournament not found',
              subtitle: 'This tournament may have been removed.',
            ),
          );
        }

        return _buildContent(tournament);
      },
    );
  }

  Widget _buildLoadingScaffold() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Tournament'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CgeSkeleton(height: 24, width: 250),
            const SizedBox(height: 12),
            Row(
              children: List.generate(
                3,
                (_) => const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: CgeSkeleton(height: 32, width: 90, borderRadius: 8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const CgeSkeleton(height: 14, width: 200),
            const SizedBox(height: 8),
            const CgeSkeleton(height: 14, width: 220),
            const SizedBox(height: 8),
            const CgeSkeleton(height: 14, width: 160),
            const SizedBox(height: 6),
            const CgeSkeleton(height: 4),
            const SizedBox(height: 24),
            const CgeSkeleton.card(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Tournament tournament) {
    final slotsRemaining = tournament.slots - tournament.filled;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Tournament'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share2, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Header info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child:
                          Text(tournament.title, style: AppTypography.heading),
                    ),
                    CgeBadge(
                      label: tournament.status.toUpperCase(),
                      color: _statusBadgeColor(tournament.status),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Info chips row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                        icon: LucideIcons.gamepad2, label: tournament.game),
                    _InfoChip(
                        icon: LucideIcons.swords, label: tournament.format),
                    _InfoChip(
                        icon: LucideIcons.monitor, label: tournament.platform),
                  ],
                ),
                const SizedBox(height: 12),

                // Date, time row
                Row(
                  children: [
                    Icon(LucideIcons.calendar,
                        size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(tournament.date, style: AppTypography.labelSmall),
                    const SizedBox(width: 16),
                    Icon(LucideIcons.clock,
                        size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(tournament.time, style: AppTypography.labelSmall),
                  ],
                ),
                const SizedBox(height: 8),

                // Prize + Entry fee
                Row(
                  children: [
                    Icon(LucideIcons.trophy, size: 14, color: AppColors.gold),
                    const SizedBox(width: 4),
                    Text(
                      'Prize: ${Pricing.formatPrice(tournament.prize)}',
                      style: AppTypography.mono.copyWith(
                        color: AppColors.gold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Icon(LucideIcons.ticket, size: 14, color: AppColors.cyan),
                    const SizedBox(width: 4),
                    Text(
                      tournament.isFree
                          ? 'Free Entry'
                          : 'Entry: ${Pricing.formatPrice(tournament.entryFee)}',
                      style: AppTypography.mono.copyWith(
                        color: AppColors.cyan,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Slots progress
                Row(
                  children: [
                    Icon(LucideIcons.users,
                        size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${tournament.filled}/${tournament.slots} registered',
                      style: AppTypography.labelSmall,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '($slotsRemaining spots left)',
                      style: AppTypography.labelSmall.copyWith(
                        color:
                            slotsRemaining <= 5 ? AppColors.red : AppColors.green,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: tournament.slots > 0
                        ? tournament.filled / tournament.slots
                        : 0,
                    minHeight: 4,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation(AppColors.cyan),
                  ),
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Details'),
              Tab(text: 'Bracket'),
              Tab(text: 'Players'),
            ],
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _DetailsTab(tournament: tournament),
                _BracketTab(tournament: tournament),
                _PlayersTab(tournament: tournament),
              ],
            ),
          ),
        ],
      ),

      // Bottom action bar
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: _isLoading
            ? const Center(
                child: SizedBox(
                  height: 48,
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            : _isRegistered
                ? _isCheckedIn
                    ? CgeButton(
                        label: 'Checked In',
                        onPressed: null,
                        fullWidth: true,
                        variant: CgeButtonVariant.secondary,
                        icon: LucideIcons.checkCircle,
                      )
                    : CgeButton(
                        label: 'Check In',
                        onPressed: () => _checkIn(tournament),
                        fullWidth: true,
                        variant: CgeButtonVariant.magenta,
                        icon: LucideIcons.logIn,
                      )
                : CgeButton(
                    label: tournament.isFree
                        ? 'Register — Free'
                        : 'Register — ${Pricing.formatPrice(tournament.entryFee)}',
                    onPressed:
                        tournament.isOpen ? () => _register(tournament) : null,
                    fullWidth: true,
                    icon: LucideIcons.userPlus,
                  ),
      ),
    );
  }
}

// ─── Info Chip ──────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.cyan),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.label.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}

// ─── Details Tab ────────────────────────────────────

class _DetailsTab extends StatelessWidget {
  final Tournament tournament;

  const _DetailsTab({required this.tournament});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Host card
        CgeCard(
          child: Row(
            children: [
              const CgeAvatar(name: 'CGE', size: 40),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hosted by', style: AppTypography.labelSmall),
                  Text('CGE',
                      style:
                          AppTypography.subheading.copyWith(fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Stream link
        if (tournament.streamUrl != null) ...[
          CgeCard(
            child: Row(
              children: [
                Icon(LucideIcons.tv, size: 20, color: AppColors.magenta),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Live Stream',
                          style: AppTypography.label.copyWith(fontSize: 12)),
                      Text(
                        tournament.streamUrl!,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.cyan),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(LucideIcons.externalLink,
                    size: 16, color: AppColors.textMuted),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Description
        if (tournament.description != null &&
            tournament.description!.isNotEmpty) ...[
          Text('Description', style: AppTypography.subheading),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              tournament.description!,
              style: AppTypography.body.copyWith(
                color: AppColors.textMuted,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Rules
        if (tournament.rules != null && tournament.rules!.isNotEmpty) ...[
          Text('Rules', style: AppTypography.subheading),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              tournament.rules!,
              style: AppTypography.body.copyWith(
                color: AppColors.textMuted,
                height: 1.6,
              ),
            ),
          ),
        ],

        // Show placeholder if no rules or description
        if ((tournament.rules == null || tournament.rules!.isEmpty) &&
            (tournament.description == null ||
                tournament.description!.isEmpty))
          Padding(
            padding: const EdgeInsets.only(top: 32),
            child: Center(
              child: Text(
                'No additional details provided.',
                style:
                    AppTypography.body.copyWith(color: AppColors.textMuted),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Bracket Tab ────────────────────────────────────

class _BracketTab extends StatelessWidget {
  final Tournament tournament;

  const _BracketTab({required this.tournament});

  @override
  Widget build(BuildContext context) {
    // Bracket data is not yet available from the API
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text('Bracket not available yet',
              style: AppTypography.headingSmall),
          const SizedBox(height: 8),
          Text(
            tournament.isLive
                ? 'The bracket is being generated...'
                : 'The bracket will appear once the tournament starts',
            style: AppTypography.body.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Players Tab ────────────────────────────────────

class _PlayersTab extends StatelessWidget {
  final Tournament tournament;

  const _PlayersTab({required this.tournament});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${tournament.filled} Registered / ${tournament.slots} Slots',
          style: AppTypography.label.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        // Player count info — individual registrant data requires
        // a separate query that is not yet exposed via the provider
        if (tournament.filled == 0)
          Padding(
            padding: const EdgeInsets.only(top: 32),
            child: Center(
              child: Text(
                'No players registered yet.',
                style:
                    AppTypography.body.copyWith(color: AppColors.textMuted),
              ),
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(
              tournament.filled,
              (i) => Column(
                children: [
                  CgeAvatar(name: 'Player ${i + 1}', size: 44),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 60,
                    child: Text(
                      'Player ${i + 1}',
                      style: AppTypography.labelSmall.copyWith(fontSize: 10),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
