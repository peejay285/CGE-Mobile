import 'package:flutter_test/flutter_test.dart';
import 'package:cge_lounge_app/data/models/profile.dart';

void main() {
  group('Profile', () {
    group('fromJson', () {
      test('correctly parses all fields', () {
        final json = {
          'id': 'user-001',
          'full_name': 'John Doe',
          'phone': '+2348012345678',
          'avatar_url': 'https://example.com/avatar.jpg',
          'gamertag': 'JD_Pro',
          'bio': 'Competitive gamer',
          'favourite_game': 'FC 25',
          'points': 1500,
          'wins': 42,
          'losses': 10,
          'team_id': 3,
          'follower_count': 100,
          'following_count': 50,
          'tournament_count': 8,
          'achievement_count': 15,
          'total_listings': 5,
          'total_sales': 3,
          'total_swaps': 2,
          'avg_rating': 4.5,
          'rating_count': 12,
          'trust_level': 'verified',
          'fcm_token': 'fcm-token-xyz',
          'created_at': '2026-01-01T00:00:00Z',
        };

        final profile = Profile.fromJson(json);

        expect(profile.id, 'user-001');
        expect(profile.fullName, 'John Doe');
        expect(profile.phone, '+2348012345678');
        expect(profile.avatarUrl, 'https://example.com/avatar.jpg');
        expect(profile.gamertag, 'JD_Pro');
        expect(profile.bio, 'Competitive gamer');
        expect(profile.favouriteGame, 'FC 25');
        expect(profile.points, 1500);
        expect(profile.wins, 42);
        expect(profile.losses, 10);
        expect(profile.teamId, 3);
        expect(profile.followerCount, 100);
        expect(profile.followingCount, 50);
        expect(profile.tournamentCount, 8);
        expect(profile.achievementCount, 15);
        expect(profile.totalListings, 5);
        expect(profile.totalSales, 3);
        expect(profile.totalSwaps, 2);
        expect(profile.avgRating, 4.5);
        expect(profile.ratingCount, 12);
        expect(profile.trustLevel, 'verified');
        expect(profile.fcmToken, 'fcm-token-xyz');
        expect(profile.createdAt, '2026-01-01T00:00:00Z');
      });

      test('handles minimal fields (only required: id, full_name, created_at)', () {
        final json = {
          'id': 'user-002',
          'full_name': 'Jane Smith',
          'created_at': '2026-03-21T00:00:00Z',
        };

        final profile = Profile.fromJson(json);

        expect(profile.id, 'user-002');
        expect(profile.fullName, 'Jane Smith');
        expect(profile.createdAt, '2026-03-21T00:00:00Z');
        expect(profile.phone, isNull);
        expect(profile.avatarUrl, isNull);
        expect(profile.gamertag, isNull);
        expect(profile.bio, isNull);
        expect(profile.favouriteGame, isNull);
        expect(profile.teamId, isNull);
        expect(profile.followerCount, isNull);
        expect(profile.followingCount, isNull);
        expect(profile.tournamentCount, isNull);
        expect(profile.achievementCount, isNull);
        expect(profile.totalListings, isNull);
        expect(profile.totalSales, isNull);
        expect(profile.totalSwaps, isNull);
        expect(profile.avgRating, isNull);
        expect(profile.ratingCount, isNull);
        expect(profile.trustLevel, isNull);
        expect(profile.fcmToken, isNull);
      });

      test('defaults points=0, wins=0, losses=0 when missing', () {
        final json = {
          'id': 'user-003',
          'full_name': 'New Player',
          'created_at': '2026-03-21T00:00:00Z',
        };

        final profile = Profile.fromJson(json);

        expect(profile.points, 0);
        expect(profile.wins, 0);
        expect(profile.losses, 0);
      });

      test('defaults full_name to empty string when null', () {
        final json = {
          'id': 'user-004',
          'full_name': null,
          'created_at': '2026-03-21T00:00:00Z',
        };

        final profile = Profile.fromJson(json);

        expect(profile.fullName, '');
      });

      test('parses avg_rating as double from int', () {
        final json = {
          'id': 'user-005',
          'full_name': 'Test',
          'created_at': '2026-03-21T00:00:00Z',
          'avg_rating': 4,
        };

        final profile = Profile.fromJson(json);

        expect(profile.avgRating, 4.0);
        expect(profile.avgRating, isA<double>());
      });
    });

    group('toJson', () {
      test('produces expected output', () {
        const profile = Profile(
          id: 'user-001',
          fullName: 'John Doe',
          phone: '+2348012345678',
          avatarUrl: 'https://example.com/avatar.jpg',
          gamertag: 'JD_Pro',
          bio: 'Competitive gamer',
          favouriteGame: 'FC 25',
          points: 1500,
          wins: 42,
          losses: 10,
          teamId: 3,
          fcmToken: 'fcm-xyz',
          createdAt: '2026-01-01T00:00:00Z',
        );

        final json = profile.toJson();

        expect(json['id'], 'user-001');
        expect(json['full_name'], 'John Doe');
        expect(json['phone'], '+2348012345678');
        expect(json['avatar_url'], 'https://example.com/avatar.jpg');
        expect(json['gamertag'], 'JD_Pro');
        expect(json['bio'], 'Competitive gamer');
        expect(json['favourite_game'], 'FC 25');
        expect(json['points'], 1500);
        expect(json['wins'], 42);
        expect(json['losses'], 10);
        expect(json['team_id'], 3);
        expect(json['fcm_token'], 'fcm-xyz');
        // toJson does not include read-only computed fields
        expect(json.containsKey('created_at'), isFalse);
        expect(json.containsKey('follower_count'), isFalse);
        expect(json.containsKey('following_count'), isFalse);
      });
    });
  });
}
