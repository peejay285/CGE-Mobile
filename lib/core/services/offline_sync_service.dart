import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Offline action queue backed by Hive.
///
/// When the device is offline, actions are queued locally. As soon as
/// connectivity is restored the queue is drained automatically.
/// Conflict resolution: server-wins (last write wins).
class OfflineSyncService {
  OfflineSyncService._();

  static const String _boxName = 'offline_queue';
  static late Box<Map> _box;
  static StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  static bool _processing = false;

  /// Open the queue box and start listening for connectivity changes.
  /// Call once during app startup after [Hive.initFlutter].
  static Future<void> initialize() async {
    _box = await Hive.openBox<Map>(_boxName);
    debugPrint(
      '[OfflineSyncService] Initialized — ${_box.length} pending actions',
    );

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) {
        debugPrint('[OfflineSyncService] Back online — processing queue');
        processQueue();
      }
    });
  }

  /// Number of actions waiting to be synced.
  static int get pendingCount => _box.length;

  /// Add an action to the offline queue.
  ///
  /// [type] identifies the operation (e.g. 'create_booking', 'send_message').
  /// [data] is a JSON-serializable map with the action payload.
  static Future<void> queueAction(
    String type,
    Map<String, dynamic> data,
  ) async {
    final id =
        '${DateTime.now().toUtc().millisecondsSinceEpoch}_${_box.length}';
    final action = {
      'id': id,
      'type': type,
      'data': data,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'retryCount': 0,
    };
    await _box.put(id, action);
    debugPrint(
      '[OfflineSyncService] Queued action: $type ($id) — ${_box.length} pending',
    );
  }

  /// Process every queued action sequentially.
  ///
  /// Skips execution if already processing or if the device is offline.
  static Future<void> processQueue() async {
    if (_processing) return;
    if (_box.isEmpty) return;

    // Verify we are actually online before draining.
    final results = await Connectivity().checkConnectivity();
    final online = results.any((r) => r != ConnectivityResult.none);
    if (!online) return;

    _processing = true;
    debugPrint('[OfflineSyncService] Processing ${_box.length} queued actions');

    // Snapshot the keys so we can iterate safely while deleting.
    final keys = List<dynamic>.from(_box.keys);

    for (final key in keys) {
      final action = _box.get(key);
      if (action == null) continue;

      final type = action['type'] as String;
      final data = Map<String, dynamic>.from(action['data'] as Map);
      final retryCount = (action['retryCount'] as int?) ?? 0;

      try {
        await _executeAction(type, data);
        await _box.delete(key);
        debugPrint('[OfflineSyncService] Completed: $type ($key)');
      } catch (e) {
        debugPrint('[OfflineSyncService] Failed: $type ($key) — $e');

        if (e is UnsupportedError) {
          // Never pretend an unimplemented action was synchronized. Leave it
          // queued until a real executor is added or the user clears it.
          continue;
        }

        if (retryCount >= 3) {
          // Give up after 3 retries to avoid blocking the queue.
          debugPrint(
            '[OfflineSyncService] Dropping action after 3 retries: $type ($key)',
          );
          await _box.delete(key);
        } else {
          // Increment retry count and leave in queue.
          action['retryCount'] = retryCount + 1;
          await _box.put(key, action);
        }
      }
    }

    _processing = false;
    debugPrint(
      '[OfflineSyncService] Queue processing complete — ${_box.length} remaining',
    );
  }

  /// Remove all queued actions.
  static Future<void> clearQueue() async {
    await _box.clear();
    debugPrint('[OfflineSyncService] Queue cleared');
  }

  /// Route an action to the appropriate repository / service call.
  ///
  /// Add new cases here as features are built out.
  static Future<void> _executeAction(
    String type,
    Map<String, dynamic> data,
  ) async {
    switch (type) {
      case 'create_booking':
      case 'send_message':
      case 'toggle_like':
      case 'create_post':
      case 'update_profile':
        throw UnsupportedError(
          'Offline action "$type" does not have a safe server executor yet',
        );
      default:
        throw UnsupportedError('Unknown offline action type: $type');
    }
  }

  /// Tear down the connectivity listener. Call on app shutdown if needed.
  static Future<void> dispose() async {
    await _connectivitySub?.cancel();
    _connectivitySub = null;
  }
}
