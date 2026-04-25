import 'package:hive_flutter/hive_flutter.dart';

/// Local cache layer using Hive for offline-first data access.
///
/// Each cached entry stores the data alongside a timestamp so stale
/// entries can be detected and evicted automatically.
class CacheService {
  CacheService._();

  static const List<String> _boxNames = [
    'bookings_cache',
    'listings_cache',
    'tournaments_cache',
    'posts_cache',
    'events_cache',
    'profile_cache',
  ];

  /// Default max age for cached entries (30 minutes).
  static const Duration defaultMaxAge = Duration(minutes: 30);

  /// Opens all cache boxes. Call once during app startup after [Hive.initFlutter].
  static Future<void> initialize() async {
    for (final name in _boxNames) {
      await Hive.openBox<Map>(name);
    }
    print('[CacheService] Initialized ${_boxNames.length} cache boxes');
  }

  /// Store [data] in [boxName] under [key] with the current timestamp.
  static Future<void> cacheData(
    String boxName,
    String key,
    dynamic data,
  ) async {
    final box = Hive.box<Map>(boxName);
    await box.put(key, {
      'data': data,
      'cachedAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Retrieve cached data for [key] from [boxName].
  ///
  /// Returns `null` if no entry exists or the entry is older than [maxAge].
  static dynamic getCachedData(
    String boxName,
    String key, {
    Duration? maxAge,
  }) {
    final box = Hive.box<Map>(boxName);
    final entry = box.get(key);
    if (entry == null) return null;

    final cachedAt = DateTime.tryParse(entry['cachedAt'] as String? ?? '');
    if (cachedAt == null) return null;

    final age = DateTime.now().toUtc().difference(cachedAt);
    if (age > (maxAge ?? defaultMaxAge)) {
      // Entry has expired — treat as cache miss.
      return null;
    }

    return entry['data'];
  }

  /// Clear every entry in the given [boxName].
  static Future<void> clearCache(String boxName) async {
    final box = Hive.box<Map>(boxName);
    await box.clear();
    print('[CacheService] Cleared $boxName');
  }

  /// Clear all cache boxes.
  static Future<void> clearAllCaches() async {
    for (final name in _boxNames) {
      if (Hive.isBoxOpen(name)) {
        await Hive.box<Map>(name).clear();
      }
    }
    print('[CacheService] All caches cleared');
  }
}
