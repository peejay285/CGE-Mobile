import '../remote/supabase_config.dart';
import '../models/event.dart';

class EventsRepository {
  final _client = SupabaseConfig.client;

  /// Fetch events with optional type filter
  Future<List<Event>> getEvents({String? type}) async {
    var query = _client.from('events').select();

    if (type != null && type != 'All') {
      query = query.eq('type', type);
    }

    final response = await query.order('date', ascending: true);
    return (response as List).map((e) => Event.fromJson(e)).toList();
  }

  /// Get single event
  Future<Event?> getEventById(int id) async {
    final response = await _client
        .from('events')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Event.fromJson(response);
  }

  /// Register for an event
  Future<void> register(int eventId) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _client.from('event_registrations').insert({
      'event_id': eventId,
      'user_id': user.id,
    });
  }

  /// Unregister from an event
  Future<void> unregister(int eventId) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _client
        .from('event_registrations')
        .delete()
        .eq('event_id', eventId)
        .eq('user_id', user.id);
  }
}
