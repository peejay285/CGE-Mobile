import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Monitors network connectivity and exposes online/offline state
final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, bool>((ref) {
  return ConnectivityNotifier();
});

class ConnectivityNotifier extends StateNotifier<bool> {
  late final StreamSubscription<List<ConnectivityResult>> _subscription;

  /// Stream that external services (e.g. OfflineSyncService) can listen to
  /// for connectivity changes without depending on Riverpod.
  static final StreamController<bool> _onlineController =
      StreamController<bool>.broadcast();

  /// Broadcast stream that emits `true` when online, `false` when offline.
  static Stream<bool> get onlineStream => _onlineController.stream;

  /// Synchronous check of the last known connectivity state.
  static bool _lastKnownState = true;

  /// Returns the last known online/offline state.
  static bool get isOnline => _lastKnownState;

  ConnectivityNotifier() : super(true) {
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      state = online;
      _lastKnownState = online;
      _onlineController.add(online);
    });

    // Check initial state
    _checkInitial();
  }

  Future<void> _checkInitial() async {
    final results = await Connectivity().checkConnectivity();
    final online = results.any((r) => r != ConnectivityResult.none);
    state = online;
    _lastKnownState = online;
    _onlineController.add(online);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
