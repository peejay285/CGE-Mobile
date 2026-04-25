import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase client configuration
class SupabaseConfig {
  SupabaseConfig._();

  /// Initialize Supabase — call in main() before runApp()
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: 'https://uornrrryktpigignayre.supabase.co',
      ),
      anonKey: const String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVvcm5ycnJ5a3RwaWdpZ25heXJlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE0NTkxOTUsImV4cCI6MjA4NzAzNTE5NX0.2ARe8AN2Ek8ZChwStN0CCYLKmFglX46fO-3hS7PUryI',
      ),
    );
  }

  /// Get the Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;

  /// Get the current authenticated user
  static User? get currentUser => client.auth.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;
}
