import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/tournament_access.dart';
import '../../../data/models/profile.dart';
import '../../../data/models/team.dart';
import '../../../data/models/tournament.dart';
import '../../../data/models/tournament_match.dart';
import '../../../providers/tournament_provider.dart';
import '../../../widgets/cge_badge.dart';
import '../../../widgets/cge_button.dart';
import '../../../widgets/cge_card.dart';
import '../../../widgets/cge_empty_state.dart';

class TournamentBracketTab extends ConsumerStatefulWidget {
  final Tournament tournament;
  final Profile? profile;
  final Team? myTeam;

  const TournamentBracketTab({
    super.key,
    required this.tournament,
    this.profile,
    this.myTeam,
  });

  @override
  ConsumerState<TournamentBracketTab> createState() =>
      _TournamentBracketTabState();
}

class _TournamentBracketTabState extends ConsumerState<TournamentBracketTab> {
  bool _busy = false;

  bool get _isManager => canManageTournament(widget.tournament, widget.profile);

  bool _isParticipant(TournamentMatch match) {
    final ids = {widget.profile?.id, widget.myTeam?.id.toString()};
    return ids.contains(match.participant1Id) ||
        ids.contains(match.participant2Id);
  }

  void _refresh() {
    ref.invalidate(tournamentMatchesProvider(widget.tournament.id));
    ref.invalidate(tournamentDisputesProvider(widget.tournament.id));
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
        ).showSnackBar(SnackBar(content: Text('Action failed: $error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openMatch(TournamentMatch match) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (context) => _MatchActionSheet(
        match: match,
        isManager: _isManager,
        isParticipant: _isParticipant(match),
        currentUserId: widget.profile?.id,
        onAction: (action, data, success) async {
          Navigator.of(context).pop();
          await _run(() async {
            await ref
                .read(tournamentRepositoryProvider)
                .updateMatch(match.id, action: action, data: data);
          }, success);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final matches = ref.watch(tournamentMatchesProvider(widget.tournament.id));
    final disputes = ref.watch(
      tournamentDisputesProvider(widget.tournament.id),
    );

    return matches.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => CgeEmptyState(
        icon: '!',
        title: 'Could not load bracket',
        subtitle: '$error',
        actionLabel: 'Retry',
        onAction: _refresh,
      ),
      data: (items) {
        if (items.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 70),
              CgeEmptyState(
                icon: '🏆',
                title: 'Bracket not generated',
                subtitle: _isManager
                    ? 'Generate the bracket from paid tournament registrations.'
                    : 'The host will publish matchups when registration closes.',
              ),
              if (_isManager) ...[
                const SizedBox(height: 20),
                CgeButton(
                  label: 'Generate Bracket',
                  icon: LucideIcons.gitBranch,
                  fullWidth: true,
                  isLoading: _busy,
                  onPressed: () => _run(() async {
                    await ref
                        .read(tournamentRepositoryProvider)
                        .updateBracket(
                          widget.tournament.id,
                          action: 'generate',
                        );
                  }, 'Bracket generated'),
                ),
              ],
            ],
          );
        }

        final rounds = <String, List<TournamentMatch>>{};
        for (final match in items) {
          final group = match.bracketPosition == 'losers'
              ? 'Losers Round ${match.round}'
              : match.bracketPosition == 'round_robin'
              ? 'Round ${match.round}'
              : 'Winners Round ${match.round}';
          rounds.putIfAbsent(group, () => []).add(match);
        }

        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_isManager)
                Row(
                  children: [
                    Expanded(
                      child: CgeButton(
                        label: 'Regenerate',
                        variant: CgeButtonVariant.secondary,
                        icon: LucideIcons.refreshCw,
                        isLoading: _busy,
                        onPressed: () => _confirmRegenerate(),
                      ),
                    ),
                  ],
                ),
              if (_isManager) const SizedBox(height: 16),
              ...rounds.entries.expand(
                (entry) => [
                  Text(
                    entry.key,
                    style: AppTypography.label.copyWith(color: AppColors.cyan),
                  ),
                  const SizedBox(height: 8),
                  ...entry.value.map(
                    (match) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _MatchCard(
                        match: match,
                        highlighted: _isParticipant(match),
                        onTap: () => _openMatch(match),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
              if (_isManager)
                disputes.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (rows) {
                    final open = rows
                        .where((item) => item.status == 'open')
                        .toList();
                    if (open.isEmpty) return const SizedBox.shrink();
                    return _DisputesPanel(
                      disputes: open,
                      busy: _busy,
                      onResolve: (dispute, decision, resolution) => _run(
                        () async {
                          await ref
                              .read(tournamentRepositoryProvider)
                              .updateMatch(
                                dispute.matchId,
                                action: 'resolve_dispute',
                                data: {
                                  'dispute_id': dispute.id,
                                  'decision': decision,
                                  'resolution': resolution,
                                },
                              );
                        },
                        decision == 'resolved'
                            ? 'Dispute upheld; match reopened'
                            : 'Dispute dismissed',
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmRegenerate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerate bracket?'),
        content: const Text(
          'This removes current match results and creates a fresh bracket.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() async {
      final repository = ref.read(tournamentRepositoryProvider);
      await repository.updateBracket(widget.tournament.id, action: 'reset');
      await repository.updateBracket(widget.tournament.id, action: 'generate');
    }, 'Bracket regenerated');
  }
}

class _MatchCard extends StatelessWidget {
  final TournamentMatch match;
  final bool highlighted;
  final VoidCallback onTap;

  const _MatchCard({
    required this.match,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CgeCard(
      onTap: onTap,
      showGlow: highlighted,
      glowColor: AppColors.cyan,
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Match ${match.matchNumber}',
                style: AppTypography.labelSmall,
              ),
              const Spacer(),
              CgeBadge(
                label: match.status.replaceAll('_', ' '),
                color: _matchColor(match.status),
                fontSize: 9,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _playerRow(
            match.participant1Name ?? 'TBD',
            match.participant1Score,
            match.winnerId == match.participant1Id,
          ),
          const Divider(height: 18),
          _playerRow(
            match.participant2Name ?? 'TBD',
            match.participant2Score,
            match.winnerId == match.participant2Id,
          ),
        ],
      ),
    );
  }

  Widget _playerRow(String name, int? score, bool winner) {
    return Row(
      children: [
        if (winner)
          const Padding(
            padding: EdgeInsets.only(right: 6),
            child: Icon(LucideIcons.trophy, size: 14, color: AppColors.gold),
          ),
        Expanded(
          child: Text(
            name,
            style: AppTypography.label.copyWith(
              color: winner ? AppColors.gold : AppColors.text,
            ),
          ),
        ),
        if (score != null) Text('$score', style: AppTypography.headingSmall),
      ],
    );
  }
}

BadgeColor _matchColor(String status) {
  switch (status) {
    case 'completed':
    case 'bye':
      return BadgeColor.green;
    case 'in_progress':
      return BadgeColor.cyan;
    case 'awaiting_confirmation':
      return BadgeColor.gold;
    case 'disputed':
      return BadgeColor.red;
    default:
      return BadgeColor.cyan;
  }
}

class _MatchActionSheet extends StatefulWidget {
  final TournamentMatch match;
  final bool isManager;
  final bool isParticipant;
  final String? currentUserId;
  final Future<void> Function(
    String action,
    Map<String, dynamic>? data,
    String success,
  )
  onAction;

  const _MatchActionSheet({
    required this.match,
    required this.isManager,
    required this.isParticipant,
    required this.currentUserId,
    required this.onAction,
  });

  @override
  State<_MatchActionSheet> createState() => _MatchActionSheetState();
}

class _MatchActionSheetState extends State<_MatchActionSheet> {
  final _score1 = TextEditingController();
  final _score2 = TextEditingController();
  final _reason = TextEditingController();
  bool _showDispute = false;

  @override
  void dispose() {
    _score1.dispose();
    _score2.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final canAct = widget.isManager || widget.isParticipant;
    final isReporter = match.reportedBy == widget.currentUserId;
    final canConfirm =
        match.status == 'awaiting_confirmation' &&
        canAct &&
        (widget.isManager || !isReporter);
    final canReport =
        canAct && ['pending', 'in_progress'].contains(match.status);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Round ${match.round} • Match ${match.matchNumber}',
                style: AppTypography.headingSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _scoreCard(
                      match.participant1Name ?? 'TBD',
                      match.participant1Score,
                      match.winnerId == match.participant1Id,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('VS'),
                  ),
                  Expanded(
                    child: _scoreCard(
                      match.participant2Name ?? 'TBD',
                      match.participant2Score,
                      match.winnerId == match.participant2Id,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (canAct && match.status == 'pending' && match.hasParticipants)
                CgeButton(
                  label: 'Start Match',
                  fullWidth: true,
                  icon: LucideIcons.play,
                  onPressed: () =>
                      widget.onAction('start', null, 'Match started'),
                ),
              if (canReport) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _score1,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: match.participant1Name ?? 'Player 1',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _score2,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: match.participant2Name ?? 'Player 2',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CgeButton(
                        label: '${match.participant1Name ?? 'P1'} wins',
                        onPressed: match.participant1Id == null
                            ? null
                            : () => _report(match.participant1Id!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CgeButton(
                        label: '${match.participant2Name ?? 'P2'} wins',
                        onPressed: match.participant2Id == null
                            ? null
                            : () => _report(match.participant2Id!),
                      ),
                    ),
                  ],
                ),
              ],
              if (canConfirm) ...[
                CgeButton(
                  label: widget.isManager && !widget.isParticipant
                      ? 'Force Confirm Result'
                      : 'Confirm Result',
                  fullWidth: true,
                  icon: LucideIcons.check,
                  onPressed: () =>
                      widget.onAction('confirm', null, 'Result confirmed'),
                ),
                const SizedBox(height: 8),
              ],
              if (canAct &&
                  [
                    'awaiting_confirmation',
                    'in_progress',
                  ].contains(match.status))
                TextButton.icon(
                  onPressed: () => setState(() => _showDispute = !_showDispute),
                  icon: const Icon(LucideIcons.flag, size: 16),
                  label: const Text('Dispute this match'),
                ),
              if (_showDispute) ...[
                TextField(
                  controller: _reason,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'What happened?',
                    hintText:
                        'Incorrect score, disconnection or rule violation...',
                  ),
                ),
                const SizedBox(height: 10),
                CgeButton(
                  label: 'Submit Dispute',
                  variant: CgeButtonVariant.danger,
                  fullWidth: true,
                  onPressed: () {
                    if (_reason.text.trim().length < 5) return;
                    widget.onAction('dispute', {
                      'reason': _reason.text.trim(),
                    }, 'Dispute filed');
                  },
                ),
              ],
              if (!canAct)
                Text(
                  'Only the participants, tournament host or CGE admin can update this match.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scoreCard(String name, int? score, bool winner) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: winner
            ? AppColors.green.withValues(alpha: 0.08)
            : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: winner ? AppColors.green : AppColors.border),
      ),
      child: Column(
        children: [
          Text(name, style: AppTypography.label, textAlign: TextAlign.center),
          if (score != null) ...[
            const SizedBox(height: 6),
            Text('$score', style: AppTypography.heading),
          ],
        ],
      ),
    );
  }

  void _report(String winnerId) {
    final score1 = int.tryParse(_score1.text);
    final score2 = int.tryParse(_score2.text);
    if (score1 == null || score2 == null || score1 == score2) return;
    widget.onAction(
      'report',
      {
        'winner_id': winnerId,
        'participant1_score': score1,
        'participant2_score': score2,
      },
      widget.isManager
          ? 'Result saved and bracket advanced'
          : 'Result submitted for confirmation',
    );
  }
}

class _DisputesPanel extends StatefulWidget {
  final List<MatchDispute> disputes;
  final bool busy;
  final Future<void> Function(
    MatchDispute dispute,
    String decision,
    String resolution,
  )
  onResolve;

  const _DisputesPanel({
    required this.disputes,
    required this.busy,
    required this.onResolve,
  });

  @override
  State<_DisputesPanel> createState() => _DisputesPanelState();
}

class _DisputesPanelState extends State<_DisputesPanel> {
  final Map<int, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Open Disputes', style: AppTypography.headingSmall),
        const SizedBox(height: 10),
        ...widget.disputes.map((dispute) {
          final controller = _controllers.putIfAbsent(
            dispute.id,
            TextEditingController.new,
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CgeCard(
              showGlow: true,
              glowColor: AppColors.red,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Match ${dispute.match?.matchNumber ?? dispute.matchId}',
                    style: AppTypography.label,
                  ),
                  const SizedBox(height: 4),
                  Text(dispute.reason, style: AppTypography.bodySmall),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Resolution note',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: CgeButton(
                          label: 'Uphold',
                          isLoading: widget.busy,
                          onPressed: () =>
                              _resolve(dispute, 'resolved', controller.text),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CgeButton(
                          label: 'Dismiss',
                          variant: CgeButtonVariant.secondary,
                          isLoading: widget.busy,
                          onPressed: () =>
                              _resolve(dispute, 'dismissed', controller.text),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _resolve(MatchDispute dispute, String decision, String resolution) {
    if (resolution.trim().length < 3) return;
    widget.onResolve(dispute, decision, resolution.trim());
  }
}
