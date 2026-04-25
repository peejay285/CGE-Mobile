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
          'swap_proposal_id': 'proposal-001',
          'rating': 5,
          'communication_rating': 5,
          'condition_rating': 4,
          'speed_rating': 5,
          'review': 'Great seller, fast delivery!',
          'is_swap': true,
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
        expect(review.swapProposalId, 'proposal-001');
        expect(review.rating, 5);
        expect(review.communicationRating, 5);
        expect(review.conditionRating, 4);
        expect(review.speedRating, 5);
        expect(review.review, 'Great seller, fast delivery!');
        expect(review.isSwap, isTrue);
        expect(review.createdAt, '2026-03-21T10:00:00Z');
        expect(review.reviewer, isNotNull);
        expect(review.reviewer!.id, 'user-abc');
        expect(review.reviewer!.fullName, 'John Doe');
      });

      test('handles purchase review (no swap_proposal_id, no sub-ratings)', () {
        final json = {
          'id': 'review-002',
          'reviewer_id': 'user-abc',
          'seller_id': 'user-xyz',
          'listing_id': 'listing-002',
          'rating': 3,
          'review': null,
          'created_at': '2026-03-21T12:00:00Z',
        };

        final review = Review.fromJson(json);

        expect(review.swapProposalId, isNull);
        expect(review.communicationRating, isNull);
        expect(review.conditionRating, isNull);
        expect(review.speedRating, isNull);
        expect(review.review, isNull);
        expect(review.isSwap, isFalse);
        expect(review.reviewer, isNull);
      });
    });

    group('toJson', () {
      test('includes all fields when set, omits optional ones when null', () {
        const review = Review(
          id: 'review-001',
          reviewerId: 'user-abc',
          sellerId: 'user-xyz',
          listingId: 'listing-001',
          swapProposalId: 'proposal-001',
          rating: 5,
          communicationRating: 5,
          conditionRating: 4,
          speedRating: 5,
          review: 'Excellent!',
          isSwap: true,
          createdAt: '2026-03-21T10:00:00Z',
        );

        final json = review.toJson();

        expect(json['reviewer_id'], 'user-abc');
        expect(json['seller_id'], 'user-xyz');
        expect(json['listing_id'], 'listing-001');
        expect(json['swap_proposal_id'], 'proposal-001');
        expect(json['rating'], 5);
        expect(json['communication_rating'], 5);
        expect(json['condition_rating'], 4);
        expect(json['speed_rating'], 5);
        expect(json['review'], 'Excellent!');
        // toJson does not include id, created_at, or is_swap
        // (is_swap is set by the database trigger when swap_proposal_id is present)
        expect(json.containsKey('id'), isFalse);
        expect(json.containsKey('created_at'), isFalse);
        expect(json.containsKey('is_swap'), isFalse);
      });

      test('omits null optional fields from JSON', () {
        const review = Review(
          id: 'review-002',
          reviewerId: 'user-abc',
          sellerId: 'user-xyz',
          listingId: 'listing-002',
          rating: 3,
          createdAt: '2026-03-21T12:00:00Z',
        );

        final json = review.toJson();

        expect(json['listing_id'], 'listing-002');
        expect(json.containsKey('swap_proposal_id'), isFalse);
        expect(json.containsKey('communication_rating'), isFalse);
        expect(json.containsKey('condition_rating'), isFalse);
        expect(json.containsKey('speed_rating'), isFalse);
        expect(json['review'], isNull); // explicitly written as null, not omitted
      });
    });
  });
}
