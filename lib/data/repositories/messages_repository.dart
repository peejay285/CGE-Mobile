import 'package:supabase_flutter/supabase_flutter.dart';
import '../remote/supabase_config.dart';
import '../models/conversation.dart';

class MessagesRepository {
  final _client = SupabaseConfig.client;

  /// Get all conversations for current user
  Future<List<Conversation>> getConversations() async {
    final user = SupabaseConfig.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('conversations')
        .select()
        .or('buyer_id.eq.${user.id},seller_id.eq.${user.id}')
        .order('updated_at', ascending: false);

    return (response as List).map((e) => Conversation.fromJson(e)).toList();
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

    final response = await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': user.id,
      'content': content,
    }).select().single();

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
    if (existing != null) return Conversation.fromJson(existing);

    // Create new
    final response = await _client.from('conversations').insert({
      'buyer_id': user.id,
      'seller_id': sellerId,
      'listing_id': listingId,
    }).select().single();

    return Conversation.fromJson(response);
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
