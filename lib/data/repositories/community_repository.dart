import 'package:supabase_flutter/supabase_flutter.dart';
import '../remote/supabase_config.dart';
import '../models/community_post.dart';

class CommunityRepository {
  final _client = SupabaseConfig.client;

  /// Fetch posts with filters
  Future<List<CommunityPost>> getPosts({
    String? topic,
    String sortBy = 'created_at',
    bool ascending = false,
    int limit = 15,
    int offset = 0,
  }) async {
    var query = _client
        .from('community_posts')
        .select('*, profiles!author_id(id, full_name, avatar_url, gamertag)');

    if (topic != null && topic != 'All') {
      query = query.eq('topic', topic);
    }

    final response = await query
        .order('is_pinned', ascending: false) // pinned first
        .order(sortBy, ascending: ascending)
        .range(offset, offset + limit - 1);

    return (response as List).map((e) => CommunityPost.fromJson(e)).toList();
  }

  /// Create a post
  Future<CommunityPost> createPost({
    required String content,
    String? imageUrl,
    String? topic,
    List<String>? mentions,
    List<String>? hashtags,
  }) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final data = {
      'author_id': user.id,
      'content': content,
      'image_url': imageUrl,
      'topic': topic,
      'mentions': mentions,
      'hashtags': hashtags,
    };

    final response =
        await _client.from('community_posts').insert(data).select().single();
    return CommunityPost.fromJson(response);
  }

  /// Toggle like
  Future<bool> toggleLike(String postId) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final existing = await _client
        .from('post_likes')
        .select('id')
        .eq('post_id', postId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (existing != null) {
      await _client.from('post_likes').delete().eq('id', existing['id']);
      return false;
    } else {
      await _client.from('post_likes').insert({
        'post_id': postId,
        'user_id': user.id,
      });
      return true;
    }
  }

  /// Get comments for a post
  Future<List<PostComment>> getComments(String postId) async {
    final response = await _client
        .from('post_comments')
        .select('*, profiles!author_id(id, full_name, avatar_url, gamertag)')
        .eq('post_id', postId)
        .order('created_at');

    return (response as List).map((e) => PostComment.fromJson(e)).toList();
  }

  /// Add a comment
  Future<PostComment> addComment({
    required String postId,
    required String content,
  }) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final response = await _client.from('post_comments').insert({
      'post_id': postId,
      'author_id': user.id,
      'content': content,
    }).select().single();

    return PostComment.fromJson(response);
  }

  /// Toggle bookmark
  Future<bool> toggleBookmark(String postId) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final existing = await _client
        .from('post_bookmarks')
        .select('id')
        .eq('post_id', postId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (existing != null) {
      await _client.from('post_bookmarks').delete().eq('id', existing['id']);
      return false;
    } else {
      await _client.from('post_bookmarks').insert({
        'post_id': postId,
        'user_id': user.id,
      });
      return true;
    }
  }

  /// Subscribe to real-time post changes
  RealtimeChannel subscribeToPosts(void Function(dynamic) onInsert) {
    return _client
        .channel('community-posts')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'community_posts',
          callback: (payload) => onInsert(payload.newRecord),
        )
        .subscribe();
  }

  /// Upload community image
  Future<String> uploadImage(String fileName, List<int> bytes) async {
    final path = 'posts/$fileName';
    await _client.storage
        .from('community-images')
        .uploadBinary(path, bytes as dynamic);
    return _client.storage.from('community-images').getPublicUrl(path);
  }
}
