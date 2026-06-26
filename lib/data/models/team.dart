import 'profile.dart';

class Team {
  final int id;
  final String name;
  final String? tag;
  final String? logoUrl;
  final String captainId;
  final String? description;
  final String? game;
  final String createdAt;
  final int memberCount;
  final Profile? captain;

  const Team({
    required this.id,
    required this.name,
    this.tag,
    this.logoUrl,
    required this.captainId,
    this.description,
    this.game,
    required this.createdAt,
    this.memberCount = 0,
    this.captain,
  });

  factory Team.fromJson(Map<String, dynamic> json) => Team(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
    tag: json['tag'] as String?,
    logoUrl: json['logo_url'] as String?,
    captainId: json['captain_id'] as String,
    description: json['description'] as String?,
    game: json['game'] as String?,
    createdAt: json['created_at'] as String,
    memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
    captain: json['captain'] is Map<String, dynamic>
        ? Profile.fromJson(json['captain'] as Map<String, dynamic>)
        : null,
  );
}

class TeamMember {
  final int id;
  final int teamId;
  final String userId;
  final String role;
  final String joinedAt;
  final Profile? profile;

  const TeamMember({
    required this.id,
    required this.teamId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.profile,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) => TeamMember(
    id: (json['id'] as num).toInt(),
    teamId: (json['team_id'] as num).toInt(),
    userId: json['user_id'] as String,
    role: json['role'] as String? ?? 'member',
    joinedAt: json['joined_at'] as String,
    profile: json['profile'] is Map<String, dynamic>
        ? Profile.fromJson(json['profile'] as Map<String, dynamic>)
        : null,
  );
}

class TeamJoinRequest {
  final String id;
  final int teamId;
  final String userId;
  final String? message;
  final String status;
  final String? decidedBy;
  final String? decidedAt;
  final String createdAt;
  final String updatedAt;
  final Profile? profile;

  const TeamJoinRequest({
    required this.id,
    required this.teamId,
    required this.userId,
    this.message,
    required this.status,
    this.decidedBy,
    this.decidedAt,
    required this.createdAt,
    required this.updatedAt,
    this.profile,
  });

  factory TeamJoinRequest.fromJson(Map<String, dynamic> json) =>
      TeamJoinRequest(
        id: json['id'] as String,
        teamId: (json['team_id'] as num).toInt(),
        userId: json['user_id'] as String,
        message: json['message'] as String?,
        status: json['status'] as String,
        decidedBy: json['decided_by'] as String?,
        decidedAt: json['decided_at'] as String?,
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
        profile: json['profile'] is Map<String, dynamic>
            ? Profile.fromJson(json['profile'] as Map<String, dynamic>)
            : null,
      );
}

class TournamentTeamRegistration {
  final String id;
  final int tournamentId;
  final int teamId;
  final String registeredBy;
  final int total;
  final String? paymentMethod;
  final String paymentStatus;
  final String? paystackReference;
  final String? paidAt;
  final String registeredAt;
  final bool checkedIn;
  final String? checkedInAt;

  const TournamentTeamRegistration({
    required this.id,
    required this.tournamentId,
    required this.teamId,
    required this.registeredBy,
    this.total = 0,
    this.paymentMethod,
    required this.paymentStatus,
    this.paystackReference,
    this.paidAt,
    required this.registeredAt,
    this.checkedIn = false,
    this.checkedInAt,
  });

  factory TournamentTeamRegistration.fromJson(Map<String, dynamic> json) =>
      TournamentTeamRegistration(
        id: json['id'] as String,
        tournamentId: (json['tournament_id'] as num).toInt(),
        teamId: (json['team_id'] as num).toInt(),
        registeredBy: json['registered_by'] as String,
        total: (json['total'] as num?)?.toInt() ?? 0,
        paymentMethod: json['payment_method'] as String?,
        paymentStatus: json['payment_status'] as String? ?? 'pending',
        paystackReference: json['paystack_reference'] as String?,
        paidAt: json['paid_at'] as String?,
        registeredAt: json['registered_at'] as String,
        checkedIn: json['checked_in'] as bool? ?? false,
        checkedInAt: json['checked_in_at'] as String?,
      );
}
