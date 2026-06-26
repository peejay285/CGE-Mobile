import 'profile.dart';

class TournamentRegistrant {
  final String id;
  final int tournamentId;
  final String userId;
  final int total;
  final String paymentStatus;
  final bool checkedIn;
  final Profile? profile;

  const TournamentRegistrant({
    required this.id,
    required this.tournamentId,
    required this.userId,
    required this.total,
    required this.paymentStatus,
    required this.checkedIn,
    this.profile,
  });

  factory TournamentRegistrant.fromJson(Map<String, dynamic> json) =>
      TournamentRegistrant(
        id: json['id'] as String,
        tournamentId: json['tournament_id'] as int,
        userId: json['user_id'] as String,
        total: (json['total'] as num?)?.toInt() ?? 0,
        paymentStatus: json['payment_status'] as String? ?? 'pending',
        checkedIn: json['checked_in'] as bool? ?? false,
        profile: json['profile'] is Map
            ? Profile.fromJson(
                Map<String, dynamic>.from(json['profile'] as Map),
              )
            : null,
      );
}

class TournamentPrizePlacement {
  final String id;
  final int tournamentId;
  final int placement;
  final String userId;
  final String source;
  final Profile? profile;

  const TournamentPrizePlacement({
    required this.id,
    required this.tournamentId,
    required this.placement,
    required this.userId,
    required this.source,
    this.profile,
  });

  factory TournamentPrizePlacement.fromJson(Map<String, dynamic> json) =>
      TournamentPrizePlacement(
        id: json['id'] as String,
        tournamentId: json['tournament_id'] as int,
        placement: json['placement'] as int,
        userId: json['user_id'] as String,
        source: json['source'] as String? ?? 'manual',
        profile: json['profile'] is Map
            ? Profile.fromJson(
                Map<String, dynamic>.from(json['profile'] as Map),
              )
            : null,
      );
}

class TournamentPayout {
  final String id;
  final int tournamentId;
  final String userId;
  final int placement;
  final double percentage;
  final int grossAmount;
  final int platformFeeAmount;
  final int netAmount;
  final String status;
  final String? transferReference;
  final String? processedAt;
  final String? notes;
  final Profile? profile;

  const TournamentPayout({
    required this.id,
    required this.tournamentId,
    required this.userId,
    required this.placement,
    required this.percentage,
    required this.grossAmount,
    required this.platformFeeAmount,
    required this.netAmount,
    required this.status,
    this.transferReference,
    this.processedAt,
    this.notes,
    this.profile,
  });

  factory TournamentPayout.fromJson(Map<String, dynamic> json) =>
      TournamentPayout(
        id: json['id'] as String,
        tournamentId: json['tournament_id'] as int,
        userId: json['user_id'] as String,
        placement: json['placement'] as int,
        percentage: (json['percentage'] as num).toDouble(),
        grossAmount: (json['gross_amount'] as num).toInt(),
        platformFeeAmount: (json['platform_fee_amount'] as num?)?.toInt() ?? 0,
        netAmount: (json['net_amount'] as num).toInt(),
        status: json['status'] as String,
        transferReference: json['paystack_transfer_reference'] as String?,
        processedAt: json['processed_at'] as String?,
        notes: json['notes'] as String?,
        profile: json['profile'] is Map
            ? Profile.fromJson(
                Map<String, dynamic>.from(json['profile'] as Map),
              )
            : null,
      );
}

class TournamentPayoutData {
  final List<TournamentPayout> payouts;
  final List<TournamentPrizePlacement> placements;
  final List<TournamentRegistrant> registrants;

  const TournamentPayoutData({
    this.payouts = const [],
    this.placements = const [],
    this.registrants = const [],
  });
}

class PaystackBank {
  final String name;
  final String code;

  const PaystackBank({required this.name, required this.code});

  factory PaystackBank.fromJson(Map<String, dynamic> json) =>
      PaystackBank(name: json['name'] as String, code: json['code'] as String);
}
