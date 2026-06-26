import 'profile.dart';

class Conversation {
  final String id;
  final String? listingId;
  final String buyerId;
  final String sellerId;
  final String createdAt;
  final String updatedAt;
  final Message? lastMessage;
  final int unreadCount;
  // Joined
  final Profile? otherUser;
  final String? listingTitle;
  final String? listingImage;

  const Conversation({
    required this.id,
    this.listingId,
    required this.buyerId,
    required this.sellerId,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.unreadCount = 0,
    this.otherUser,
    this.listingTitle,
    this.listingImage,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final listing = json['listing'] as Map<String, dynamic>?;
    final images = listing?['images'] as List?;
    return Conversation(
      id: json['id'] as String,
      listingId: json['listing_id'] as String?,
      buyerId: json['buyer_id'] as String,
      sellerId: json['seller_id'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      lastMessage: json['last_message'] is Map<String, dynamic>
          ? Message.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      otherUser: json['other_user'] is Map<String, dynamic>
          ? Profile.fromJson(json['other_user'] as Map<String, dynamic>)
          : null,
      listingTitle: listing?['title'] as String?,
      listingImage: images != null && images.isNotEmpty
          ? images.first as String?
          : null,
    );
  }
}

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final bool isRead;
  final String createdAt;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.isRead = false,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'] as String,
    conversationId: json['conversation_id'] as String,
    senderId: json['sender_id'] as String,
    content: json['content'] as String,
    isRead: json['is_read'] as bool? ?? false,
    createdAt: json['created_at'] as String,
  );

  Map<String, dynamic> toJson() => {
    'conversation_id': conversationId,
    'sender_id': senderId,
    'content': content,
  };
}
