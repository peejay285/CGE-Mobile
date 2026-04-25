class Tournament {
  final int id;
  final String title;
  final String game;
  final String date;
  final String time;
  final int entryFee;
  final int prize;
  final int slots;
  final int filled;
  final String format;
  final String platform;
  final String status; // open, full, in_progress, completed, cancelled
  final String? rules;
  final String createdBy;
  final String? streamUrl;
  final int? seriesId;
  final int? teamSize;
  final bool? checkInRequired;
  final int? checkInOpensMinutes;
  final String? bracketType;
  final String? description;
  final String createdAt;

  const Tournament({
    required this.id,
    required this.title,
    required this.game,
    required this.date,
    required this.time,
    required this.entryFee,
    required this.prize,
    required this.slots,
    required this.filled,
    required this.format,
    required this.platform,
    required this.status,
    this.rules,
    required this.createdBy,
    this.streamUrl,
    this.seriesId,
    this.teamSize,
    this.checkInRequired,
    this.checkInOpensMinutes,
    this.bracketType,
    this.description,
    required this.createdAt,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) => Tournament(
        id: json['id'] as int,
        title: json['title'] as String,
        game: json['game'] as String,
        date: json['date'] as String,
        time: json['time'] as String,
        entryFee: json['entry_fee'] as int? ?? 0,
        prize: json['prize'] as int? ?? 0,
        slots: json['slots'] as int,
        filled: json['filled'] as int? ?? 0,
        format: json['format'] as String,
        platform: json['platform'] as String,
        status: json['status'] as String,
        rules: json['rules'] as String?,
        createdBy: json['created_by'] as String,
        streamUrl: json['stream_url'] as String?,
        seriesId: json['series_id'] as int?,
        teamSize: json['team_size'] as int?,
        checkInRequired: json['check_in_required'] as bool?,
        checkInOpensMinutes: json['check_in_opens_minutes'] as int?,
        bracketType: json['bracket_type'] as String?,
        description: json['description'] as String?,
        createdAt: json['created_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'game': game,
        'date': date,
        'time': time,
        'entry_fee': entryFee,
        'prize': prize,
        'slots': slots,
        'format': format,
        'platform': platform,
        'status': status,
        'rules': rules,
        'created_by': createdBy,
        'stream_url': streamUrl,
        'team_size': teamSize,
        'check_in_required': checkInRequired,
        'check_in_opens_minutes': checkInOpensMinutes,
        'bracket_type': bracketType,
        'description': description,
      };

  bool get isOpen => status == 'open' && filled < slots;
  bool get isLive => status == 'in_progress';
  bool get isFree => entryFee == 0;
}

class TournamentRegistration {
  final String id;
  final int tournamentId;
  final String userId;
  final String? paymentStatus;
  final String? paystackReference;
  final bool? checkedIn;
  final String? checkedInAt;
  final String registeredAt;

  const TournamentRegistration({
    required this.id,
    required this.tournamentId,
    required this.userId,
    this.paymentStatus,
    this.paystackReference,
    this.checkedIn,
    this.checkedInAt,
    required this.registeredAt,
  });

  factory TournamentRegistration.fromJson(Map<String, dynamic> json) =>
      TournamentRegistration(
        id: json['id'] as String,
        tournamentId: json['tournament_id'] as int,
        userId: json['user_id'] as String,
        paymentStatus: json['payment_status'] as String?,
        paystackReference: json['paystack_reference'] as String?,
        checkedIn: json['checked_in'] as bool?,
        checkedInAt: json['checked_in_at'] as String?,
        registeredAt: json['registered_at'] as String,
      );
}
