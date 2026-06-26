import 'package:cge_lounge_app/core/services/deep_link_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaymentReturn', () {
    test('parses tournament payment return and routes to its tournament', () {
      final result = PaymentReturn.fromUri(
        Uri.parse(
          'cge://payment-return?payment_type=tournament&payment_ref=abc&tournament_id=12',
        ),
      );

      expect(result, isNotNull);
      expect(result!.type, 'tournament');
      expect(result.reference, 'abc');
      expect(result.tournamentId, 12);
      expect(result.route, '/esports/12');
    });

    test('maps each supported payment type to a safe app route', () {
      expect(
        PaymentReturn.fromUri(
          Uri.parse('cge://payment-return?payment_type=booking'),
        )?.route,
        '/profile/bookings',
      );
      expect(
        PaymentReturn.fromUri(
          Uri.parse('cge://payment-return?payment_type=swap_assist'),
        )?.route,
        '/profile/swaps',
      );
      expect(
        PaymentReturn.fromUri(
          Uri.parse('cge://payment-return?payment_type=premium'),
        )?.route,
        '/profile/upgrade',
      );
    });

    test('rejects unrelated or incomplete links', () {
      expect(PaymentReturn.fromUri(Uri.parse('https://cgelounge.com')), isNull);
      expect(PaymentReturn.fromUri(Uri.parse('cge://payment-return')), isNull);
    });
  });
}
