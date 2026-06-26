import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/pricing.dart';
import '../../../core/services/payment_service.dart';
import '../../../data/models/team.dart';
import '../../../data/models/tournament.dart';
import '../../../data/models/profile.dart';
import '../../../data/models/tournament_payout.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/team_provider.dart';
import '../../../providers/tournament_provider.dart';
import '../../../widgets/cge_button.dart';
import '../../../widgets/cge_badge.dart';
import '../../../widgets/cge_card.dart';
import '../../../widgets/cge_avatar.dart';
import '../../../widgets/cge_skeleton.dart';
import '../../../widgets/cge_empty_state.dart';
import 'tournament_bracket_tab.dart';
import 'tournament_payouts_tab.dart';

class TournamentDetailScreen extends ConsumerStatefulWidget {
  final String tournamentId;

  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<TournamentDetailScreen> createState() =>
      _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends ConsumerState<TournamentDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isLoading = false;

  int? get _parsedId => int.tryParse(widget.tournamentId);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  BadgeColor _statusBadgeColor(Tournament tournament) {
    if (tournament.isRegistrationExpired) return BadgeColor.red;
    switch (tournament.status) {
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

  String _statusLabel(Tournament tournament) {
    if (tournament.isRegistrationExpired) return 'CLOSED';
    return tournament.status.toUpperCase();
  }

  String _registrationLabel(Tournament tournament) {
    if (tournament.isRegistrationExpired) return 'Registration closed';
    if (tournament.filled >= tournament.slots) return 'Tournament full';
    if (!tournament.isOpen) return 'Registration unavailable';
    if (tournament.isFree) {
      return tournament.isTeamTournament
          ? 'Register Team — Free'
          : 'Register — Free';
    }
    return tournament.isTeamTournament
        ? 'Register Team — ${Pricing.formatPrice(tournament.entryFee)}'
        : 'Register — ${Pricing.formatPrice(tournament.entryFee)}';
  }

  Future<void> _register(Tournament tournament) async {
    if (_isLoading) return;
    if (!tournament.isOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration is closed for this tournament.'),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);

    try {
      String? checkoutUrl;
      if (tournament.isTeamTournament) {
        final team = await ref.read(myTeamProvider.future);
        if (team == null) {
          throw Exception('Create or join a team before registering');
        }
        final members = await ref
            .read(teamRepositoryProvider)
            .getMembers(team.id);
        final requiredSize = tournament.teamSize ?? 1;
        if (members.length < requiredSize) {
          throw Exception(
            'Your team needs $requiredSize members; it currently has ${members.length}',
          );
        }
        final registration = await ref
            .read(tournamentRepositoryProvider)
            .registerTeam(tournamentId: tournament.id, teamId: team.id);
        if (registration.total > 0 &&
            registration.paymentStatus != 'paid' &&
            registration.paymentStatus != 'free') {
          checkoutUrl = await PaymentService.initializeRecordPayment(
            type: 'tournament_team',
            recordId: registration.id,
            metadata: {
              'registration_id': registration.id,
              'team_registration_id': registration.id,
              'tournament_id': tournament.id,
            },
          );
        }
        ref.invalidate(myTeamTournamentRegistrationProvider(tournament.id));
      } else {
        final registration = await ref
            .read(tournamentRepositoryProvider)
            .register(tournament.id);
        if (registration.total > 0 &&
            registration.paymentStatus != 'paid' &&
            registration.paymentStatus != 'free') {
          checkoutUrl = await PaymentService.initializeRecordPayment(
            type: 'tournament',
            recordId: registration.id,
            metadata: {
              'registration_id': registration.id,
              'tournament_id': tournament.id,
            },
          );
        }
        ref.invalidate(myTournamentRegistrationProvider(tournament.id));
      }
      if (checkoutUrl != null) {
        await PaymentService.openCheckout(checkoutUrl);
      }
      if (mounted) {
        setState(() => _isLoading = false);
        // Refresh tournament data to reflect updated filled count
        ref.invalidate(tournamentDetailProvider(_parsedId!));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              checkoutUrl == null
                  ? 'Registered successfully!'
                  : 'Paystack checkout opened. Registration confirms after payment.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Registration failed: $e')));
      }
    }
  }

  Future<void> _checkIn(Tournament tournament, Team? team) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      if (tournament.isTeamTournament) {
        if (team == null) throw Exception('Team not found');
        await ref
            .read(tournamentRepositoryProvider)
            .checkInTeam(tournament.id, team.id);
        ref.invalidate(myTeamTournamentRegistrationProvider(tournament.id));
      } else {
        await ref.read(tournamentRepositoryProvider).checkIn(tournament.id);
        ref.invalidate(myTournamentRegistrationProvider(tournament.id));
      }
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Checked in! Good luck!')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Check-in failed: $e')));
      }
    }
  }

  Future<void> _shareTournament(Tournament tournament) async {
    await Share.share(
      'Join me in ${tournament.title} on CGE.\n'
      'Game: ${tournament.game}\n'
      'Prize pool: ${Pricing.formatPrice(tournament.prize)}\n'
      'https://cgelounge.com/esports/${tournament.id}',
    );
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
    final soloRegistration = ref
        .watch(myTournamentRegistrationProvider(id))
        .valueOrNull;
    final teamRegistration = ref
        .watch(myTeamTournamentRegistrationProvider(id))
        .valueOrNull;
    final myTeam = ref.watch(myTeamProvider).valueOrNull;
    final profile = ref.watch(currentProfileProvider).valueOrNull;

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

        return _buildContent(
          tournament,
          soloRegistration: soloRegistration,
          teamRegistration: teamRegistration,
          myTeam: myTeam,
          profile: profile,
        );
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

  Widget _buildContent(
    Tournament tournament, {
    TournamentRegistration? soloRegistration,
    TournamentTeamRegistration? teamRegistration,
    Team? myTeam,
    Profile? profile,
  }) {
    final slotsRemaining = tournament.slots - tournament.filled;
    final isRegistered = tournament.isTeamTournament
        ? teamRegistration != null
        : soloRegistration != null;
    final isCheckedIn = tournament.isTeamTournament
        ? teamRegistration?.checkedIn == true
        : soloRegistration?.checkedIn == true;

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
            onPressed: () => _shareTournament(tournament),
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
                      child: Text(
                        tournament.title,
                        style: AppTypography.heading,
                      ),
                    ),
                    CgeBadge(
                      label: _statusLabel(tournament),
                      color: _statusBadgeColor(tournament),
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
                      icon: LucideIcons.gamepad2,
                      label: tournament.game,
                    ),
                    _InfoChip(
                      icon: LucideIcons.swords,
                      label: tournament.format,
                    ),
                    _InfoChip(
                      icon: LucideIcons.monitor,
                      label: tournament.platform,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Date, time row
                Row(
                  children: [
                    Icon(
                      LucideIcons.calendar,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(tournament.date, style: AppTypography.labelSmall),
                    const SizedBox(width: 16),
                    Icon(
                      LucideIcons.clock,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
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
                    Icon(
                      LucideIcons.users,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${tournament.filled}/${tournament.slots} registered',
                      style: AppTypography.labelSmall,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '($slotsRemaining spots left)',
                      style: AppTypography.labelSmall.copyWith(
                        color: slotsRemaining <= 5
                            ? AppColors.red
                            : AppColors.green,
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
                if (tournament.isRegistrationExpired) ...[
                  const SizedBox(height: 12),
                  CgeCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          LucideIcons.calendarX,
                          color: AppColors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This tournament date has passed, so registration is closed. Check the esports list for active tournaments.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
              Tab(text: 'Payouts'),
            ],
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _DetailsTab(tournament: tournament),
                TournamentBracketTab(
                  tournament: tournament,
                  profile: profile,
                  myTeam: myTeam,
                ),
                _PlayersTab(tournament: tournament),
                TournamentPayoutsTab(tournament: tournament, profile: profile),
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
            : isRegistered
            ? isCheckedIn
                  ? CgeButton(
                      label: 'Checked In',
                      onPressed: null,
                      fullWidth: true,
                      variant: CgeButtonVariant.secondary,
                      icon: LucideIcons.checkCircle,
                    )
                  : CgeButton(
                      label: 'Check In',
                      onPressed: () => _checkIn(tournament, myTeam),
                      fullWidth: true,
                      variant: CgeButtonVariant.magenta,
                      icon: LucideIcons.logIn,
                    )
            : CgeButton(
                label: _registrationLabel(tournament),
                onPressed: tournament.isOpen
                    ? () => _register(tournament)
                    : null,
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
    final colors = AppColors.of(context);
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
                  Text(
                    'CGE',
                    style: AppTypography.subheading.copyWith(fontSize: 14),
                  ),
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
                      Text(
                        'Live Stream',
                        style: AppTypography.label.copyWith(fontSize: 12),
                      ),
                      Text(
                        tournament.streamUrl!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.cyan,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.externalLink,
                  size: 16,
                  color: AppColors.textMuted,
                ),
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
            (tournament.description == null || tournament.description!.isEmpty))
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: CgeCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.info, size: 20, color: AppColors.cyan),
                      const SizedBox(width: 10),
                      Text(
                        'What to know before registering',
                        style: AppTypography.subheading.copyWith(fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DetailTrustPoint(
                    text:
                        'Confirm your availability for the date and time above before paying.',
                    color: colors.textSecondary,
                  ),
                  _DetailTrustPoint(
                    text:
                        'Match results can be confirmed or disputed inside CGE.',
                    color: colors.textSecondary,
                  ),
                  _DetailTrustPoint(
                    text:
                        'Prize payouts require a verified payout account on the winner profile.',
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _DetailTrustPoint extends StatelessWidget {
  final String text;
  final Color color;

  const _DetailTrustPoint({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(
              LucideIcons.checkCircle2,
              size: 15,
              color: AppColors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: color,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Players Tab ────────────────────────────────────

class _PlayersTab extends ConsumerWidget {
  final Tournament tournament;

  const _PlayersTab({required this.tournament});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registrants = ref.watch(tournamentRegistrantsProvider(tournament));
    return registrants.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => CgeEmptyState(
        icon: '!',
        title: 'Could not load players',
        subtitle: '$error',
        actionLabel: 'Retry',
        onAction: () =>
            ref.invalidate(tournamentRegistrantsProvider(tournament)),
      ),
      data: (items) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${items.length} Registered / ${tournament.slots} Slots',
            style: AppTypography.label.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Center(
                child: Text(
                  'No players registered yet.',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            )
          else
            ...items.map(
              (registrant) => _RegistrantCard(registrant: registrant),
            ),
        ],
      ),
    );
  }
}

class _RegistrantCard extends StatelessWidget {
  final TournamentRegistrant registrant;

  const _RegistrantCard({required this.registrant});

  @override
  Widget build(BuildContext context) {
    final profile = registrant.profile;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CgeCard(
        child: Row(
          children: [
            CgeAvatar(
              name: profile?.fullName ?? 'Player',
              imageUrl: profile?.avatarUrl,
              size: 42,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile?.gamertag ?? profile?.fullName ?? 'Player',
                    style: AppTypography.label,
                  ),
                  Text(
                    registrant.paymentStatus.replaceAll('_', ' '),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (registrant.checkedIn)
              const CgeBadge(label: 'Checked in', color: BadgeColor.green),
          ],
        ),
      ),
    );
  }
}
