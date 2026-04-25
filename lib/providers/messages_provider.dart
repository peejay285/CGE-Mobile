import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/messages_repository.dart';
import '../data/models/conversation.dart';

final messagesRepositoryProvider =
    Provider((_) => MessagesRepository());

final conversationsProvider =
    FutureProvider<List<Conversation>>((ref) async {
  return ref.read(messagesRepositoryProvider).getConversations();
});

final messagesProvider =
    FutureProvider.family<List<Message>, String>(
        (ref, conversationId) async {
  return ref.read(messagesRepositoryProvider).getMessages(conversationId);
});

final unreadCountProvider = FutureProvider<int>((ref) async {
  return ref.read(messagesRepositoryProvider).getUnreadCount();
});
