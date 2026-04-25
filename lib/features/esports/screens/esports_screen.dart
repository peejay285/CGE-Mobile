import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/pricing.dart';
import '../../../data/models/tournament.dart';
import '../../../providers/tournament_provider.dart';
import '../../../widgets/cge_card.dart';
import '../../../widgets/cge_badge.dart';
import '../../../widgets/cge_avatar.dart';
import '../../../widgets/cge_button.dart';
import '../../../widgets/cge_skeleton.dart';

class EsportsScreen extends ConsumerStatefulWidget {
  const EsportsScreen({super.key});

  @override
  ConsumerState<EsportsScreen> createState() => _EsportsScreenState();
}

class _EsportsScreenState extends ConsumerState<EsportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _statusFilter = 'All';

  static const _statusFilters = ['All', 'Open', 'Live', 'Completed'];

  /// Maps display filter label to the status string the provider expects.
  String? get _providerStatus {
    switch (_statusFilter) {
      case 'Open':
        return 'open';
      case 'Live':
        return 'in_progress';
      case 'Completed':
        return 'completed';
      default:
        return null; // 'All' → no filter
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Esports'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.search, size: 20),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tournaments'),
            Tab(text: 'Leaderboard'),
            Tab(text: 'Teams'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.cyan,
        child: const Icon(LucideIcons.plus, color: AppColors.base),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TournamentsList(
            statusFilter: _statusFilter,
            providerStatus: _providerStatus,
            onFilterChange: (f) => setState(() => _statusFilter = f),
            statusFilters: _statusFilters,
          ),
          const _LeaderboardTab(),
          const _TeamsTab(),
        ],
      ),
    );
  }
}

// ─── Tournaments List ─────────────────────────────────

class _TournamentsList extends ConsumerStatefulWidget {
  final String statusFilter;
  final String? providerStatus;
  final ValueChanged<String> onFilterChange;
  final List<String> statusFilters;

  const _TournamentsList({
    required this.statusFilter,
    required this.providerStatus,
    required this.onFilterChange,
    required this.statusFilters,
  });

  @override
  ConsumerState<_TournamentsList> createState() => _TournamentsListState();
}

class _TournamentsListState extends ConsumerState<_TournamentsList> {
  Future<void> _refresh() async {
    ref.invalidate(tournamentsProvider(widget.providerStatus));
  }

  @override
  Widget build(BuildContext context) {
    final tournamentsAsync =
        ref.watch(tournamentsProvider(widget.providerStatus));

    return Column(
      children: [
        // Stats bar — derived from live data when available
        tournamentsAsync.when(
          data: (tournaments) => _StatsBar(tournaments: tournaments),
          loading: () => const _StatsBarSkeleton(),
          error: (_, __) => const _StatsBarSkeleton(),
        ),

        // Status filter chips
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: widget.statusFilters
                .map((f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f),
                        selected: widget.statusFilter == f,
                        selectedColor: AppColors.cyan.withValues(alpha: 0.2),
                        onSelected: (_) => widget.onFilterChange(f),
                        side: BorderSide(
                          color: widget.statusFilter == f
                              ? AppColors.cyan
                              : AppColors.border,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),

        const SizedBox(height: 12),

        // Tournament cards
        Expanded(
          child: tournamentsAsync.when(
            data: (tournaments) => RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.cyan,
              child: tournaments.isEmpty
                  ? const _EmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: tournaments.length,
                      itemBuilder: (context, i) =>
                          _TournamentCard(tournament: tournaments[i]),
                    ),
            ),
            loading: () => const _TournamentsLoadingSkeleton(),
            error: (error, _) => _ErrorState(onRetry: _refresh),
          ),
        ),
      ],
    );
  }
}

// ─── Stats Bar ────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  final List<Tournament> tournaments;

  const _StatsBar({required this.tournaments});

  @override
  Widget build(BuildContext context) {
    final openCount =
        tournaments.where((t) => t.status == 'open').length.toString();
    final totalPrize = tournaments.fold<int>(0, (sum, t) => sum + t.prize);
    final totalCount = tournaments.length.toString();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _StatChip(
              label: 'Open', value: openCount, color: AppColors.cyan),
          const SizedBox(width: 12),
          _StatChip(
              label: 'Prize Pool',
              value: Pricing.formatPrice(totalPrize),
              color: AppColors.gold),
          const SizedBox(width: 12),
          _StatChip(
              label: 'Total', value: totalCount, color: AppColors.magenta),
        ],
      ),
    );
  }
}

class _StatsBarSkeleton extends StatelessWidget {
  const _StatsBarSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Row(
        children: [
          Expanded(child: CgeSkeleton(height: 58, borderRadius: 12)),
          SizedBox(width: 12),
          Expanded(child: CgeSkeleton(height: 58, borderRadius: 12)),
          SizedBox(width: 12),
          Expanded(child: CgeSkeleton(height: 58, borderRadius: 12)),
        ],
      ),
    );
  }
}

// ─── Loading & Error States ───────────────────────────

class _TournamentsLoadingSkeleton extends StatelessWidget {
  const _TournamentsLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 4,
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: CgeSkeleton.card(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              const Icon(LucideIcons.trophy,
                  size: 48, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text('No tournaments found',
                  style: AppTypography.headingSmall),
              const SizedBox(height: 8),
              Text(
                'Check back soon for upcoming events',
                style:
                    AppTypography.body.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.wifiOff, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text('Failed to load tournaments',
              style: AppTypography.headingSmall),
          const SizedBox(height: 8),
          Text(
            'Check your connection and try again',
            style: AppTypography.body.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          CgeButton(
            label: 'Retry',
            onPressed: onRetry,
            size: CgeButtonSize.sm,
          ),
        ],
      ),
    );
  }
}

// ─── Tournament Card ──────────────────────────────────

class _TournamentCard extends StatelessWidget {
  final Tournament tournament;

  const _TournamentCard({required this.tournament});

  BadgeColor get _statusColor {
    switch (tournament.status) {
      case 'open':
        return BadgeColor.cyan;
      case 'in_progress':
        return BadgeColor.green;
      case 'completed':
        return BadgeColor.gold;
      default:
        return BadgeColor.cyan;
    }
  }

  String get _statusLabel {
    switch (tournament.status) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'Live';
      case 'completed':
        return 'Completed';
      default:
        return tournament.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/esports/${tournament.id}'),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: CgeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(tournament.title,
                        style: AppTypography.subheading,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  CgeBadge(
                      label: _statusLabel,
                      color: _statusColor,
                      fontSize: 10),
                ],
              ),
              const SizedBox(height: 8),

              // Info row
              Row(
                children: [
                  _InfoChip(
                      icon: LucideIcons.gamepad2, label: tournament.game),
                  const SizedBox(width: 12),
                  _InfoChip(
                      icon: LucideIcons.monitor, label: tournament.platform),
                  const SizedBox(width: 12),
                  _InfoChip(
                      icon: LucideIcons.layoutGrid, label: tournament.format),
                ],
              ),
              const SizedBox(height: 12),

              // Bottom row
              Row(
                children: [
                  // Prize
                  Icon(LucideIcons.trophy, size: 14, color: AppColors.gold),
                  const SizedBox(width: 4),
                  Text(
                    Pricing.formatPrice(tournament.prize),
                    style: AppTypography.mono
                        .copyWith(color: AppColors.gold, fontSize: 13),
                  ),
                  const SizedBox(width: 16),
                  // Entry fee
                  if (tournament.entryFee > 0) ...[
                    Icon(LucideIcons.ticket,
                        size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      Pricing.formatPrice(tournament.entryFee),
                      style: AppTypography.labelSmall,
                    ),
                  ] else ...[
                    const CgeBadge(
                        label: 'FREE', color: BadgeColor.green, fontSize: 10),
                  ],
                  const Spacer(),
                  // Slots
                  Icon(LucideIcons.users, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${tournament.filled}/${tournament.slots}',
                    style: AppTypography.labelSmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Action
              if (tournament.isOpen)
                CgeButton(
                  label: tournament.entryFee > 0 ? 'Pay & Register' : 'Register',
                  onPressed: () {},
                  fullWidth: true,
                  size: CgeButtonSize.sm,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(label,
            style: AppTypography.labelSmall.copyWith(fontSize: 11)),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style:
                    AppTypography.mono.copyWith(color: color, fontSize: 16)),
            Text(label,
                style:
                    AppTypography.labelSmall.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ─── Leaderboard Tab ──────────────────────────────────

class _LeaderboardTab extends ConsumerWidget {
  const _LeaderboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return leaderboardAsync.when(
      data: (players) => players.isEmpty
          ? Center(
              child: Text('No leaderboard data yet',
                  style: AppTypography.body
                      .copyWith(color: AppColors.textMuted)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: players.length,
              itemBuilder: (context, i) {
                final player = players[i];
                final gamertag =
                    (player['gamertag'] as String?) ?? 'Unknown';
                final points = (player['points'] as num?)?.toInt() ?? 0;
                final wins = (player['wins'] as num?)?.toInt() ?? 0;
                final losses = (player['losses'] as num?)?.toInt() ?? 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: i == 0
                        ? AppColors.gold.withValues(alpha: 0.08)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: i == 0
                          ? AppColors.gold.withValues(alpha: 0.3)
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          '#${i + 1}',
                          style: AppTypography.mono.copyWith(
                            color: i == 0
                                ? AppColors.gold
                                : i == 1
                                    ? AppColors.text
                                    : AppColors.textMuted,
                          ),
                        ),
                      ),
                      CgeAvatar(name: gamertag, size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(gamertag, style: AppTypography.label),
                            Text(
                              '${wins}W - ${losses}L',
                              style: AppTypography.labelSmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '$points pts',
                        style: AppTypography.mono.copyWith(
                          color: AppColors.cyan,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: CgeSkeleton(height: 60, borderRadius: 12),
        ),
      ),
      error: (_, __) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.wifiOff,
                size: 40, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text('Failed to load leaderboard',
                style: AppTypography.body
                    .copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            CgeButton(
              label: 'Retry',
              onPressed: () => ref.invalidate(leaderboardProvider),
              size: CgeButtonSize.sm,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Teams Tab ────────────────────────────────────────

class _TeamsTab extends StatelessWidget {
  const _TeamsTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.swords, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text('Teams coming soon', style: AppTypography.headingSmall),
          const SizedBox(height: 8),
          Text(
            'Create or join a team to compete together',
            style: AppTypography.body.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          CgeButton(label: 'Create Team', onPressed: () {}),
        ],
      ),
    );
  }
}
