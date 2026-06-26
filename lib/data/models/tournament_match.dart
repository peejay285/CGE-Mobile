class TournamentMatch {
  final int id;
  final int tournamentId;
  final int round;
  final int matchNumber;
  final String? bracketPosition;
  final String? participant1Id;
  final String? participant2Id;
  final String? participant1Name;
  final String? participant2Name;
  final int? participant1Seed;
  final int? participant2Seed;
  final int? participant1Score;
  final int? participant2Score;
  final String? winnerId;
  final String? loserId;
  final String status;
  final String? reportedBy;
  final String? reportedAt;
  final String? confirmedBy;
  final String? confirmedAt;
  final int? nextMatchId;
  final int? nextMatchSlot;
  final int? loserNextMatchId;
  final int? loserNextMatchSlot;
  final String? scheduledAt;
  final String? startedAt;
  final String? completedAt;
  final String createdAt;

  const TournamentMatch({
    required this.id,
    required this.tournamentId,
    required this.round,
    required this.matchNumber,
    this.bracketPosition,
    this.participant1Id,
    this.participant2Id,
    this.participant1Name,
    this.participant2Name,
    this.participant1Seed,
    this.participant2Seed,
    this.participant1Score,
    this.participant2Score,
    this.winnerId,
    this.loserId,
    required this.status,
    this.reportedBy,
    this.reportedAt,
    this.confirmedBy,
    this.confirmedAt,
    this.nextMatchId,
    this.nextMatchSlot,
    this.loserNextMatchId,
    this.loserNextMatchSlot,
    this.scheduledAt,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
  });

  factory TournamentMatch.fromJson(Map<String, dynamic> json) =>
      TournamentMatch(
        id: json['id'] as int,
        tournamentId: json['tournament_id'] as int,
        round: json['round'] as int,
        matchNumber: json['match_number'] as int,
        bracketPosition: json['bracket_position'] as String?,
        participant1Id: json['participant1_id'] as String?,
        participant2Id: json['participant2_id'] as String?,
        participant1Name: json['participant1_name'] as String?,
        participant2Name: json['participant2_name'] as String?,
        participant1Seed: json['participant1_seed'] as int?,
        participant2Seed: json['participant2_seed'] as int?,
        participant1Score: json['participant1_score'] as int?,
        participant2Score: json['participant2_score'] as int?,
        winnerId: json['winner_id'] as String?,
        loserId: json['loser_id'] as String?,
        status: json['status'] as String? ?? 'pending',
        reportedBy: json['reported_by'] as String?,
        reportedAt: json['reported_at'] as String?,
        confirmedBy: json['confirmed_by'] as String?,
        confirmedAt: json['confirmed_at'] as String?,
        nextMatchId: json['next_match_id'] as int?,
        nextMatchSlot: json['next_match_slot'] as int?,
        loserNextMatchId: json['loser_next_match_id'] as int?,
        loserNextMatchSlot: json['loser_next_match_slot'] as int?,
        scheduledAt: json['scheduled_at'] as String?,
        startedAt: json['started_at'] as String?,
        completedAt: json['completed_at'] as String?,
        createdAt: json['created_at'] as String? ?? '',
      );

  bool get hasParticipants => participant1Id != null && participant2Id != null;
  bool get isFinal => status == 'completed' || status == 'bye';
}

class MatchDispute {
  final int id;
  final int matchId;
  final String reportedBy;
  final String reason;
  final List<String> evidenceUrls;
  final String status;
  final String? resolvedBy;
  final String? resolution;
  final String createdAt;
  final String? resolvedAt;
  final TournamentMatch? match;

  const MatchDispute({
    required this.id,
    required this.matchId,
    required this.reportedBy,
    required this.reason,
    this.evidenceUrls = const [],
    required this.status,
    this.resolvedBy,
    this.resolution,
    required this.createdAt,
    this.resolvedAt,
    this.match,
  });

  factory MatchDispute.fromJson(Map<String, dynamic> json) => MatchDispute(
    id: json['id'] as int,
    matchId: json['match_id'] as int,
    reportedBy: json['reported_by'] as String,
    reason: json['reason'] as String,
    evidenceUrls: List<String>.from(json['evidence_urls'] as List? ?? const []),
    status: json['status'] as String? ?? 'open',
    resolvedBy: json['resolved_by'] as String?,
    resolution: json['resolution'] as String?,
    createdAt: json['created_at'] as String? ?? '',
    resolvedAt: json['resolved_at'] as String?,
    match: json['match'] is Map
        ? TournamentMatch.fromJson(
            Map<String, dynamic>.from(json['match'] as Map),
          )
        : null,
  );
}
