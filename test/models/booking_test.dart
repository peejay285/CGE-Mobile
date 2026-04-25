import 'package:flutter_test/flutter_test.dart';
import 'package:cge_lounge_app/data/models/booking.dart';

void main() {
  group('Booking', () {
    group('fromJson', () {
      test('correctly parses all fields', () {
        final json = {
          'id': 'booking-001',
          'user_id': 'user-abc',
          'zone_id': 'main',
          'game_name': 'FC 25',
          'booking_date': '2026-03-21',
          'time_slot': '14:00',
          'duration': 2,
          'drinks': {'Coca-Cola': 2, 'Red Bull': 1},
          'session_total': 6000,
          'drinks_total': 2000,
          'total': 8000,
          'payment_method': 'paystack',
          'payment_status': 'paid',
          'paystack_reference': 'ref_abc_123',
          'pass_code': 'PASS-1234',
          'status': 'confirmed',
          'created_at': '2026-03-21T10:00:00Z',
        };

        final booking = Booking.fromJson(json);

        expect(booking.id, 'booking-001');
        expect(booking.userId, 'user-abc');
        expect(booking.zoneId, 'main');
        expect(booking.gameName, 'FC 25');
        expect(booking.bookingDate, '2026-03-21');
        expect(booking.timeSlot, '14:00');
        expect(booking.duration, 2);
        expect(booking.drinks, {'Coca-Cola': 2, 'Red Bull': 1});
        expect(booking.sessionTotal, 6000);
        expect(booking.drinksTotal, 2000);
        expect(booking.total, 8000);
        expect(booking.paymentMethod, 'paystack');
        expect(booking.paymentStatus, 'paid');
        expect(booking.paystackReference, 'ref_abc_123');
        expect(booking.passCode, 'PASS-1234');
        expect(booking.status, 'confirmed');
        expect(booking.createdAt, '2026-03-21T10:00:00Z');
      });

      test('handles null/missing optional fields (paystackReference, passCode)', () {
        final json = {
          'id': 'booking-002',
          'user_id': 'user-xyz',
          'zone_id': 'vip',
          'game_name': 'Mortal Kombat',
          'booking_date': '2026-03-22',
          'time_slot': '16:00',
          'duration': 1,
          'drinks': <String, dynamic>{},
          'session_total': 5000,
          'drinks_total': 0,
          'total': 5000,
          'payment_method': 'venue',
          'payment_status': 'pending',
          'status': 'confirmed',
          'created_at': '2026-03-22T08:00:00Z',
        };

        final booking = Booking.fromJson(json);

        expect(booking.paystackReference, isNull);
        expect(booking.passCode, isNull);
      });

      test('handles null drinks map', () {
        final json = {
          'id': 'booking-003',
          'user_id': 'user-xyz',
          'zone_id': 'vr',
          'game_name': 'Beat Saber',
          'booking_date': '2026-03-22',
          'time_slot': '18:00',
          'duration': 1,
          'drinks': null,
          'session_total': 2000,
          'drinks_total': 0,
          'total': 2000,
          'payment_method': 'venue',
          'payment_status': 'paid',
          'status': 'confirmed',
          'created_at': '2026-03-22T09:00:00Z',
        };

        final booking = Booking.fromJson(json);

        expect(booking.drinks, isEmpty);
        expect(booking.drinks, isA<Map<String, int>>());
      });

      test('handles empty drinks map', () {
        final json = {
          'id': 'booking-004',
          'user_id': 'user-xyz',
          'zone_id': 'main',
          'game_name': 'Tekken 8',
          'booking_date': '2026-03-22',
          'time_slot': '12:00',
          'duration': 1,
          'drinks': <String, dynamic>{},
          'session_total': 2000,
          'drinks_total': 0,
          'total': 2000,
          'payment_method': 'venue',
          'payment_status': 'paid',
          'status': 'completed',
          'created_at': '2026-03-22T11:00:00Z',
        };

        final booking = Booking.fromJson(json);

        expect(booking.drinks, isEmpty);
      });
    });

    group('toJson', () {
      test('produces expected output', () {
        const booking = Booking(
          id: 'booking-001',
          userId: 'user-abc',
          zoneId: 'main',
          gameName: 'FC 25',
          bookingDate: '2026-03-21',
          timeSlot: '14:00',
          duration: 2,
          drinks: {'Coca-Cola': 2},
          sessionTotal: 6000,
          drinksTotal: 1000,
          total: 7000,
          paymentMethod: 'paystack',
          paymentStatus: 'paid',
          paystackReference: 'ref_123',
          passCode: 'PASS-5678',
          status: 'confirmed',
          createdAt: '2026-03-21T10:00:00Z',
        );

        final json = booking.toJson();

        expect(json['user_id'], 'user-abc');
        expect(json['zone_id'], 'main');
        expect(json['game_name'], 'FC 25');
        expect(json['booking_date'], '2026-03-21');
        expect(json['time_slot'], '14:00');
        expect(json['duration'], 2);
        expect(json['drinks'], {'Coca-Cola': 2});
        expect(json['session_total'], 6000);
        expect(json['drinks_total'], 1000);
        expect(json['total'], 7000);
        expect(json['payment_method'], 'paystack');
        expect(json['payment_status'], 'paid');
        expect(json['paystack_reference'], 'ref_123');
        expect(json['pass_code'], 'PASS-5678');
        expect(json['status'], 'confirmed');
        // toJson does not include id or created_at
        expect(json.containsKey('id'), isFalse);
        expect(json.containsKey('created_at'), isFalse);
      });

      test('toJson includes null for optional fields when not set', () {
        const booking = Booking(
          id: 'booking-002',
          userId: 'user-xyz',
          zoneId: 'vip',
          gameName: 'Tekken 8',
          bookingDate: '2026-03-22',
          timeSlot: '16:00',
          duration: 1,
          sessionTotal: 5000,
          drinksTotal: 0,
          total: 5000,
          paymentMethod: 'venue',
          paymentStatus: 'pending',
          status: 'confirmed',
          createdAt: '2026-03-22T08:00:00Z',
        );

        final json = booking.toJson();

        expect(json['paystack_reference'], isNull);
        expect(json['pass_code'], isNull);
        expect(json['drinks'], isEmpty);
      });
    });
  });
}
