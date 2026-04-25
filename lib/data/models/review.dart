import 'profile.dart';

class Review {
  final String id;
  final String reviewerId;
  final String sellerId;
  final String? listingId;
  final int rating; // 1-5
  final String? comment;
  final String type; // buyer_to_seller, seller_to_buyer
  final String createdAt;
  final Profile? reviewer;

  const Review({
    required this.id,
    required this.reviewerId,
    required this.sellerId,
    this.listingId,
    required this.rating,
    this.comment,
    required this.type,
    required this.createdAt,
    this.reviewer,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] as String,
        reviewerId: json['reviewer_id'] as String,
        sellerId: json['seller_id'] as String,
        listingId: json['listing_id'] as String?,
        rating: json['rating'] as int,
        comment: json['comment'] as String?,
        type: json['type'] as String? ?? 'buyer_to_seller',
        createdAt: json['created_at'] as String,
        reviewer: json['reviewer'] != null
            ? Profile.fromJson(json['reviewer'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'reviewer_id': reviewerId,
        'seller_id': sellerId,
        'listing_id': listingId,
        'rating': rating,
        'comment': comment,
        'type': type,
      };
}
