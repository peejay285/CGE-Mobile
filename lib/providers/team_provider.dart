import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/team.dart';
import '../data/repositories/team_repository.dart';

final teamRepositoryProvider = Provider((_) => TeamRepository());

final teamsProvider = FutureProvider<List<Team>>((ref) {
  return ref.read(teamRepositoryProvider).getTeams();
});

final myTeamProvider = FutureProvider<Team?>((ref) {
  return ref.read(teamRepositoryProvider).getMyTeam();
});

final teamMembersProvider = FutureProvider.family<List<TeamMember>, int>((
  ref,
  teamId,
) {
  return ref.read(teamRepositoryProvider).getMembers(teamId);
});

final teamJoinRequestsProvider =
    FutureProvider.family<List<TeamJoinRequest>, int>((ref, teamId) {
      return ref.read(teamRepositoryProvider).getPendingRequests(teamId);
    });

final myTeamJoinRequestProvider = FutureProvider.family<TeamJoinRequest?, int>((
  ref,
  teamId,
) {
  return ref.read(teamRepositoryProvider).getMyPendingRequest(teamId);
});
