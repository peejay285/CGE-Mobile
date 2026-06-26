import 'package:supabase_flutter/supabase_flutter.dart';
import '../remote/supabase_config.dart';
import '../models/community_post.dart';

class CommunityRepository {
  final _client = SupabaseConfig.client;

  Future<Map<String, Map<String, dynamic>>> _profilesFor(
    Iterable<String> ids,
  ) async {
    final uniqueIds = ids.toSet().toList();
    if (uniqueIds.isEmpty) return {};
    final response = await _client
        .from('profiles')
        .select(
          'id, full_name, phone, avatar_url, gamertag, bio, favourite_game, '
          'points, wins, losses, team_id, follower_count, following_count, '
          'tournament_count, achievement_count, total_listings, total_sales, '
          'total_swaps, avg_rating, rating_count, trust_level, location_state, '
          'location_city, location_lat, location_lng, is_admin, is_id_verified, '
          'id_verified_at, premium_tier, premium_expires_at, created_at',
        )
        .inFilter('id', uniqueIds);
    return {
      for (final raw in (response as List))
        (raw as Map)['id'] as String: Map<String, dynamic>.from(raw),
    };
  }

  Future<List<CommunityPost>> _hydratePosts(
    List<Map<String, dynamic>> rows,
  ) async {
    final profiles = await _profilesFor(
      rows.map((row) => row['author_id'] as String),
    );
    final userId = SupabaseConfig.currentUser?.id;
    return rows.map((row) {
      final likes = (row['post_likes'] as List?) ?? const [];
      final bookmarks = (row['post_bookmarks'] as List?) ?? const [];
      return CommunityPost.fromJson({
        ...row,
        'author': profiles[row['author_id']],
        'user_has_liked':
            userId != null &&
            likes.any((raw) => (raw as Map)['user_id'] == userId),
        'bookmarked':
            userId != null &&
            bookmarks.any((raw) => (raw as Map)['user_id'] == userId),
      });
    }).toList();
  }

  /// Fetch posts with filters
  Future<List<CommunityPost>> getPosts({
    String? topic,
    String? search,
    String sortBy = 'created_at',
    bool ascending = false,
    int limit = 15,
    int offset = 0,
  }) async {
    var query = _client
        .from('community_posts')
        .select('*, post_likes(user_id), post_bookmarks(user_id)');

    if (topic != null && topic != 'All') {
      query = query.eq('topic', topic);
    }
    final term = search?.trim();
    if (term != null && term.isNotEmpty) {
      final escaped = term
          .replaceAll(RegExp(r'[,()]'), ' ')
          .replaceAll('%', r'\%')
          .replaceAll('_', r'\_');
      query = query.or('content.ilike.%$escaped%,topic.ilike.%$escaped%');
    }

    final response = await query
        .order('is_pinned', ascending: false) // pinned first
        .order(sortBy, ascending: ascending)
        .range(offset, offset + limit - 1);

    return _hydratePosts(
      (response as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(),
    );
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

    final response = await _client
        .from('community_posts')
        .insert(data)
        .select('*, post_likes(user_id), post_bookmarks(user_id)')
        .single();
    final hydrated = await _hydratePosts([Map<String, dynamic>.from(response)]);
    return hydrated.single;
  }

  /// Toggle like
  Future<bool> toggleLike(String postId) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final existing = await _client
        .from('post_likes')
        .select('post_id')
        .eq('post_id', postId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', user.id);
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
        .select()
        .eq('post_id', postId)
        .order('created_at');

    final rows = (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    final profiles = await _profilesFor(
      rows.map((row) => row['author_id'] as String),
    );
    return rows
        .map(
          (row) => PostComment.fromJson({
            ...row,
            'author': profiles[row['author_id']],
          }),
        )
        .toList();
  }

  /// Add a comment
  Future<PostComment> addComment({
    required String postId,
    required String content,
  }) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final response = await _client
        .from('post_comments')
        .insert({'post_id': postId, 'author_id': user.id, 'content': content})
        .select()
        .single();

    final profiles = await _profilesFor([user.id]);
    return PostComment.fromJson({
      ...Map<String, dynamic>.from(response),
      'author': profiles[user.id],
    });
  }

  /// Toggle bookmark
  Future<bool> toggleBookmark(String postId) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final existing = await _client
        .from('post_bookmarks')
        .select('post_id')
        .eq('post_id', postId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('post_bookmarks')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', user.id);
      return false;
    } else {
      await _client.from('post_bookmarks').insert({
        'post_id': postId,
        'user_id': user.id,
      });
      return true;
    }
  }

  Future<void> reportPost({
    required String postId,
    required String reason,
    String? details,
  }) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('Not authenticated');
    await _client.from('post_reports').insert({
      'post_id': postId,
      'reporter_id': user.id,
      'reason': reason,
      'details': details?.trim().isEmpty == true ? null : details?.trim(),
    });
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
