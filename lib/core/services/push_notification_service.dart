import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles background messages when the app is terminated or in background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No-op for now — just ensures messages are delivered
  debugPrint('Background message: ${message.messageId}');
}

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static FirebaseAnalytics get analytics => _analytics;

  static Future<void> initialize() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission (iOS requires explicit permission, Android auto-grants)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // Get FCM token
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveFcmToken(token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_saveFcmToken);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle when user taps a notification (app was in background)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a terminated state via notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    }

    debugPrint(
      'Push notifications initialized: ${settings.authorizationStatus}',
    );
  }

  /// Save FCM token to user's profile in Supabase
  static Future<void> _saveFcmToken(String token) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({'fcm_token': token})
            .eq('id', user.id);
      }
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }

  /// Handle messages when app is in foreground
  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
    // TODO: Show in-app notification banner
  }

  /// Handle notification tap (deep link to relevant screen)
  static void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;

    // Route based on notification type
    // These will be handled by GoRouter when navigation context is available
    switch (type) {
      case 'booking_confirmed':
      case 'booking_reminder':
        // Navigate to booking detail
        break;
      case 'swap_proposal':
      case 'listing_sold':
        // Navigate to marketplace listing
        break;
      case 'tournament_starting':
      case 'match_ready':
        // Navigate to tournament
        break;
      case 'new_message':
        // Navigate to conversation
        break;
      case 'post_reaction':
      case 'post_comment':
        // Navigate to community post
        break;
    }
  }

  /// Log a custom analytics event
  static Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  /// Set user ID for analytics
  static Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }
}
