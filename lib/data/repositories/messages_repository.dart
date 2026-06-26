import 'package:supabase_flutter/supabase_flutter.dart';
import '../remote/supabase_config.dart';
import '../models/conversation.dart';

class MessagesRepository {
  final _client = SupabaseConfig.client;

  Future<List<Conversation>> _hydrateConversations(
    List<Map<String, dynamic>> rows,
  ) async {
    final user = SupabaseConfig.currentUser;
    if (user == null || rows.isEmpty) return [];

    final otherIds = rows
        .map(
          (row) => row['buyer_id'] == user.id
              ? row['seller_id'] as String
              : row['buyer_id'] as String,
        )
        .toSet()
        .toList();
    final listingIds = rows
        .map((row) => row['listing_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    final conversationIds = rows.map((row) => row['id'] as String).toList();

    final profilesById = <String, Map<String, dynamic>>{};
    if (otherIds.isNotEmpty) {
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
          .inFilter('id', otherIds);
      for (final raw in (profileRows as List)) {
        final profile = Map<String, dynamic>.from(raw as Map);
        profilesById[profile['id'] as String] = profile;
      }
    }

    final listingsById = <String, Map<String, dynamic>>{};
    if (listingIds.isNotEmpty) {
      final listingRows = await _client
          .from('marketplace_listings')
          .select('id, title, images, price, listing_type, status')
          .inFilter('id', listingIds);
      for (final raw in (listingRows as List)) {
        final listing = Map<String, dynamic>.from(raw as Map);
        listingsById[listing['id'] as String] = listing;
      }
    }

    final messagesByConversation = <String, List<Map<String, dynamic>>>{};
    final messageRows = await _client
        .from('messages')
        .select()
        .inFilter('conversation_id', conversationIds)
        .order('created_at', ascending: false);
    for (final raw in (messageRows as List)) {
      final message = Map<String, dynamic>.from(raw as Map);
      final conversationId = message['conversation_id'] as String;
      messagesByConversation.putIfAbsent(conversationId, () => []).add(message);
    }

    return rows.map((row) {
      final otherId = row['buyer_id'] == user.id
          ? row['seller_id'] as String
          : row['buyer_id'] as String;
      final messages = messagesByConversation[row['id']] ?? const [];
      final unread = messages.where(
        (message) =>
            message['sender_id'] != user.id && message['is_read'] != true,
      );
      return Conversation.fromJson({
        ...row,
        'other_user': profilesById[otherId],
        'listing': listingsById[row['listing_id']],
        'last_message': messages.isEmpty ? null : messages.first,
        'unread_count': unread.length,
      });
    }).toList();
  }

  /// Get all conversations for current user
  Future<List<Conversation>> getConversations() async {
    final user = SupabaseConfig.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('conversations')
        .select()
        .or('buyer_id.eq.${user.id},seller_id.eq.${user.id}')
        .order('updated_at', ascending: false);

    return _hydrateConversations(
      (response as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(),
    );
  }

  /// Get messages for a conversation
  Future<List<Message>> getMessages(String conversationId) async {
    final response = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at');

    return (response as List).map((e) => Message.fromJson(e)).toList();
  }

  /// Send a message
  Future<Message> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final response = await _client
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': user.id,
          'content': content,
        })
        .select()
        .single();

    // Update conversation timestamp
    await _client
        .from('conversations')
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', conversationId);

    return Message.fromJson(response);
  }

  /// Mark messages as read
  Future<void> markAsRead(String conversationId) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) return;

    await _client
        .from('messages')
        .update({'is_read': true})
        .eq('conversation_id', conversationId)
        .neq('sender_id', user.id)
        .eq('is_read', false);
  }

  /// Get unread count across all conversations
  Future<int> getUnreadCount() async {
    final user = SupabaseConfig.currentUser;
    if (user == null) return 0;

    final response = await _client
        .from('messages')
        .select('id')
        .neq('sender_id', user.id)
        .eq('is_read', false);

    return (response as List).length;
  }

  /// Create or get existing conversation for a marketplace listing
  Future<Conversation> getOrCreateConversation({
    required String sellerId,
    String? listingId,
  }) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Check for existing conversation
    var query = _client
        .from('conversations')
        .select()
        .eq('buyer_id', user.id)
        .eq('seller_id', sellerId);

    if (listingId != null) {
      query = query.eq('listing_id', listingId);
    }

    final existing = await query.maybeSingle();
    if (existing != null) {
      final hydrated = await _hydrateConversations([
        Map<String, dynamic>.from(existing),
      ]);
      return hydrated.single;
    }

    // Create new
    final response = await _client
        .from('conversations')
        .insert({
          'buyer_id': user.id,
          'seller_id': sellerId,
          'listing_id': listingId,
        })
        .select()
        .single();

    final hydrated = await _hydrateConversations([
      Map<String, dynamic>.from(response),
    ]);
    return hydrated.single;
  }

  /// Subscribe to new messages in a conversation
  RealtimeChannel subscribeToMessages(
    String conversationId,
    void Function(dynamic) onNewMessage,
  ) {
    return _client
        .channel('messages-$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) => onNewMessage(payload.newRecord),
        )
        .subscribe();
  }

  /// Subscribe to global unread count changes
  RealtimeChannel subscribeToUnread(void Function() onUpdate) {
    return _client
        .channel('global-messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (_) => onUpdate(),
        )
        .subscribe();
  }
}
