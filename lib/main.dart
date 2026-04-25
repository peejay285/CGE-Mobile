import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'data/remote/supabase_config.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/cache_service.dart';
import 'core/services/offline_sync_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Dark status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFF111113),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  try {
    // Initialize Hive (local key-value storage)
    await Hive.initFlutter();

    // Open Hive boxes for caching
    await CacheService.initialize();
    await OfflineSyncService.initialize();
  } catch (e) {
    print('Hive init error: $e');
  }

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Pass Flutter errors to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  } catch (e) {
    print('Firebase init error: $e');
  }

  try {
    // Initialize Supabase
    await SupabaseConfig.initialize();
  } catch (e) {
    print('Supabase init error: $e');
  }

  try {
    // Initialize push notifications
    await PushNotificationService.initialize();
  } catch (e) {
    print('Push notification init error: $e');
  }

  runApp(
    const ProviderScope(
      child: CgeLoungeApp(),
    ),
  );
}
