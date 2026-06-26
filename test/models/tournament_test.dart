import 'package:flutter_test/flutter_test.dart';
import 'package:cge_lounge_app/data/models/tournament.dart';

Tournament tournament({
  required String date,
  String status = 'open',
  int filled = 0,
  int slots = 16,
}) => Tournament(
  id: 1,
  title: 'FC Weekend Cup',
  game: 'FC 26',
  date: date,
  time: '2:00 PM',
  entryFee: 2000,
  prize: 50000,
  slots: slots,
  filled: filled,
  format: 'Single Elimination',
  platform: 'PS5',
  status: status,
  createdAt: '2026-06-22T12:00:00Z',
);

void main() {
  group('Tournament registration state', () {
    test('does not treat past open tournaments as registerable', () {
      final stale = tournament(date: '2000-01-01');

      expect(stale.hasPassed, isTrue);
      expect(stale.isRegistrationExpired, isTrue);
      expect(stale.isOpen, isFalse);
    });

    test('keeps future open tournaments registerable when slots remain', () {
      final upcoming = tournament(date: '2999-01-01');

      expect(upcoming.hasPassed, isFalse);
      expect(upcoming.isRegistrationExpired, isFalse);
      expect(upcoming.isOpen, isTrue);
    });

    test('does not open full tournaments', () {
      final full = tournament(date: '2999-01-01', filled: 16, slots: 16);

      expect(full.isOpen, isFalse);
    });
  });
}
