import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/remote/supabase_config.dart';

/// Auth state — holds the current user (or null if signed out)
final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  late final StreamSubscription<AuthState> _subscription;

  AuthNotifier() : super(const AsyncValue.loading()) {
    // Listen to auth state changes
    _subscription = SupabaseConfig.client.auth.onAuthStateChange.listen((data) {
      state = AsyncValue.data(data.session?.user);
    });

    // Set initial state
    state = AsyncValue.data(SupabaseConfig.currentUser);
  }

  /// Sign up with email and password
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? gamertag,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await SupabaseConfig.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          if (phone != null) 'phone': phone, // ignore: use_null_aware_elements
          if (gamertag != null) 'gamertag': gamertag, // ignore: use_null_aware_elements
        },
      );
      state = AsyncValue.data(response.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Sign in with email and password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await SupabaseConfig.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      state = AsyncValue.data(response.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Sign in with social provider
  Future<void> signInWithProvider(OAuthProvider provider) async {
    try {
      await SupabaseConfig.client.auth.signInWithOAuth(provider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    await SupabaseConfig.client.auth.resetPasswordForEmail(email);
  }

  /// Sign out
  Future<void> signOut() async {
    await SupabaseConfig.client.auth.signOut();
    state = const AsyncValue.data(null);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
