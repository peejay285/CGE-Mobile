import '../remote/supabase_config.dart';
import '../models/marketplace_listing.dart';

class MarketplaceRepository {
  final _client = SupabaseConfig.client;

  Future<List<MarketplaceListing>> _hydrateListings(
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return [];

    final sellerIds = rows
        .map((row) => (row['user_id'] ?? row['seller_id']) as String?)
        .whereType<String>()
        .toSet()
        .toList();
    final profilesById = <String, Map<String, dynamic>>{};

    if (sellerIds.isNotEmpty) {
      final profileRows = await _client
          .from('profiles')
          .select(
            'id, full_name, phone, avatar_url, gamertag, bio, favourite_game, '
            'points, wins, losses, team_id, follower_count, following_count, '
            'tournament_count, achievement_count, total_listings, total_sales, '
            'total_swaps, avg_rating, rating_count, trust_level, location_state, '
            'location_city, location_lat, location_lng, is_admin, is_id_verified, '
            'id_verified_at, premium_tier, premium_expires_at, created_at',
          )
          .inFilter('id', sellerIds);
      for (final raw in (profileRows as List)) {
        final profile = Map<String, dynamic>.from(raw as Map);
        profilesById[profile['id'] as String] = profile;
      }
    }

    final currentUserId = SupabaseConfig.currentUser?.id;
    return rows.map((row) {
      final sellerId = (row['user_id'] ?? row['seller_id']) as String;
      final saves = (row['listing_saves'] as List?) ?? const [];
      return MarketplaceListing.fromJson({
        ...row,
        'seller': profilesById[sellerId],
        'saves_count': saves.length,
        'user_has_saved':
            currentUserId != null &&
            saves.any(
              (raw) => (raw as Map)['user_id']?.toString() == currentUserId,
            ),
      });
    }).toList();
  }

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
        .select('*, listing_saves(user_id)')
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

    return _hydrateListings(
      (response as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(),
    );
  }

  /// Get a single listing by ID
  Future<MarketplaceListing?> getListingById(String id) async {
    final response = await _client
        .from('marketplace_listings')
        .select('*, listing_saves(user_id)')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    final hydrated = await _hydrateListings([
      Map<String, dynamic>.from(response),
    ]);
    return hydrated.isEmpty ? null : hydrated.first;
  }

  /// Create a new listing
  Future<MarketplaceListing> createListing(Map<String, dynamic> data) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('Not authenticated');

    data['user_id'] = user.id;
    final response = await _client
        .from('marketplace_listings')
        .insert(data)
        .select('*, listing_saves(user_id)')
        .single();

    final hydrated = await _hydrateListings([
      Map<String, dynamic>.from(response),
    ]);
    return hydrated.single;
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
        .select('*, listing_saves(user_id)')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return _hydrateListings(
      (response as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(),
    );
  }

  /// Get saved listings
  Future<List<MarketplaceListing>> getSavedListings() async {
    final user = SupabaseConfig.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('listing_saves')
        .select('marketplace_listings(*, listing_saves(user_id))')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    final rows = (response as List)
        .map(
          (raw) => Map<String, dynamic>.from(
            (raw as Map)['marketplace_listings'] as Map,
          ),
        )
        .toList();
    return _hydrateListings(rows);
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
          '*, offered_listing:marketplace_listings!offered_listing_id(id, title, images, condition, category, price, buyout_price), target_listing:marketplace_listings!listing_id(id, title, images, condition, category, price, buyout_price, user_id), assist_payments:swap_assist_payments(*)',
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
          '*, proposer:profiles!proposer_id(id, full_name, avatar_url, gamertag), offered_listing:marketplace_listings!offered_listing_id(id, title, images, condition, category, price, buyout_price), target_listing:marketplace_listings!listing_id(id, title, images, condition, category, price, buyout_price), assist_payments:swap_assist_payments(*)',
        )
        .inFilter('listing_id', ids)
        .order('created_at', ascending: false);
    return response as List;
  }

  /// Tier 3 — listing owner accepts a proposal.
  Future<void> acceptSwapProposal(String proposalId) async {
    await _client
        .from('swap_proposals')
        .update({
          'status': 'accepted',
          'accepted_at': DateTime.now().toIso8601String(),
        })
        .eq('id', proposalId);
  }

  /// Tier 3 — listing owner declines a proposal.
  Future<void> declineSwapProposal(String proposalId) async {
    await _client
        .from('swap_proposals')
        .update({
          'status': 'declined',
          'declined_at': DateTime.now().toIso8601String(),
        })
        .eq('id', proposalId);
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
    await _client
        .from('swap_proposals')
        .update({'${side}_received_at': DateTime.now().toIso8601String()})
        .eq('id', proposalId);
  }

  /// Tier 3 — cancel a non-terminal swap.
  Future<void> cancelSwap({required String proposalId, String? reason}) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('Not authenticated');
    await _client
        .from('swap_proposals')
        .update({
          'cancelled_at': DateTime.now().toIso8601String(),
          'cancelled_by': user.id,
          if (reason != null && reason.isNotEmpty)
            'cancellation_reason': reason,
        })
        .eq('id', proposalId);
  }

  /// Tier 3 — flag a swap for moderation review.
  Future<void> disputeSwap({
    required String proposalId,
    required String reason,
  }) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('Not authenticated');
    await _client
        .from('swap_proposals')
        .update({
          'disputed_at': DateTime.now().toIso8601String(),
          'disputed_by': user.id,
          'dispute_reason': reason,
        })
        .eq('id', proposalId);
  }

  Future<void> requestSwapAssistance(String proposalId) async {
    await _client.rpc(
      'request_swap_assistance',
      params: {'p_proposal_id': proposalId},
    );
  }

  Future<void> coverSwapAssistWithPremium(String proposalId) async {
    await _client.rpc(
      'cover_swap_assist_with_premium',
      params: {'p_proposal_id': proposalId},
    );
  }

  Future<void> completeSwapAssistance(String proposalId) async {
    await _client.rpc(
      'complete_swap_assistance',
      params: {'p_proposal_id': proposalId},
    );
  }

  Future<void> cancelSwapAssistance(String proposalId) async {
    await _client.rpc(
      'cancel_swap_assistance',
      params: {'p_proposal_id': proposalId},
    );
  }

  Future<List<SwapAssistPayment>> getSwapAssistPayments(
    String proposalId,
  ) async {
    final response = await _client
        .from('swap_assist_payments')
        .select()
        .eq('proposal_id', proposalId);
    return (response as List)
        .map(
          (raw) =>
              SwapAssistPayment.fromJson(Map<String, dynamic>.from(raw as Map)),
        )
        .toList();
  }

  Future<int> getMyAssistCredits() async {
    final user = SupabaseConfig.currentUser;
    if (user == null) return 0;
    final response = await _client.rpc(
      'swap_assist_premium_credits_remaining',
      params: {'p_user_id': user.id},
    );
    return (response as num?)?.toInt() ?? 0;
  }

  /// Upload listing image
  Future<String> uploadImage(String fileName, List<int> bytes) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final path = '${user.id}/$fileName';
    await _client.storage
        .from('marketplace-images')
        .uploadBinary(path, bytes as dynamic);
    return _client.storage.from('marketplace-images').getPublicUrl(path);
  }
}
