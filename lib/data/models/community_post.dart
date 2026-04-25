import 'profile.dart';

class CommunityPost {
  final String id;
  final String authorId;
  final String content;
  final String? imageUrl;
  final bool isPinned;
  final String? topic;
  final List<String>? mediaUrls;
  final String? mediaType;
  final String? embedUrl;
  final bool? hasPoll;
  final List<String>? mentions;
  final List<String>? hashtags;
  final int likesCount;
  final int commentsCount;
  final bool userHasLiked;
  final int? shareCount;
  final bool? bookmarked;
  final String createdAt;
  // Joined
  final Profile? author;

  const CommunityPost({
    required this.id,
    required this.authorId,
    required this.content,
    this.imageUrl,
    this.isPinned = false,
    this.topic,
    this.mediaUrls,
    this.mediaType,
    this.embedUrl,
    this.hasPoll,
    this.mentions,
    this.hashtags,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.userHasLiked = false,
    this.shareCount,
    this.bookmarked,
    required this.createdAt,
    this.author,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) => CommunityPost(
        id: json['id'] as String,
        authorId: json['author_id'] as String,
        content: json['content'] as String,
        imageUrl: json['image_url'] as String?,
        isPinned: json['is_pinned'] as bool? ?? false,
        topic: json['topic'] as String?,
        mediaUrls: (json['media_urls'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
        mediaType: json['media_type'] as String?,
        embedUrl: json['embed_url'] as String?,
        hasPoll: json['has_poll'] as bool?,
        mentions: (json['mentions'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
        hashtags: (json['hashtags'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
        likesCount: json['likes_count'] as int? ?? 0,
        commentsCount: json['comments_count'] as int? ?? 0,
        userHasLiked: json['user_has_liked'] as bool? ?? false,
        shareCount: json['share_count'] as int?,
        bookmarked: json['bookmarked'] as bool?,
        createdAt: json['created_at'] as String,
        author: json['profiles'] != null
            ? Profile.fromJson(json['profiles'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'author_id': authorId,
        'content': content,
        'image_url': imageUrl,
        'topic': topic,
        'mentions': mentions,
        'hashtags': hashtags,
      };
}

class PostComment {
  final String id;
  final String postId;
  final String authorId;
  final String content;
  final String createdAt;
  final Profile? author;

  const PostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.content,
    required this.createdAt,
    this.author,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) => PostComment(
        id: json['id'] as String,
        postId: json['post_id'] as String,
        authorId: json['author_id'] as String,
        content: json['content'] as String,
        createdAt: json['created_at'] as String,
        author: json['profiles'] != null
            ? Profile.fromJson(json['profiles'] as Map<String, dynamic>)
            : null,
      );
}
