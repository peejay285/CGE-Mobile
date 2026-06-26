import '../../core/network/cge_api_client.dart';
import '../remote/supabase_config.dart';
import '../models/tournament.dart';
import '../models/team.dart';
import '../models/tournament_match.dart';
import '../models/tournament_payout.dart';

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
  Future<TournamentRegistration> register(int tournamentId) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final response = await _client
        .rpc(
          'create_tournament_registration_with_payment',
          params: {'p_tournament_id': tournamentId, 'p_user_id': user.id},
        )
        .single();
    return TournamentRegistration.fromJson(Map<String, dynamic>.from(response));
  }

  Future<TournamentTeamRegistration> registerTeam({
    required int tournamentId,
    required int teamId,
  }) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final response = await _client
        .rpc(
          'create_tournament_team_registration_with_payment',
          params: {
            'p_tournament_id': tournamentId,
            'p_team_id': teamId,
            'p_registered_by': user.id,
          },
        )
        .single();
    return TournamentTeamRegistration.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  Future<TournamentRegistration?> getMyRegistration(int tournamentId) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) return null;
    final response = await _client
        .from('tournament_registrations')
        .select()
        .eq('tournament_id', tournamentId)
        .eq('user_id', user.id)
        .maybeSingle();
    if (response == null) return null;
    return TournamentRegistration.fromJson(Map<String, dynamic>.from(response));
  }

  Future<TournamentTeamRegistration?> getMyTeamRegistration(
    int tournamentId,
  ) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) return null;
    final response = await _client
        .from('tournament_team_registrations')
        .select()
        .eq('tournament_id', tournamentId)
        .eq('registered_by', user.id)
        .maybeSingle();
    if (response == null) return null;
    return TournamentTeamRegistration.fromJson(
      Map<String, dynamic>.from(response),
    );
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

  Future<void> checkInTeam(int tournamentId, int teamId) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('Not authenticated');
    await _client
        .from('tournament_team_registrations')
        .update({
          'checked_in': true,
          'checked_in_at': DateTime.now().toIso8601String(),
        })
        .eq('tournament_id', tournamentId)
        .eq('team_id', teamId)
        .eq('registered_by', user.id);
  }

  Future<List<TournamentMatch>> getMatches(int tournamentId) async {
    final response = await _client
        .from('tournament_matches')
        .select()
        .eq('tournament_id', tournamentId)
        .order('round')
        .order('match_number');
    return (response as List)
        .map(
          (row) =>
              TournamentMatch.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<TournamentMatch> updateMatch(
    int matchId, {
    required String action,
    Map<String, dynamic>? data,
  }) async {
    final response = await CgeApiClient.post(
      '/api/tournament-matches/$matchId',
      body: {'action': action, ...?data},
    );
    final match = response['match'];
    if (match is! Map) {
      throw const CgeApiException('Match server returned an invalid response');
    }
    return TournamentMatch.fromJson(Map<String, dynamic>.from(match));
  }

  Future<List<TournamentMatch>> updateBracket(
    int tournamentId, {
    required String action,
  }) async {
    final response = await CgeApiClient.post(
      '/api/tournaments/$tournamentId/bracket',
      body: {'action': action},
    );
    final matches = response['matches'];
    if (matches is! List) {
      throw const CgeApiException(
        'Bracket server returned an invalid response',
      );
    }
    return matches
        .map(
          (row) =>
              TournamentMatch.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<List<MatchDispute>> getDisputes(int tournamentId) async {
    final response = await _client
        .from('match_disputes')
        .select('*, match:tournament_matches!inner(*)')
        .eq('match.tournament_id', tournamentId)
        .order('created_at', ascending: false);
    return (response as List)
        .map(
          (row) => MatchDispute.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<List<TournamentRegistrant>> getRegistrants(
    Tournament tournament,
  ) async {
    if (tournament.isTeamTournament) {
      final response = await _client
          .from('tournament_team_registrations')
          .select()
          .eq('tournament_id', tournament.id)
          .order('registered_at');
      final rows = List<Map<String, dynamic>>.from(response as List);
      final teamIds = rows.map((row) => row['team_id'] as int).toSet().toList();
      final teams = teamIds.isEmpty
          ? const <Map<String, dynamic>>[]
          : List<Map<String, dynamic>>.from(
              await _client
                      .from('teams')
                      .select('id, name, tag, logo_url, captain_id')
                      .inFilter('id', teamIds)
                  as List,
            );
      final teamMap = {for (final team in teams) team['id'] as int: team};
      final captainIds = teams
          .map((team) => team['captain_id'] as String)
          .toSet()
          .toList();
      final captains = captainIds.isEmpty
          ? const <Map<String, dynamic>>[]
          : List<Map<String, dynamic>>.from(
              await _client.from('profiles').select().inFilter('id', captainIds)
                  as List,
            );
      final captainMap = {
        for (final captain in captains) captain['id'] as String: captain,
      };
      return rows.map((row) {
        final teamId = row['team_id'] as int;
        final team = teamMap[teamId];
        final name = team?['name'] as String? ?? 'Team $teamId';
        final tag = team?['tag'] as String?;
        final captainId =
            team?['captain_id'] as String? ?? row['registered_by'] as String;
        final captain = captainMap[captainId];
        return TournamentRegistrant.fromJson({
          ...row,
          'user_id': captainId,
          'profile': {
            ...?captain,
            'id': captainId,
            'full_name': tag == null ? name : '[$tag] $name',
            'gamertag': tag ?? name,
            'avatar_url': team?['logo_url'],
            'created_at': '',
          },
        });
      }).toList();
    }

    final response = await _client
        .from('tournament_registrations')
        .select()
        .eq('tournament_id', tournament.id)
        .order('registered_at');
    final rows = List<Map<String, dynamic>>.from(response as List);
    final userIds = rows
        .map((row) => row['user_id'] as String)
        .toSet()
        .toList();
    final profiles = userIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(
            await _client.from('profiles').select().inFilter('id', userIds)
                as List,
          );
    final profileMap = {
      for (final profile in profiles) profile['id'] as String: profile,
    };
    return rows
        .map(
          (row) => TournamentRegistrant.fromJson({
            ...row,
            'profile': profileMap[row['user_id']],
          }),
        )
        .toList();
  }

  Future<TournamentPayoutData> getPayoutData(Tournament tournament) async {
    final payoutResponse = await _client
        .from('tournament_payouts')
        .select()
        .eq('tournament_id', tournament.id)
        .order('placement');
    final placementResponse = await _client
        .from('tournament_prize_placements')
        .select()
        .eq('tournament_id', tournament.id)
        .order('placement');
    final registrants = await getRegistrants(tournament);

    final payoutRows = List<Map<String, dynamic>>.from(payoutResponse);
    final placementRows = List<Map<String, dynamic>>.from(placementResponse);
    final userIds = {
      ...payoutRows.map((row) => row['user_id'] as String),
      ...placementRows.map((row) => row['user_id'] as String),
    }.toList();
    final profiles = userIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(
            await _client.from('profiles').select().inFilter('id', userIds)
                as List,
          );
    final profileMap = {
      for (final profile in profiles) profile['id'] as String: profile,
    };

    return TournamentPayoutData(
      payouts: payoutRows
          .map(
            (row) => TournamentPayout.fromJson({
              ...row,
              'profile': profileMap[row['user_id']],
            }),
          )
          .toList(),
      placements: placementRows
          .map(
            (row) => TournamentPrizePlacement.fromJson({
              ...row,
              'profile': profileMap[row['user_id']],
            }),
          )
          .toList(),
      registrants: registrants,
    );
  }

  Future<void> setPrizePlacement({
    required int tournamentId,
    required int placement,
    required String userId,
  }) async {
    await _client.rpc(
      'set_tournament_prize_placement',
      params: {
        'p_tournament_id': tournamentId,
        'p_placement': placement,
        'p_user_id': userId,
      },
    );
  }

  Future<Map<String, dynamic>?> preparePayouts(int tournamentId) async {
    final data = await _client.rpc(
      'prepare_tournament_payouts',
      params: {'p_tournament_id': tournamentId},
    );
    if (data is List && data.isNotEmpty) {
      return Map<String, dynamic>.from(data.first as Map);
    }
    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  Future<int> approvePayouts(int tournamentId) async {
    final data = await _client.rpc(
      'approve_tournament_payouts',
      params: {'p_tournament_id': tournamentId},
    );
    return (data as num?)?.toInt() ?? 0;
  }

  Future<Map<String, dynamic>> releasePayout(String payoutId) {
    return CgeApiClient.post('/api/tournament-payouts/$payoutId/release');
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

    final response = await _client
        .from('tournaments')
        .insert(data)
        .select()
        .single();
    return Tournament.fromJson(response);
  }
}
