import 'package:cge_lounge_app/core/utils/tournament_access.dart';
import 'package:cge_lounge_app/data/models/profile.dart';
import 'package:cge_lounge_app/data/models/tournament.dart';
import 'package:flutter_test/flutter_test.dart';

Tournament tournament({String? createdBy}) => Tournament(
  id: 1,
  title: 'Cup',
  game: 'FC 26',
  date: '2026-06-30',
  time: '14:00',
  entryFee: 1000,
  prize: 10000,
  slots: 16,
  filled: 0,
  format: 'Single Elimination',
  platform: 'PS5',
  status: 'open',
  createdBy: createdBy,
  createdAt: '2026-06-22T12:00:00Z',
);

Profile profile(String id, {bool isAdmin = false}) => Profile(
  id: id,
  fullName: 'User',
  isAdmin: isAdmin,
  createdAt: '2026-06-22T12:00:00Z',
);

void main() {
  test('missing creator and missing profile never grants manager access', () {
    expect(canManageTournament(tournament(), null), isFalse);
  });

  test('host and admin can manage while another user cannot', () {
    expect(
      canManageTournament(tournament(createdBy: 'host'), profile('host')),
      isTrue,
    );
    expect(
      canManageTournament(
        tournament(createdBy: 'host'),
        profile('admin', isAdmin: true),
      ),
      isTrue,
    );
    expect(
      canManageTournament(tournament(createdBy: 'host'), profile('other')),
      isFalse,
    );
  });
}
