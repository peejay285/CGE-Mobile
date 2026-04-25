import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/community_repository.dart';
import '../data/models/community_post.dart';

final communityRepositoryProvider =
    Provider((_) => CommunityRepository());

final communityPostsProvider = FutureProvider.family<List<CommunityPost>,
    Map<String, dynamic>>((ref, filters) async {
  return ref.read(communityRepositoryProvider).getPosts(
        topic: filters['topic'] as String?,
        sortBy: (filters['sortBy'] as String?) ?? 'created_at',
        ascending: (filters['ascending'] as bool?) ?? false,
        limit: (filters['limit'] as int?) ?? 15,
        offset: (filters['offset'] as int?) ?? 0,
      );
});

final postCommentsProvider =
    FutureProvider.family<List<PostComment>, String>((ref, postId) async {
  return ref.read(communityRepositoryProvider).getComments(postId);
});
