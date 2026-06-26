import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/pricing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/tournament_access.dart';
import '../../../data/models/profile.dart';
import '../../../data/models/tournament.dart';
import '../../../data/models/tournament_payout.dart';
import '../../../providers/tournament_provider.dart';
import '../../../widgets/cge_badge.dart';
import '../../../widgets/cge_button.dart';
import '../../../widgets/cge_card.dart';
import '../../../widgets/cge_empty_state.dart';

class TournamentPayoutsTab extends ConsumerStatefulWidget {
  final Tournament tournament;
  final Profile? profile;

  const TournamentPayoutsTab({
    super.key,
    required this.tournament,
    this.profile,
  });

  @override
  ConsumerState<TournamentPayoutsTab> createState() =>
      _TournamentPayoutsTabState();
}

class _TournamentPayoutsTabState extends ConsumerState<TournamentPayoutsTab> {
  bool _busy = false;

  bool get _isManager => canManageTournament(widget.tournament, widget.profile);

  void _refresh() {
    ref.invalidate(tournamentPayoutDataProvider(widget.tournament));
    ref.invalidate(tournamentDetailProvider(widget.tournament.id));
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(success)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Payout action failed: $error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(tournamentPayoutDataProvider(widget.tournament));
    return data.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => CgeEmptyState(
        icon: '!',
        title: 'Payout information unavailable',
        subtitle: '$error',
        actionLabel: 'Retry',
        onAction: _refresh,
      ),
      data: (value) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PayoutAccountCard(profile: widget.profile),
          const SizedBox(height: 16),
          if (_isManager) ...[
            _ManagerPayoutControls(
              tournament: widget.tournament,
              data: value,
              busy: _busy,
              onPlacement: (place, userId) => _run(
                () => ref
                    .read(tournamentRepositoryProvider)
                    .setPrizePlacement(
                      tournamentId: widget.tournament.id,
                      placement: place,
                      userId: userId,
                    ),
                'Prize placement updated',
              ),
              onPrepare: () => _run(() async {
                await ref
                    .read(tournamentRepositoryProvider)
                    .preparePayouts(widget.tournament.id);
              }, 'Payout draft generated'),
              onApprove: () => _run(() async {
                await ref
                    .read(tournamentRepositoryProvider)
                    .approvePayouts(widget.tournament.id);
              }, 'Payouts approved for release'),
            ),
            const SizedBox(height: 18),
          ],
          Text('Prize Ledger', style: AppTypography.headingSmall),
          const SizedBox(height: 10),
          if (value.payouts.isEmpty)
            const CgeEmptyState(
              icon: '₦',
              title: 'No payout rows yet',
              subtitle:
                  'Payouts appear after the tournament is complete and placements are assigned.',
            )
          else
            ...value.payouts.map(
              (payout) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PayoutCard(
                  payout: payout,
                  canRelease:
                      widget.profile?.isAdmin == true &&
                      ['approved', 'failed'].contains(payout.status),
                  busy: _busy,
                  onRelease: () => _run(() async {
                    await ref
                        .read(tournamentRepositoryProvider)
                        .releasePayout(payout.id);
                  }, 'Payout release submitted'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PayoutAccountCard extends StatelessWidget {
  final Profile? profile;

  const _PayoutAccountCard({this.profile});

  @override
  Widget build(BuildContext context) {
    final ready = profile?.payoutProfileVerifiedAt != null;
    return CgeCard(
      showGlow: true,
      glowColor: ready ? AppColors.green : AppColors.gold,
      child: Row(
        children: [
          Icon(
            ready ? LucideIcons.badgeCheck : LucideIcons.landmark,
            color: ready ? AppColors.green : AppColors.gold,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ready ? 'Payout account ready' : 'Set up prize payouts',
                  style: AppTypography.label,
                ),
                Text(
                  ready
                      ? '${profile?.payoutBankName ?? 'Bank'} •••• ${profile?.payoutAccountLast4 ?? ''}'
                      : 'Winners need a verified bank recipient before CGE can release prize money.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push('/profile/payout'),
            icon: const Icon(LucideIcons.chevronRight, size: 18),
          ),
        ],
      ),
    );
  }
}

class _ManagerPayoutControls extends StatelessWidget {
  final Tournament tournament;
  final TournamentPayoutData data;
  final bool busy;
  final Future<void> Function(int place, String userId) onPlacement;
  final Future<void> Function() onPrepare;
  final Future<void> Function() onApprove;

  const _ManagerPayoutControls({
    required this.tournament,
    required this.data,
    required this.busy,
    required this.onPlacement,
    required this.onPrepare,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    final paid = data.registrants
        .where((row) => row.paymentStatus == 'paid')
        .toList();
    final distribution = tournament.payoutDistribution.isEmpty
        ? const [
            {'place': 1, 'label': '1st Place', 'percent': 60},
            {'place': 2, 'label': '2nd Place', 'percent': 25},
            {'place': 3, 'label': '3rd Place', 'percent': 15},
          ]
        : tournament.payoutDistribution;
    final placementMap = {
      for (final placement in data.placements)
        placement.placement: placement.userId,
    };
    final canPrepare =
        tournament.status == 'completed' &&
        !data.payouts.any(
          (row) => ['approved', 'processing', 'paid'].contains(row.status),
        );
    final canApprove =
        data.payouts.isNotEmpty &&
        data.payouts.every((row) => row.status == 'pending_review');

    return CgeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Host Payout Controls', style: AppTypography.headingSmall),
          const SizedBox(height: 4),
          if (tournament.isTeamTournament) ...[
            Text(
              'Team prize automation currently pays verified individual winners. Assign the captain or agreed recipient for each place.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.gold),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            'Pool: ${Pricing.formatPrice(tournament.prizePoolTotal)} • ${tournament.payoutStatus.replaceAll('_', ' ')}',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          ...distribution.map((item) {
            final place = (item['place'] as num?)?.toInt() ?? 0;
            final label = item['label'] as String? ?? 'Place $place';
            final percent = (item['percent'] as num?)?.toDouble() ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DropdownButtonFormField<String>(
                initialValue: placementMap[place],
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: '$label • ${percent.toStringAsFixed(0)}%',
                ),
                items: paid
                    .map(
                      (registrant) => DropdownMenuItem(
                        value: registrant.userId,
                        child: Text(
                          registrant.profile?.gamertag ??
                              registrant.profile?.fullName ??
                              registrant.userId,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: busy
                    ? null
                    : (userId) {
                        if (userId != null) onPlacement(place, userId);
                      },
              ),
            );
          }),
          Row(
            children: [
              Expanded(
                child: CgeButton(
                  label: 'Generate Draft',
                  variant: CgeButtonVariant.secondary,
                  isLoading: busy,
                  onPressed: canPrepare ? onPrepare : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CgeButton(
                  label: 'Approve',
                  isLoading: busy,
                  onPressed: canApprove ? onApprove : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PayoutCard extends StatelessWidget {
  final TournamentPayout payout;
  final bool canRelease;
  final bool busy;
  final Future<void> Function() onRelease;

  const _PayoutCard({
    required this.payout,
    required this.canRelease,
    required this.busy,
    required this.onRelease,
  });

  @override
  Widget build(BuildContext context) {
    return CgeCard(
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.surfaceAlt,
                child: Text('${payout.placement}'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payout.profile?.gamertag ??
                          payout.profile?.fullName ??
                          'Winner',
                      style: AppTypography.label,
                    ),
                    Text(
                      '${payout.percentage.toStringAsFixed(0)}% • net after ${Pricing.formatPrice(payout.platformFeeAmount)} fee',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Pricing.formatPrice(payout.netAmount),
                    style: AppTypography.mono.copyWith(color: AppColors.gold),
                  ),
                  CgeBadge(
                    label: payout.status,
                    color: payout.status == 'paid'
                        ? BadgeColor.green
                        : payout.status == 'failed'
                        ? BadgeColor.red
                        : BadgeColor.gold,
                    fontSize: 9,
                  ),
                ],
              ),
            ],
          ),
          if (canRelease) ...[
            const SizedBox(height: 12),
            CgeButton(
              label: payout.status == 'failed'
                  ? 'Retry Transfer'
                  : 'Release Prize',
              fullWidth: true,
              isLoading: busy,
              onPressed: onRelease,
              icon: LucideIcons.send,
            ),
          ],
        ],
      ),
    );
  }
}
