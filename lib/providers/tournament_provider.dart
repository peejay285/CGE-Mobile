import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/tournament_repository.dart';
import '../data/models/tournament.dart';
import '../data/models/team.dart';
import '../data/models/tournament_match.dart';
import '../data/models/tournament_payout.dart';

final tournamentRepositoryProvider = Provider((_) => TournamentRepository());

final tournamentsProvider = FutureProvider.family<List<Tournament>, String?>((
  ref,
  status,
) async {
  return ref.read(tournamentRepositoryProvider).getTournaments(status: status);
});

final tournamentDetailProvider = FutureProvider.family<Tournament?, int>((
  ref,
  id,
) async {
  return ref.read(tournamentRepositoryProvider).getTournamentById(id);
});

final leaderboardProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  return ref.read(tournamentRepositoryProvider).getLeaderboard();
});

final myTournamentRegistrationProvider =
    FutureProvider.family<TournamentRegistration?, int>((ref, id) {
      return ref.read(tournamentRepositoryProvider).getMyRegistration(id);
    });

final myTeamTournamentRegistrationProvider =
    FutureProvider.family<TournamentTeamRegistration?, int>((ref, id) {
      return ref.read(tournamentRepositoryProvider).getMyTeamRegistration(id);
    });

final tournamentMatchesProvider =
    FutureProvider.family<List<TournamentMatch>, int>((ref, id) {
      return ref.read(tournamentRepositoryProvider).getMatches(id);
    });

final tournamentDisputesProvider =
    FutureProvider.family<List<MatchDispute>, int>((ref, id) {
      return ref.read(tournamentRepositoryProvider).getDisputes(id);
    });

final tournamentRegistrantsProvider =
    FutureProvider.family<List<TournamentRegistrant>, Tournament>((ref, value) {
      return ref.read(tournamentRepositoryProvider).getRegistrants(value);
    });

final tournamentPayoutDataProvider =
    FutureProvider.family<TournamentPayoutData, Tournament>((ref, value) {
      return ref.read(tournamentRepositoryProvider).getPayoutData(value);
    });
