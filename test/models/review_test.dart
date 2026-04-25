import 'package:flutter_test/flutter_test.dart';
import 'package:cge_lounge_app/data/models/review.dart';

void main() {
  group('Review', () {
    group('fromJson', () {
      test('correctly parses all fields with reviewer join', () {
        final json = {
          'id': 'review-001',
          'reviewer_id': 'user-abc',
          'seller_id': 'user-xyz',
          'listing_id': 'listing-001',
          'rating': 5,
          'comment': 'Great seller, fast delivery!',
          'type': 'buyer_to_seller',
          'created_at': '2026-03-21T10:00:00Z',
          'reviewer': {
            'id': 'user-abc',
            'full_name': 'John Doe',
            'created_at': '2026-01-01T00:00:00Z',
          },
        };

        final review = Review.fromJson(json);

        expect(review.id, 'review-001');
        expect(review.reviewerId, 'user-abc');
        expect(review.sellerId, 'user-xyz');
        expect(review.listingId, 'listing-001');
        expect(review.rating, 5);
        expect(review.comment, 'Great seller, fast delivery!');
        expect(review.type, 'buyer_to_seller');
        expect(review.createdAt, '2026-03-21T10:00:00Z');
        expect(review.reviewer, isNotNull);
        expect(review.reviewer!.id, 'user-abc');
        expect(review.reviewer!.fullName, 'John Doe');
      });

      test('handles null reviewer', () {
        final json = {
          'id': 'review-002',
          'reviewer_id': 'user-abc',
          'seller_id': 'user-xyz',
          'listing_id': null,
          'rating': 3,
          'comment': null,
          'type': 'seller_to_buyer',
          'created_at': '2026-03-21T12:00:00Z',
        };

        final review = Review.fromJson(json);

        expect(review.reviewer, isNull);
        expect(review.listingId, isNull);
        expect(review.comment, isNull);
      });

      test('defaults type to buyer_to_seller when null', () {
        final json = {
          'id': 'review-003',
          'reviewer_id': 'user-abc',
          'seller_id': 'user-xyz',
          'rating': 4,
          'created_at': '2026-03-21T14:00:00Z',
        };

        final review = Review.fromJson(json);

        expect(review.type, 'buyer_to_seller');
      });
    });

    group('toJson', () {
      test('produces expected output', () {
        const review = Review(
          id: 'review-001',
          reviewerId: 'user-abc',
          sellerId: 'user-xyz',
          listingId: 'listing-001',
          rating: 5,
          comment: 'Excellent!',
          type: 'buyer_to_seller',
          createdAt: '2026-03-21T10:00:00Z',
        );

        final json = review.toJson();

        expect(json['reviewer_id'], 'user-abc');
        expect(json['seller_id'], 'user-xyz');
        expect(json['listing_id'], 'listing-001');
        expect(json['rating'], 5);
        expect(json['comment'], 'Excellent!');
        expect(json['type'], 'buyer_to_seller');
        // toJson does not include id or created_at
        expect(json.containsKey('id'), isFalse);
        expect(json.containsKey('created_at'), isFalse);
      });

      test('toJson includes null for optional fields when not set', () {
        const review = Review(
          id: 'review-002',
          reviewerId: 'user-abc',
          sellerId: 'user-xyz',
          rating: 3,
          type: 'seller_to_buyer',
          createdAt: '2026-03-21T12:00:00Z',
        );

        final json = review.toJson();

        expect(json['listing_id'], isNull);
        expect(json['comment'], isNull);
      });
    });
  });
}
