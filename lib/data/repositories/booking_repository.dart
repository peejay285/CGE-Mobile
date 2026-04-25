import 'dart:math';
import '../remote/supabase_config.dart';
import '../models/booking.dart';

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
  }) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final passCode = _generatePassCode();

    final data = {
      'user_id': user.id,
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
      'payment_status': paymentMethod == 'venue' ? 'pending' : 'pending',
      'pass_code': passCode,
      'status': 'confirmed',
    };

    final response =
        await _client.from('bookings').insert(data).select().single();

    return Booking.fromJson(response);
  }

  /// Check slot availability
  Future<bool> checkAvailability({
    required String zoneId,
    required String date,
    required String timeSlot,
  }) async {
    final response = await _client
        .from('bookings')
        .select('id')
        .eq('zone_id', zoneId)
        .eq('booking_date', date)
        .eq('time_slot', timeSlot)
        .neq('status', 'cancelled');

    return (response as List).isEmpty;
  }

  /// Cancel a booking
  Future<void> cancelBooking(String bookingId) async {
    await _client
        .from('bookings')
        .update({'status': 'cancelled'}).eq('id', bookingId);
  }

  String _generatePassCode() {
    final rng = Random();
    return List.generate(6, (_) => rng.nextInt(10)).join();
  }
}
