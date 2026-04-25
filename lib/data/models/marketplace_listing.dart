import 'profile.dart';

class MarketplaceListing {
  final String id;
  final String sellerId;
  final String title;
  final int? price;
  final String condition;
  final String category;
  final String? description;
  final List<String> images;
  final String listingType; // sell, swap, sell_or_swap
  final String? swapFor;
  final List<String> swapForTags;
  final int? buyoutPrice;
  final String? location;
  final String? locationState;
  final String? locationCity;
  final int viewsCount;
  final int savesCount;
  final bool userHasSaved;
  final String status; // active, sold, archived
  final String createdAt;
  // Joined fields
  final Profile? seller;

  const MarketplaceListing({
    required this.id,
    required this.sellerId,
    required this.title,
    this.price,
    required this.condition,
    required this.category,
    this.description,
    this.images = const [],
    required this.listingType,
    this.swapFor,
    this.swapForTags = const [],
    this.buyoutPrice,
    this.location,
    this.locationState,
    this.locationCity,
    this.viewsCount = 0,
    this.savesCount = 0,
    this.userHasSaved = false,
    required this.status,
    required this.createdAt,
    this.seller,
  });

  factory MarketplaceListing.fromJson(Map<String, dynamic> json) =>
      MarketplaceListing(
        id: json['id'] as String,
        sellerId: json['user_id'] as String,
        title: json['title'] as String,
        price: json['price'] as int?,
        condition: json['condition'] as String,
        category: json['category'] as String,
        description: json['description'] as String?,
        images: (json['images'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        listingType: json['listing_type'] as String,
        swapFor: json['swap_for'] as String?,
        swapForTags: (json['swap_for_tags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        buyoutPrice: json['buyout_price'] as int?,
        location: json['location'] as String?,
        locationState: json['location_state'] as String?,
        locationCity: json['location_city'] as String?,
        viewsCount: json['views_count'] as int? ?? 0,
        savesCount: json['saves_count'] as int? ?? 0,
        userHasSaved: json['user_has_saved'] as bool? ?? false,
        status: json['status'] as String? ?? 'active',
        createdAt: json['created_at'] as String,
        seller: json['seller'] != null
            ? Profile.fromJson(json['seller'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'user_id': sellerId,
        'title': title,
        'price': price,
        'condition': condition,
        'category': category,
        'description': description,
        'images': images,
        'listing_type': listingType,
        'swap_for': swapFor,
        'swap_for_tags': swapForTags,
        'buyout_price': buyoutPrice,
        'location': location,
        'location_state': locationState,
        'location_city': locationCity,
        'status': status,
      };
}

class SwapProposal {
  final String id;
  final String listingId;
  final String proposerId;
  final String offeredListingId;
  final String? message;
  final String status; // pending, accepted, declined
  final String createdAt;
  final Profile? proposer;
  final MarketplaceListing? offeredListing;

  const SwapProposal({
    required this.id,
    required this.listingId,
    required this.proposerId,
    required this.offeredListingId,
    this.message,
    required this.status,
    required this.createdAt,
    this.proposer,
    this.offeredListing,
  });

  factory SwapProposal.fromJson(Map<String, dynamic> json) => SwapProposal(
        id: json['id'] as String,
        listingId: json['listing_id'] as String,
        proposerId: json['proposer_id'] as String,
        offeredListingId: json['offered_listing_id'] as String,
        message: json['message'] as String?,
        status: json['status'] as String,
        createdAt: json['created_at'] as String,
      );
}
