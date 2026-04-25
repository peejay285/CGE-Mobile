import '../remote/supabase_config.dart';
import '../models/review.dart';
import '../models/profile.dart';

class ReviewRepository {
  final _client = SupabaseConfig.client;

  /// Get reviews for a seller
  Future<List<Review>> getSellerReviews(String sellerId) async {
    final response = await _client
        .from('seller_ratings')
        .select('*, reviewer:profiles!reviewer_id(*)')
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Review.fromJson(e)).toList();
  }

  /// Get a seller's profile with trust info
  Future<Profile?> getSellerProfile(String sellerId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', sellerId)
        .maybeSingle();

    if (response == null) return null;
    return Profile.fromJson(response);
  }

  /// Submit a review
  Future<Review> createReview({
    required String sellerId,
    required int rating,
    String? comment,
    String? listingId,
    String type = 'buyer_to_seller',
  }) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final data = {
      'reviewer_id': user.id,
      'seller_id': sellerId,
      'rating': rating,
      'comment': comment,
      'listing_id': listingId,
      'type': type,
    };

    final response = await _client
        .from('seller_ratings')
        .insert(data)
        .select('*, reviewer:profiles!reviewer_id(*)')
        .single();

    return Review.fromJson(response);
  }

  /// Check if current user has already reviewed this seller for a listing
  Future<bool> hasReviewed({
    required String sellerId,
    String? listingId,
  }) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) return false;

    var query = _client
        .from('seller_ratings')
        .select('id')
        .eq('reviewer_id', user.id)
        .eq('seller_id', sellerId);

    if (listingId != null) {
      query = query.eq('listing_id', listingId);
    }

    final response = await query;
    return (response as List).isNotEmpty;
  }
}
