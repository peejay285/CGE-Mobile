import '../../core/network/cge_api_client.dart';
import '../remote/supabase_config.dart';
import '../models/booking.dart';

class BookingAvailability {
  final bool available;
  final int remainingSlots;
  final int totalCapacity;
  final int bookedCount;

  const BookingAvailability({
    required this.available,
    required this.remainingSlots,
    required this.totalCapacity,
    required this.bookedCount,
  });
}

class BookingRepository {
  final _client = SupabaseConfig.client;

  /// Fetch user's bookings
  Future<List<Booking>> getUserBookings() async {
    final user = SupabaseConfig.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('bookings')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Booking.fromJson(e)).toList();
  }

  /// Create a new booking
  Future<Booking> createBooking({
    required String zoneId,
    required String gameName,
    required String bookingDate,
    required String timeSlot,
    required int duration,
    required Map<String, int> drinks,
    required int sessionTotal,
    required int drinksTotal,
    required int total,
    required String paymentMethod,
    String? voucherCode,
  }) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final response = await CgeApiClient.post(
      '/api/bookings/create',
      body: {
        'zone_id': zoneId,
        'game_name': gameName,
        'booking_date': bookingDate,
        'time_slot': timeSlot,
        'duration': duration,
        'drinks': drinks,
        'payment_method': paymentMethod,
        if (voucherCode != null && voucherCode.trim().isNotEmpty)
          'voucher_code': voucherCode.trim(),
      },
    );

    final booking = response['booking'];
    if (booking is! Map<String, dynamic>) {
      throw const CgeApiException(
        'Booking server returned an invalid response',
      );
    }
    return Booking.fromJson(booking);
  }

  /// Check duration-aware slot availability using the shared aggregate RPC.
  Future<BookingAvailability> checkAvailability({
    required String zoneId,
    required String date,
    required String timeSlot,
    int duration = 1,
  }) async {
    final rows = await _client.rpc(
      'get_slot_availability',
      params: {'p_zone_id': zoneId, 'p_booking_date': date},
    );

    final byHour = <int, ({int booked, int capacity})>{};
    for (final raw in (rows as List)) {
      final row = Map<String, dynamic>.from(raw as Map);
      byHour[(row['slot_hour'] as num).toInt()] = (
        booked: (row['booked_count'] as num?)?.toInt() ?? 0,
        capacity: (row['capacity'] as num?)?.toInt() ?? 1,
      );
    }

    final start = _slotToHour(timeSlot);
    final span = zoneId == 'vr' ? 1 : duration.clamp(1, 8);
    var capacity = byHour[start]?.capacity ?? 1;
    var worstBooked = 0;
    for (var hour = start; hour < start + span; hour++) {
      final info = byHour[hour];
      if (info == null) continue;
      capacity = info.capacity;
      if (info.booked > worstBooked) worstBooked = info.booked;
    }
    final remaining = (capacity - worstBooked).clamp(0, capacity);

    return BookingAvailability(
      available: remaining > 0,
      remainingSlots: remaining,
      totalCapacity: capacity,
      bookedCount: worstBooked,
    );
  }

  /// Cancel a booking
  Future<void> cancelBooking(String bookingId) async {
    await _client
        .from('bookings')
        .update({'status': 'cancelled'})
        .eq('id', bookingId);
  }

  int _slotToHour(String slot) {
    final match = RegExp(
      r'^(\d{1,2}):\d{2}\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(slot.trim());
    if (match == null) throw const FormatException('Invalid time slot');
    var hour = int.parse(match.group(1)!);
    final period = match.group(2)!.toUpperCase();
    if (hour == 12) hour = 0;
    if (period == 'PM') hour += 12;
    return hour;
  }
}
