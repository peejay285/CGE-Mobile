import '../remote/supabase_config.dart';
import '../models/tournament.dart';

class TournamentRepository {
  final _client = SupabaseConfig.client;

  /// Fetch tournaments with optional status filter
  Future<List<Tournament>> getTournaments({String? status}) async {
    var query = _client.from('tournaments').select();

    if (status != null && status != 'all') {
      query = query.eq('status', status);
    }

    final response = await query.order('date', ascending: true);
    return (response as List).map((e) => Tournament.fromJson(e)).toList();
  }

  /// Get single tournament
  Future<Tournament?> getTournamentById(int id) async {
    final response = await _client
        .from('tournaments')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Tournament.fromJson(response);
  }

  /// Register for a tournament
  Future<void> register(int tournamentId) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _client.from('tournament_registrations').insert({
      'tournament_id': tournamentId,
      'user_id': user.id,
    });

    // Increment filled count
    await _client.rpc('increment_tournament_filled',
        params: {'t_id': tournamentId});
  }

  /// Check in to tournament
  Future<void> checkIn(int tournamentId) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _client
        .from('tournament_registrations')
        .update({
          'checked_in': true,
          'checked_in_at': DateTime.now().toIso8601String(),
        })
        .eq('tournament_id', tournamentId)
        .eq('user_id', user.id);
  }

  /// Get leaderboard
  Future<List<Map<String, dynamic>>> getLeaderboard({String? game}) async {
    var query = _client
        .from('profiles')
        .select('id, full_name, gamertag, avatar_url, points, wins, losses')
        .gt('points', 0)
        .order('points', ascending: false)
        .limit(50);

    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  /// Create tournament
  Future<Tournament> createTournament(Map<String, dynamic> data) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('Not authenticated');

    data['created_by'] = user.id;
    data['filled'] = 0;
    data['status'] = 'open';

    final response =
        await _client.from('tournaments').insert(data).select().single();
    return Tournament.fromJson(response);
  }
}
