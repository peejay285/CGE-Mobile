import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/team.dart';
import '../../../data/remote/supabase_config.dart';
import '../../../providers/team_provider.dart';
import '../../../widgets/cge_avatar.dart';
import '../../../widgets/cge_badge.dart';
import '../../../widgets/cge_button.dart';
import '../../../widgets/cge_card.dart';
import '../../../widgets/cge_skeleton.dart';

class TeamsTab extends ConsumerWidget {
  const TeamsTab({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(teamsProvider);
    ref.invalidate(myTeamProvider);
    await Future.wait([
      ref.read(teamsProvider.future),
      ref.read(myTeamProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamsProvider);
    final myTeamAsync = ref.watch(myTeamProvider);

    return RefreshIndicator(
      color: AppColors.cyan,
      onRefresh: () => _refresh(ref),
      child: teamsAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          itemBuilder: (_, _) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: CgeSkeleton.card(),
          ),
        ),
        error: (error, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 100),
            const Icon(
              LucideIcons.wifiOff,
              size: 44,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Could not load teams',
                style: AppTypography.headingSmall,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 80),
              child: CgeButton(label: 'Retry', onPressed: () => _refresh(ref)),
            ),
          ],
        ),
        data: (teams) {
          final myTeam = myTeamAsync.valueOrNull;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              if (myTeam != null) ...[
                Text('Your Team', style: AppTypography.subheading),
                const SizedBox(height: 10),
                _TeamCard(
                  team: myTeam,
                  isMine: true,
                  onTap: () => _showTeam(context, ref, myTeam, myTeam),
                ),
                const SizedBox(height: 24),
              ] else ...[
                CgeButton(
                  label: 'Create a Team',
                  icon: LucideIcons.plus,
                  onPressed: () => _createTeam(context, ref),
                  fullWidth: true,
                ),
                const SizedBox(height: 24),
              ],
              Text('Discover Teams', style: AppTypography.subheading),
              const SizedBox(height: 10),
              if (teams.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 56),
                  child: Column(
                    children: [
                      const Icon(
                        LucideIcons.swords,
                        size: 48,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 14),
                      Text('No teams yet', style: AppTypography.headingSmall),
                    ],
                  ),
                )
              else
                ...teams
                    .where((team) => team.id != myTeam?.id)
                    .map(
                      (team) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TeamCard(
                          team: team,
                          onTap: () => _showTeam(context, ref, team, myTeam),
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createTeam(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final tagController = TextEditingController();
    final descriptionController = TextEditingController();
    String? game;
    var loading = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Create Team'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Team name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tagController,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Short tag (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: game,
                  decoration: const InputDecoration(labelText: 'Main game'),
                  items: AppConstants.esportsGames
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) => setDialogState(() => game = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: loading
                  ? null
                  : () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            CgeButton(
              label: 'Create',
              isLoading: loading,
              onPressed: loading
                  ? null
                  : () async {
                      if (nameController.text.trim().length < 3) return;
                      setDialogState(() => loading = true);
                      try {
                        await ref
                            .read(teamRepositoryProvider)
                            .createTeam(
                              name: nameController.text,
                              tag: tagController.text,
                              description: descriptionController.text,
                              game: game,
                            );
                        ref.invalidate(teamsProvider);
                        ref.invalidate(myTeamProvider);
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                      } catch (error) {
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(content: Text(error.toString())),
                          );
                          setDialogState(() => loading = false);
                        }
                      }
                    },
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    tagController.dispose();
    descriptionController.dispose();
  }

  Future<void> _showTeam(
    BuildContext context,
    WidgetRef ref,
    Team team,
    Team? myTeam,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        maxChildSize: 0.92,
        builder: (context, controller) => Consumer(
          builder: (context, ref, _) {
            final members = ref.watch(teamMembersProvider(team.id));
            final requests = ref.watch(teamJoinRequestsProvider(team.id));
            final myRequest = ref.watch(myTeamJoinRequestProvider(team.id));
            final currentUserId = SupabaseConfig.currentUser?.id;
            final isMyTeam = myTeam?.id == team.id;
            final isCaptain = team.captainId == currentUserId;

            return ListView(
              controller: controller,
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    CgeAvatar(
                      name: team.name,
                      imageUrl: team.logoUrl,
                      size: 54,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(team.name, style: AppTypography.headingSmall),
                          Text(
                            [
                              if (team.tag?.isNotEmpty == true) '[${team.tag}]',
                              team.game ?? 'Multi-game',
                            ].join(' · '),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CgeBadge(
                      label: '${team.memberCount} members',
                      color: BadgeColor.cyan,
                    ),
                  ],
                ),
                if (team.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  Text(team.description!, style: AppTypography.body),
                ],
                const SizedBox(height: 20),
                if (!isMyTeam && myTeam == null)
                  myRequest.when(
                    loading: () => const CgeButton(
                      label: 'Checking request…',
                      onPressed: null,
                      fullWidth: true,
                    ),
                    error: (_, _) => CgeButton(
                      label: 'Request to Join',
                      fullWidth: true,
                      onPressed: () => _requestJoin(context, ref, team.id),
                    ),
                    data: (request) => CgeButton(
                      label: request == null
                          ? 'Request to Join'
                          : 'Cancel Pending Request',
                      variant: request == null
                          ? CgeButtonVariant.primary
                          : CgeButtonVariant.secondary,
                      fullWidth: true,
                      onPressed: () async {
                        if (request == null) {
                          await _requestJoin(context, ref, team.id);
                        } else {
                          await ref
                              .read(teamRepositoryProvider)
                              .cancelJoinRequest(request.id);
                          ref.invalidate(myTeamJoinRequestProvider(team.id));
                        }
                      },
                    ),
                  ),
                const SizedBox(height: 22),
                Text('Members', style: AppTypography.subheading),
                const SizedBox(height: 8),
                members.when(
                  loading: () => const CgeSkeleton.card(),
                  error: (_, _) => const Text('Could not load members'),
                  data: (items) => Column(
                    children: items
                        .map(
                          (member) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CgeAvatar(
                              name: member.profile?.fullName ?? 'Gamer',
                              imageUrl: member.profile?.avatarUrl,
                              size: 36,
                            ),
                            title: Text(
                              member.profile?.gamertag ??
                                  member.profile?.fullName ??
                                  'Gamer',
                            ),
                            trailing: CgeBadge(
                              label: member.role,
                              color: member.role == 'captain'
                                  ? BadgeColor.gold
                                  : BadgeColor.cyan,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                if (isCaptain) ...[
                  const SizedBox(height: 20),
                  Text('Pending Requests', style: AppTypography.subheading),
                  const SizedBox(height: 8),
                  requests.when(
                    loading: () => const CgeSkeleton.card(),
                    error: (_, _) => const Text('Could not load requests'),
                    data: (items) => items.isEmpty
                        ? Text(
                            'No pending requests',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          )
                        : Column(
                            children: items
                                .map(
                                  (request) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      request.profile?.gamertag ??
                                          request.profile?.fullName ??
                                          'Gamer',
                                    ),
                                    subtitle: request.message == null
                                        ? null
                                        : Text(request.message!),
                                    trailing: Wrap(
                                      children: [
                                        IconButton(
                                          tooltip: 'Approve',
                                          icon: const Icon(
                                            LucideIcons.check,
                                            color: AppColors.green,
                                          ),
                                          onPressed: () async {
                                            await ref
                                                .read(teamRepositoryProvider)
                                                .approveJoinRequest(request.id);
                                            ref.invalidate(
                                              teamJoinRequestsProvider(team.id),
                                            );
                                            ref.invalidate(
                                              teamMembersProvider(team.id),
                                            );
                                            ref.invalidate(teamsProvider);
                                          },
                                        ),
                                        IconButton(
                                          tooltip: 'Decline',
                                          icon: const Icon(
                                            LucideIcons.x,
                                            color: AppColors.red,
                                          ),
                                          onPressed: () async {
                                            await ref
                                                .read(teamRepositoryProvider)
                                                .declineJoinRequest(request.id);
                                            ref.invalidate(
                                              teamJoinRequestsProvider(team.id),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _requestJoin(
    BuildContext context,
    WidgetRef ref,
    int teamId,
  ) async {
    try {
      await ref.read(teamRepositoryProvider).requestJoin(teamId);
      ref.invalidate(myTeamJoinRequestProvider(teamId));
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Join request sent')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }
}

class _TeamCard extends StatelessWidget {
  final Team team;
  final bool isMine;
  final VoidCallback onTap;

  const _TeamCard({
    required this.team,
    required this.onTap,
    this.isMine = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CgeCard(
        showGlow: isMine,
        child: Row(
          children: [
            CgeAvatar(name: team.name, imageUrl: team.logoUrl, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(team.name, style: AppTypography.subheading),
                  const SizedBox(height: 3),
                  Text(
                    [
                      if (team.tag?.isNotEmpty == true) '[${team.tag}]',
                      team.game ?? 'Multi-game',
                      '${team.memberCount} members',
                    ].join(' · '),
                    style: AppTypography.labelSmall,
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
