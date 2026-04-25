import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/events_repository.dart';
import '../data/models/event.dart';

final eventsRepositoryProvider =
    Provider((_) => EventsRepository());

final eventsProvider =
    FutureProvider.family<List<Event>, String?>((ref, type) async {
  return ref.read(eventsRepositoryProvider).getEvents(type: type);
});

final eventDetailProvider =
    FutureProvider.family<Event?, int>((ref, id) async {
  return ref.read(eventsRepositoryProvider).getEventById(id);
});
