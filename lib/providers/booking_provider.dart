import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/booking_repository.dart';
import '../data/models/booking.dart';

final bookingRepositoryProvider = Provider((_) => BookingRepository());

final userBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  return ref.read(bookingRepositoryProvider).getUserBookings();
});
