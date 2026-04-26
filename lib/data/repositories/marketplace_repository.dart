import '../remote/supabase_config.dart';
import '../models/marketplace_listing.dart';

class MarketplaceRepository {
  final _client = SupabaseConfig.client;

  /// Fetch listings with filters
  Future<List<MarketplaceListing>> getListings({
    String? category,
    String? listingType,
    String? search,
    String? locationState,
    String sortBy = 'created_at',
    bool ascending = false,
    int limit = 20,
    int offset = 0,
  }) async {
    var query = _client
        .from('marketplace_listings')
        .select('*, seller:profiles!user_id(id, full_name, avatar_url, gamertag, trust_level, is_id_verified, premium_tier)')
        .eq('status', 'active');

    if (category != null) query = query.eq('category', category);
    if (listingType != null) query = query.eq('listing_type', listingType);
    if (search != null && search.isNotEmpty) {
      query = query.ilike('title', '%$search%');
    }
    if (locationState != null) {
      query = query.eq('location_state', locationState);
    }

    final response = await query
        .order(sortBy, ascending: ascending)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((e) => MarketplaceListing.fromJson(e))
        .toList();
  }

  /// Get a single listing by ID
  Future<MarketplaceListing?> getListingById(String id) async {
    final response = await _client
        .from('marketplace_listings')
        .select('*, seller:profiles!user_id(id, full_name, avatar_url, gamertag, trust_level, is_id_verified, premium_tier)')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return MarketplaceListing.fromJson(response);
  }

  /// Create a new listing
  Future<MarketplaceListing> createListing(
      Map<String, dynamic> data) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('Not authenticated');

    data['user_id'] = user.id;
    final response = await _client
        .from('marketplace_listings')
        .insert(data)
        .select()
        .single();

    return MarketplaceListing.fromJson(response);
  }

  /// Toggle save/unsave a listing
  Future<bool> toggleSave(String listingId) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Check if already saved
    final existing = await _client
        .from('listing_saves')
        .select('id')
        .eq('listing_id', listingId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (existing != null) {
      await _client.from('listing_saves').delete().eq('id', existing['id']);
      return false; // unsaved
    } else {
      await _client.from('listing_saves').insert({
        'listing_id': listingId,
        'user_id': user.id,
      });
      return true; // saved
    }
  }

  /// Record a view
  Future<void> recordView(String listingId) async {
    await _client.rpc('increment_views', params: {'listing_id': listingId});
  }

  /// Get user's own listings
  Future<List<MarketplaceListing>> getMyListings() async {
    final user = SupabaseConfig.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('marketplace_listings')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => MarketplaceListing.fromJson(e))
        .toList();
  }

  /// Get saved listings
  Future<List<MarketplaceListing>> getSavedListings() async {
    final user = SupabaseConfig.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('listing_saves')
        .select('marketplace_listings(*)')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) =>
            MarketplaceListing.fromJson(e['marketplace_listings'] as Map<String, dynamic>))
        .toList();
  }

  /// Create a swap proposal
  Future<void> createSwapProposal({
    required String listingId,
    required String offeredListingId,
    String? message,
  }) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _client.from('swap_proposals').insert({
      'listing_id': listingId,
      'proposer_id': user.id,
      'offered_listing_id': offeredListingId,
      'message': message,
    });
  }

  /// Tier 3 — proposals the current user has *sent* (proposer side).
  Future<List<dynamic>> getMyOutgoingProposals() async {
    final user = SupabaseConfig.currentUser;
    if (user == null) return [];
    final response = await _client
        .from('swap_proposals')
        .select(
          '*, offered_listing:marketplace_listings!offered_listing_id(id, title, images, condition, category), target_listing:marketplace_listings!listing_id(id, title, images, condition, category, user_id)',
        )
        .eq('proposer_id', user.id)
        .order('created_at', ascending: false);
    return response as List;
  }

  /// Tier 3 — proposals on listings the current user *owns* (owner side).
  Future<List<dynamic>> getMyIncomingProposals() async {
    final user = SupabaseConfig.currentUser;
    if (user == null) return [];
    final myListings = await _client
        .from('marketplace_listings')
        .select('id')
        .eq('user_id', user.id);
    final ids = (myListings as List)
        .map((l) => l['id'] as String)
        .toList(growable: false);
    if (ids.isEmpty) return [];
    final response = await _client
        .from('swap_proposals')
        .select(
          '*, proposer:profiles!proposer_id(id, full_name, avatar_url, gamertag), offered_listing:marketplace_listings!offered_listing_id(id, title, images, condition, category), target_listing:marketplace_listings!listing_id(id, title, images, condition, category)',
        )
        .inFilter('listing_id', ids)
        .order('created_at', ascending: false);
    return response as List;
  }

  /// Tier 3 — listing owner accepts a proposal.
  Future<void> acceptSwapProposal(String proposalId) async {
    await _client.from('swap_proposals').update({
      'status': 'accepted',
      'accepted_at': DateTime.now().toIso8601String(),
    }).eq('id', proposalId);
  }

  /// Tier 3 — listing owner declines a proposal.
  Future<void> declineSwapProposal(String proposalId) async {
    await _client.from('swap_proposals').update({
      'status': 'declined',
      'declined_at': DateTime.now().toIso8601String(),
    }).eq('id', proposalId);
  }

  /// Tier 3 — either party marks their own outgoing shipment as sent.
  /// Pass `side: 'proposer'` if the caller is the proposer, otherwise `'owner'`.
  Future<void> markSwapShipped({
    required String proposalId,
    required String side, // 'proposer' | 'owner'
    String? tracking,
  }) async {
    final patch = <String, dynamic>{
      '${side}_shipped_at': DateTime.now().toIso8601String(),
      if (tracking != null && tracking.isNotEmpty) '${side}_tracking': tracking,
    };
    await _client.from('swap_proposals').update(patch).eq('id', proposalId);
  }

  /// Tier 3 — either party confirms receipt of the other party's item.
  Future<void> markSwapReceived({
    required String proposalId,
    required String side, // 'proposer' | 'owner'
  }) async {
    await _client.from('swap_proposals').update({
      '${side}_received_at': DateTime.now().toIso8601String(),
    }).eq('id', proposalId);
  }

  /// Tier 3 — cancel a non-terminal swap.
  Future<void> cancelSwap({
    required String proposalId,
    String? reason,
  }) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('Not authenticated');
    await _client.from('swap_proposals').update({
      'cancelled_at': DateTime.now().toIso8601String(),
      'cancelled_by': user.id,
      if (reason != null && reason.isNotEmpty) 'cancellation_reason': reason,
    }).eq('id', proposalId);
  }

  /// Tier 3 — flag a swap for moderation review.
  Future<void> disputeSwap({
    required String proposalId,
    required String reason,
  }) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('Not authenticated');
    await _client.from('swap_proposals').update({
      'disputed_at': DateTime.now().toIso8601String(),
      'disputed_by': user.id,
      'dispute_reason': reason,
    }).eq('id', proposalId);
  }

  /// Upload listing image
  Future<String> uploadImage(String fileName, List<int> bytes) async {
    final path = 'listings/$fileName';
    await _client.storage
        .from('marketplace-images')
        .uploadBinary(path, bytes as dynamic);
    return _client.storage.from('marketplace-images').getPublicUrl(path);
  }
}
