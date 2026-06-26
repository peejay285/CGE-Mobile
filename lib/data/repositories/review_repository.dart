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

  /// Submit a review.
  ///
  /// `listingId` is required at the schema level. If `swapProposalId` is
  /// provided, the database trigger validates that the proposal exists, is
  /// in a terminal-success state, and that the reviewer + seller are the
  /// two parties to it. Skip `swapProposalId` for legacy purchase reviews.
  Future<Review> createReview({
    required String sellerId,
    required String listingId,
    required int rating,
    String? review,
    String? swapProposalId,
    int? communicationRating,
    int? conditionRating,
    int? speedRating,
  }) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final data = <String, dynamic>{
      'reviewer_id': user.id,
      'seller_id': sellerId,
      'listing_id': listingId,
      'rating': rating,
      'review': review,
      'swap_proposal_id': ?swapProposalId,
      'communication_rating': ?communicationRating,
      'condition_rating': ?conditionRating,
      'speed_rating': ?speedRating,
    };

    final response = await _client
        .from('seller_ratings')
        .insert(data)
        .select('*, reviewer:profiles!reviewer_id(*)')
        .single();

    return Review.fromJson(response);
  }

  /// Check if current user has already reviewed this listing.
  Future<bool> hasReviewed({
    required String sellerId,
    required String listingId,
  }) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) return false;

    final response = await _client
        .from('seller_ratings')
        .select('id')
        .eq('reviewer_id', user.id)
        .eq('seller_id', sellerId)
        .eq('listing_id', listingId);

    return (response as List).isNotEmpty;
  }
}
