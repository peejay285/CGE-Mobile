import '../models/team.dart';
import '../remote/supabase_config.dart';

class TeamRepository {
  final _client = SupabaseConfig.client;

  Future<Map<String, Map<String, dynamic>>> _profilesFor(
    Iterable<String> ids,
  ) async {
    final uniqueIds = ids.toSet().toList();
    if (uniqueIds.isEmpty) return {};
    final response = await _client
        .from('profiles')
        .select(
          'id, full_name, phone, avatar_url, gamertag, bio, favourite_game, '
          'points, wins, losses, team_id, follower_count, following_count, '
          'tournament_count, achievement_count, total_listings, total_sales, '
          'total_swaps, avg_rating, rating_count, trust_level, location_state, '
          'location_city, location_lat, location_lng, is_admin, is_id_verified, '
          'id_verified_at, premium_tier, premium_expires_at, created_at',
        )
        .inFilter('id', uniqueIds);
    return {
      for (final raw in (response as List))
        (raw as Map)['id'] as String: Map<String, dynamic>.from(raw),
    };
  }

  Future<List<Team>> getTeams({String? game}) async {
    var query = _client.from('teams').select();
    if (game != null && game.isNotEmpty) query = query.eq('game', game);
    final response = await query.order('created_at', ascending: false);
    final rows = (response as List)
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .toList();
    if (rows.isEmpty) return [];

    final teamIds = rows.map((row) => (row['id'] as num).toInt()).toList();
    final memberRows = await _client
        .from('team_members')
        .select('team_id')
        .inFilter('team_id', teamIds);
    final counts = <int, int>{};
    for (final raw in (memberRows as List)) {
      final teamId = ((raw as Map)['team_id'] as num).toInt();
      counts[teamId] = (counts[teamId] ?? 0) + 1;
    }
    final profiles = await _profilesFor(
      rows.map((row) => row['captain_id'] as String),
    );

    return rows
        .map(
          (row) => Team.fromJson({
            ...row,
            'member_count': counts[(row['id'] as num).toInt()] ?? 0,
            'captain': profiles[row['captain_id']],
          }),
        )
        .toList();
  }

  Future<Team?> getMyTeam() async {
    final user = SupabaseConfig.currentUser;
    if (user == null) return null;
    final membership = await _client
        .from('team_members')
        .select('team_id')
        .eq('user_id', user.id)
        .limit(1)
        .maybeSingle();
    if (membership == null) return null;
    final teams = await getTeams();
    final teamId = (membership['team_id'] as num).toInt();
    for (final team in teams) {
      if (team.id == teamId) return team;
    }
    return null;
  }

  Future<List<TeamMember>> getMembers(int teamId) async {
    final response = await _client
        .from('team_members')
        .select()
        .eq('team_id', teamId)
        .order('joined_at');
    final rows = (response as List)
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .toList();
    final profiles = await _profilesFor(
      rows.map((row) => row['user_id'] as String),
    );
    return rows
        .map(
          (row) => TeamMember.fromJson({
            ...row,
            'profile': profiles[row['user_id']],
          }),
        )
        .toList();
  }

  Future<List<TeamJoinRequest>> getPendingRequests(int teamId) async {
    final response = await _client
        .from('team_join_requests')
        .select()
        .eq('team_id', teamId)
        .eq('status', 'pending')
        .order('created_at');
    final rows = (response as List)
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .toList();
    final profiles = await _profilesFor(
      rows.map((row) => row['user_id'] as String),
    );
    return rows
        .map(
          (row) => TeamJoinRequest.fromJson({
            ...row,
            'profile': profiles[row['user_id']],
          }),
        )
        .toList();
  }

  Future<TeamJoinRequest?> getMyPendingRequest(int teamId) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) return null;
    final response = await _client
        .from('team_join_requests')
        .select()
        .eq('team_id', teamId)
        .eq('user_id', user.id)
        .eq('status', 'pending')
        .maybeSingle();
    if (response == null) return null;
    return TeamJoinRequest.fromJson(Map<String, dynamic>.from(response));
  }

  Future<Team> createTeam({
    required String name,
    String? tag,
    String? description,
    String? game,
  }) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final response = await _client
        .from('teams')
        .insert({
          'name': name.trim(),
          'tag': tag?.trim().isEmpty == true ? null : tag?.trim(),
          'description': description?.trim().isEmpty == true
              ? null
              : description?.trim(),
          'game': game?.trim().isEmpty == true ? null : game?.trim(),
          'captain_id': user.id,
        })
        .select()
        .single();
    final team = Team.fromJson({
      ...Map<String, dynamic>.from(response),
      'member_count': 1,
    });
    await _client.from('team_members').insert({
      'team_id': team.id,
      'user_id': user.id,
      'role': 'captain',
    });
    await _client
        .from('profiles')
        .update({'team_id': team.id})
        .eq('id', user.id);
    return team;
  }

  Future<TeamJoinRequest> requestJoin(int teamId, {String? message}) async {
    final response = await _client
        .rpc(
          'request_team_join',
          params: {
            'p_team_id': teamId,
            'p_message': message?.trim().isEmpty == true
                ? null
                : message?.trim(),
          },
        )
        .single();
    return TeamJoinRequest.fromJson(Map<String, dynamic>.from(response));
  }

  Future<void> cancelJoinRequest(String requestId) async {
    await _client.rpc(
      'cancel_team_join_request',
      params: {'p_request_id': requestId},
    );
  }

  Future<TeamMember> approveJoinRequest(String requestId) async {
    final response = await _client
        .rpc('approve_team_join_request', params: {'p_request_id': requestId})
        .single();
    return TeamMember.fromJson(Map<String, dynamic>.from(response));
  }

  Future<void> declineJoinRequest(String requestId) async {
    await _client.rpc(
      'decline_team_join_request',
      params: {'p_request_id': requestId},
    );
  }

  Future<void> leaveTeam(int teamId) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('Not authenticated');
    await _client
        .from('team_members')
        .delete()
        .eq('team_id', teamId)
        .eq('user_id', user.id);
    await _client.from('profiles').update({'team_id': null}).eq('id', user.id);
  }
}
