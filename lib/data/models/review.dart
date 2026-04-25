import 'profile.dart';

class Review {
  final String id;
  final String reviewerId;
  final String sellerId;
  final String listingId;
  final String? swapProposalId;
  final int rating;
  final int? communicationRating;
  final int? conditionRating;
  final int? speedRating;
  final String? review;
  final bool isSwap;
  final String createdAt;
  final Profile? reviewer;

  const Review({
    required this.id,
    required this.reviewerId,
    required this.sellerId,
    required this.listingId,
    this.swapProposalId,
    required this.rating,
    this.communicationRating,
    this.conditionRating,
    this.speedRating,
    this.review,
    this.isSwap = false,
    required this.createdAt,
    this.reviewer,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] as String,
        reviewerId: json['reviewer_id'] as String,
        sellerId: json['seller_id'] as String,
        listingId: json['listing_id'] as String,
        swapProposalId: json['swap_proposal_id'] as String?,
        rating: json['rating'] as int,
        communicationRating: json['communication_rating'] as int?,
        conditionRating: json['condition_rating'] as int?,
        speedRating: json['speed_rating'] as int?,
        review: json['review'] as String?,
        isSwap: json['is_swap'] as bool? ?? false,
        createdAt: json['created_at'] as String,
        reviewer: json['reviewer'] != null
            ? Profile.fromJson(json['reviewer'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'reviewer_id': reviewerId,
        'seller_id': sellerId,
        'listing_id': listingId,
        if (swapProposalId != null) 'swap_proposal_id': swapProposalId,
        'rating': rating,
        if (communicationRating != null)
          'communication_rating': communicationRating,
        if (conditionRating != null) 'condition_rating': conditionRating,
        if (speedRating != null) 'speed_rating': speedRating,
        'review': review,
      };
}
