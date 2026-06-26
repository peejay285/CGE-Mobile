class Booking {
  final String id;
  final String userId;
  final String zoneId;
  final String gameName;
  final String bookingDate;
  final String timeSlot;
  final int duration;
  final Map<String, int> drinks;
  final int sessionTotal;
  final int drinksTotal;
  final int total;
  final String paymentMethod; // paystack, venue
  final String paymentStatus; // pending, paid, failed, refunded
  final String? paystackReference;
  final String? receiptToken;
  final String? passCode;
  final String status; // confirmed, cancelled, completed
  final String createdAt;

  const Booking({
    required this.id,
    required this.userId,
    required this.zoneId,
    required this.gameName,
    required this.bookingDate,
    required this.timeSlot,
    required this.duration,
    this.drinks = const {},
    required this.sessionTotal,
    required this.drinksTotal,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    this.paystackReference,
    this.receiptToken,
    this.passCode,
    required this.status,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    zoneId: json['zone_id'] as String,
    gameName: json['game_name'] as String,
    bookingDate: json['booking_date'] as String,
    timeSlot: json['time_slot'] as String,
    duration: json['duration'] as int,
    drinks:
        (json['drinks'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, v as int),
        ) ??
        {},
    sessionTotal: json['session_total'] as int,
    drinksTotal: json['drinks_total'] as int,
    total: json['total'] as int,
    paymentMethod: json['payment_method'] as String,
    paymentStatus: json['payment_status'] as String,
    paystackReference: json['paystack_reference'] as String?,
    receiptToken: json['receipt_token'] as String?,
    passCode: json['pass_code'] as String?,
    status: json['status'] as String,
    createdAt: json['created_at'] as String,
  );

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'zone_id': zoneId,
    'game_name': gameName,
    'booking_date': bookingDate,
    'time_slot': timeSlot,
    'duration': duration,
    'drinks': drinks,
    'session_total': sessionTotal,
    'drinks_total': drinksTotal,
    'total': total,
    'payment_method': paymentMethod,
    'payment_status': paymentStatus,
    'paystack_reference': paystackReference,
    'receipt_token': receiptToken,
    'pass_code': passCode,
    'status': status,
  };
}
