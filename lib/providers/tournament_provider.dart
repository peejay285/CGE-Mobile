import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/tournament_repository.dart';
import '../data/models/tournament.dart';

final tournamentRepositoryProvider =
    Provider((_) => TournamentRepository());

final tournamentsProvider =
    FutureProvider.family<List<Tournament>, String?>((ref, status) async {
  return ref.read(tournamentRepositoryProvider).getTournaments(status: status);
});

final tournamentDetailProvider =
    FutureProvider.family<Tournament?, int>((ref, id) async {
  return ref.read(tournamentRepositoryProvider).getTournamentById(id);
});

final leaderboardProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(tournamentRepositoryProvider).getLeaderboard();
});
