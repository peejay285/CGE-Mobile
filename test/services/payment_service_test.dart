import 'package:flutter_test/flutter_test.dart';
import 'package:cge_lounge_app/core/services/payment_service.dart';

void main() {
  group('PaymentService', () {
    group('toKobo', () {
      test('converts 1000 naira to 100000 kobo', () {
        expect(PaymentService.toKobo(1000), 100000);
      });

      test('converts 0 naira to 0 kobo', () {
        expect(PaymentService.toKobo(0), 0);
      });

      test('converts 5500 naira to 550000 kobo', () {
        expect(PaymentService.toKobo(5500), 550000);
      });

      test('converts 1 naira to 100 kobo', () {
        expect(PaymentService.toKobo(1), 100);
      });
    });

    // generateReference tests skipped — requires SupabaseConfig.currentUser
    // which needs Supabase initialized (integration test territory)
  });
}
