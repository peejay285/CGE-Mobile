import 'package:flutter_test/flutter_test.dart';
import 'package:cge_lounge_app/core/constants/pricing.dart';

void main() {
  group('Pricing', () {
    group('formatPrice', () {
      test('formats 1500 as NGN 1,500', () {
        expect(Pricing.formatPrice(1500), '\u20A61,500');
      });

      test('formats 0 as NGN 0', () {
        expect(Pricing.formatPrice(0), '\u20A60');
      });

      test('formats 10000 as NGN 10,000', () {
        expect(Pricing.formatPrice(10000), '\u20A610,000');
      });

      test('formats 1000000 with commas', () {
        expect(Pricing.formatPrice(1000000), '\u20A61,000,000');
      });

      test('formats small number without comma', () {
        expect(Pricing.formatPrice(500), '\u20A6500');
      });
    });

    group('mainLoungePrice', () {
      test('returns 3000 for FC games', () {
        expect(Pricing.mainLoungePrice('FC 25'), 3000);
      });

      test('returns 3000 for FIFA games', () {
        expect(Pricing.mainLoungePrice('FIFA 23'), 3000);
      });

      test('returns 2000 for non-FC/FIFA games', () {
        expect(Pricing.mainLoungePrice('Tekken 8'), 2000);
      });

      test('returns 2000 for Mortal Kombat', () {
        expect(Pricing.mainLoungePrice('Mortal Kombat'), 2000);
      });
    });

    group('getSessionTotal', () {
      test('calculates main zone with FC game correctly', () {
        final total = Pricing.getSessionTotal(
          zoneId: 'main',
          game: 'FC 25',
          duration: 2,
        );
        expect(total, 6000); // 3000 * 2
      });

      test('calculates main zone with non-FC game correctly', () {
        final total = Pricing.getSessionTotal(
          zoneId: 'main',
          game: 'Tekken 8',
          duration: 3,
        );
        expect(total, 6000); // 2000 * 3
      });

      test('calculates VIP zone correctly', () {
        final total = Pricing.getSessionTotal(
          zoneId: 'vip',
          game: 'Any Game',
          duration: 2,
        );
        expect(total, 10000); // 5000 * 2
      });

      test('calculates VR zone correctly', () {
        final total = Pricing.getSessionTotal(
          zoneId: 'vr',
          game: 'Beat Saber',
          duration: 4,
        );
        expect(total, 8000); // 2000 * 4
      });

      test('returns 0 for unknown zone', () {
        final total = Pricing.getSessionTotal(
          zoneId: 'unknown',
          game: 'Any',
          duration: 1,
        );
        expect(total, 0);
      });
    });

    group('getAddOnsTotal', () {
      test('calculates single drink correctly', () {
        final total = Pricing.getAddOnsTotal({'Coca-Cola': 2});
        expect(total, 1000); // 500 * 2
      });

      test('calculates multiple drinks correctly', () {
        final total = Pricing.getAddOnsTotal({
          'Coca-Cola': 1,
          'Red Bull': 2,
        });
        expect(total, 2500); // 500 + 2000
      });

      test('calculates snacks correctly', () {
        final total = Pricing.getAddOnsTotal({'Pringles': 1, 'Popcorn': 2});
        expect(total, 1800); // 800 + 1000
      });

      test('calculates mixed drinks and snacks', () {
        final total = Pricing.getAddOnsTotal({
          'Water': 3,
          'Chin Chin': 2,
        });
        expect(total, 2100); // 1500 + 600
      });

      test('returns 0 for empty map', () {
        final total = Pricing.getAddOnsTotal({});
        expect(total, 0);
      });

      test('returns 0 for unknown items', () {
        final total = Pricing.getAddOnsTotal({'Unknown Item': 5});
        expect(total, 0);
      });
    });
  });
}
