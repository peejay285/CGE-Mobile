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
import '../../../widgets/cge_visual_banner.dart';
import 'teams_tab.dart';

class EsportsScreen extends ConsumerStatefulWidget {
  const EsportsScreen({super.key});

  @override
  ConsumerState<EsportsScreen> createState() => _EsportsScreenState();
}

class _EsportsScreenState extends ConsumerState<EsportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _statusFilter = 'All';
  String _search = '';

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
            Text('Search Tournaments', style: AppTypography.headingSmall),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                prefixIcon: Icon(LucideIcons.search),
                hintText: 'Search title, game, platform or format',
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Esports'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.search, size: 20),
            onPressed: _showSearchSheet,
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _TournamentsList(
            statusFilter: _statusFilter,
            providerStatus: _providerStatus,
            search: _search,
            onClearSearch: () => setState(() => _search = ''),
            onFilterChange: (f) => setState(() => _statusFilter = f),
            statusFilters: _statusFilters,
          ),
          const _LeaderboardTab(),
          const TeamsTab(),
        ],
      ),
    );
  }
}

// ─── Tournaments List ─────────────────────────────────

class _TournamentsList extends ConsumerStatefulWidget {
  final String statusFilter;
  final String? providerStatus;
  final String search;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onFilterChange;
  final List<String> statusFilters;

  const _TournamentsList({
    required this.statusFilter,
    required this.providerStatus,
    required this.search,
    required this.onClearSearch,
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
    final colors = AppColors.of(context);
    final tournamentsAsync = ref.watch(
      tournamentsProvider(widget.providerStatus),
    );
    final searchTerm = widget.search.trim().toLowerCase();

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: CgeVisualBanner(
            imageAsset: 'assets/images/fc-25.jpg',
            eyebrow: 'CGE Esports',
            title: 'Compete for more than bragging rights.',
            subtitle: 'Join tournaments, build your team and climb the table.',
            height: 168,
          ),
        ),
        // Stats bar — derived from live data when available
        tournamentsAsync.when(
          data: (tournaments) => _StatsBar(tournaments: tournaments),
          loading: () => const _StatsBarSkeleton(),
          error: (_, _) => const _StatsBarSkeleton(),
        ),

        // Status filter chips
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: widget.statusFilters
                .map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: widget.statusFilter == f,
                      selectedColor: AppColors.cyan.withValues(alpha: 0.2),
                      onSelected: (_) => widget.onFilterChange(f),
                      side: BorderSide(
                        color: widget.statusFilter == f
                            ? AppColors.cyan
                            : colors.border,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),

        const SizedBox(height: 12),

        if (searchTerm.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: CgeBadge(
                    label: 'Search: ${widget.search.trim()}',
                    color: BadgeColor.cyan,
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 16),
                  onPressed: widget.onClearSearch,
                ),
              ],
            ),
          ),

        // Tournament cards
        Expanded(
          child: tournamentsAsync.when(
            data: (tournaments) {
              final statusVisible = widget.statusFilter == 'Open'
                  ? tournaments.where((t) => t.isOpen).toList()
                  : tournaments;
              final visible = searchTerm.isEmpty
                  ? statusVisible
                  : statusVisible
                        .where(
                          (t) => [t.title, t.game, t.platform, t.format].any(
                            (value) => value.toLowerCase().contains(searchTerm),
                          ),
                        )
                        .toList();
              return RefreshIndicator(
                onRefresh: _refresh,
                color: AppColors.cyan,
                child: visible.isEmpty
                    ? const _EmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: visible.length,
                        itemBuilder: (context, i) =>
                            _TournamentCard(tournament: visible[i]),
                      ),
              );
            },
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
    final openCount = tournaments.where((t) => t.isOpen).length.toString();
    final totalPrize = tournaments.fold<int>(0, (sum, t) => sum + t.prize);
    final totalCount = tournaments.length.toString();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _StatChip(label: 'Open', value: openCount, color: AppColors.cyan),
          const SizedBox(width: 12),
          _StatChip(
            label: 'Prize Pool',
            value: Pricing.formatPrice(totalPrize),
            color: AppColors.gold,
          ),
          const SizedBox(width: 12),
          _StatChip(
            label: 'Total',
            value: totalCount,
            color: AppColors.magenta,
          ),
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
      itemBuilder: (_, _) => const Padding(
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
    final colors = AppColors.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Icon(LucideIcons.trophy, size: 48, color: colors.textSecondary),
              const SizedBox(height: 16),
              Text('No tournaments found', style: AppTypography.headingSmall),
              const SizedBox(height: 8),
              Text(
                'Check back soon for upcoming events',
                style: AppTypography.body.copyWith(color: colors.textSecondary),
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
    final colors = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.wifiOff, size: 48, color: colors.textSecondary),
          const SizedBox(height: 16),
          Text('Failed to load tournaments', style: AppTypography.headingSmall),
          const SizedBox(height: 8),
          Text(
            'Check your connection and try again',
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 24),
          CgeButton(label: 'Retry', onPressed: onRetry, size: CgeButtonSize.sm),
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
    if (tournament.isRegistrationExpired) return BadgeColor.red;
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
    if (tournament.isRegistrationExpired) return 'Closed';
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
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: () => context.push('/esports/${tournament.id}'),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: CgeCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: Stack(
                  children: [
                    Image.asset(
                      cgeGameArtwork(tournament.game),
                      width: double.infinity,
                      height: 132,
                      fit: BoxFit.cover,
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              colors.surface.withValues(alpha: 0.95),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: CgeBadge(
                        label: _statusLabel,
                        color: _statusColor,
                        fontSize: 10,
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 12,
                      child: Text(
                        tournament.title,
                        style: AppTypography.subheadingLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          icon: LucideIcons.gamepad2,
                          label: tournament.game,
                        ),
                        _InfoChip(
                          icon: LucideIcons.monitor,
                          label: tournament.platform,
                        ),
                        _InfoChip(
                          icon: LucideIcons.layoutGrid,
                          label: tournament.format,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.trophy,
                          size: 15,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          Pricing.formatPrice(tournament.prize),
                          style: AppTypography.mono.copyWith(
                            color: AppColors.gold,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          LucideIcons.users,
                          size: 14,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${tournament.filled}/${tournament.slots} players',
                          style: AppTypography.labelSmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (tournament.isOpen) ...[
                      const SizedBox(height: 14),
                      CgeButton(
                        label: tournament.entryFee > 0
                            ? 'View & register'
                            : 'Join tournament',
                        onPressed: () =>
                            context.push('/esports/${tournament.id}'),
                        fullWidth: true,
                        size: CgeButtonSize.sm,
                      ),
                    ],
                  ],
                ),
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
    final colors = AppColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: colors.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.labelSmall.copyWith(fontSize: 11)),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

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
            Text(
              value,
              style: AppTypography.mono.copyWith(color: color, fontSize: 16),
            ),
            Text(label, style: AppTypography.labelSmall.copyWith(fontSize: 10)),
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
    final colors = AppColors.of(context);
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return leaderboardAsync.when(
      data: (players) => players.isEmpty
          ? Center(
              child: Text(
                'No leaderboard data yet',
                style: AppTypography.body.copyWith(color: colors.textSecondary),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: players.length,
              itemBuilder: (context, i) {
                final player = players[i];
                final gamertag = (player['gamertag'] as String?) ?? 'Unknown';
                final points = (player['points'] as num?)?.toInt() ?? 0;
                final wins = (player['wins'] as num?)?.toInt() ?? 0;
                final losses = (player['losses'] as num?)?.toInt() ?? 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: i == 0
                        ? AppColors.gold.withValues(alpha: 0.08)
                        : colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: i == 0
                          ? AppColors.gold.withValues(alpha: 0.3)
                          : colors.border,
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
                                ? colors.textPrimary
                                : colors.textSecondary,
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
      error: (_, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.wifiOff, size: 40, color: colors.textSecondary),
            const SizedBox(height: 12),
            Text(
              'Failed to load leaderboard',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
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
