import 'dart:ui';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../data/remote/supabase_config.dart';

/// Handles FCM push notifications and local notification display
class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'cge_lounge_channel',
    'CGE App Notifications',
    description: 'Notifications from CGE App',
    importance: Importance.high,
  );

  /// Initialize notification handling
  static Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Create Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Initialize local notifications
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Get and store FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      await _storeFcmToken(token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_storeFcmToken);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    // Handle background message taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // Check if app was opened from a notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }
  }

  /// Store FCM token in user's profile on Supabase
  static Future<void> _storeFcmToken(String token) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) return;

    try {
      await SupabaseConfig.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', user.id);
    } catch (_) {
      // Silently fail — token will be stored on next auth
    }
  }

  /// Show a local notification when a message arrives in foreground
  static void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF00F0FF),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data['route'],
    );
  }

  /// Handle notification tap (from background)
  static void _handleMessageTap(RemoteMessage message) {
    final route = message.data['route'];
    if (route != null) {
      // GoRouter will handle deep linking via the route
      // This will be wired up in the router's redirect logic
    }
  }

  /// Handle local notification tap
  static void _onNotificationTap(NotificationResponse response) {
    final route = response.payload;
    if (route != null) {
      // Navigate to the route
    }
  }

  /// Subscribe to a topic (e.g., 'tournaments', 'community')
  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from a topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages if needed
}
