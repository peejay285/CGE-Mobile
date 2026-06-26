import 'package:cge_lounge_app/data/models/tournament_match.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TournamentMatch parses a reported result and progression links', () {
    final match = TournamentMatch.fromJson({
      'id': 7,
      'tournament_id': 3,
      'round': 1,
      'match_number': 2,
      'bracket_position': 'winners',
      'participant1_id': 'p1',
      'participant2_id': 'p2',
      'participant1_name': 'Alpha',
      'participant2_name': 'Bravo',
      'participant1_score': 3,
      'participant2_score': 1,
      'winner_id': 'p1',
      'loser_id': 'p2',
      'status': 'awaiting_confirmation',
      'reported_by': 'p1',
      'next_match_id': 10,
      'next_match_slot': 1,
      'created_at': '2026-06-22T12:00:00Z',
    });

    expect(match.hasParticipants, isTrue);
    expect(match.winnerId, 'p1');
    expect(match.participant1Score, 3);
    expect(match.nextMatchId, 10);
    expect(match.isFinal, isFalse);
  });

  test('MatchDispute hydrates its match context', () {
    final dispute = MatchDispute.fromJson({
      'id': 5,
      'match_id': 7,
      'reported_by': 'p2',
      'reason': 'The submitted score is incorrect',
      'evidence_urls': <String>[],
      'status': 'open',
      'created_at': '2026-06-22T12:10:00Z',
      'match': {
        'id': 7,
        'tournament_id': 3,
        'round': 1,
        'match_number': 2,
        'participant1_id': 'p1',
        'participant2_id': 'p2',
        'participant1_name': 'Alpha',
        'participant2_name': 'Bravo',
        'status': 'disputed',
        'created_at': '2026-06-22T12:00:00Z',
      },
    });

    expect(dispute.match?.status, 'disputed');
    expect(dispute.match?.participant2Name, 'Bravo');
  });
}
