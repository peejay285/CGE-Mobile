import '../remote/supabase_config.dart';
import '../models/profile.dart';

class AuthRepository {
  final _client = SupabaseConfig.client;

  /// Get current user's profile from the profiles table
  Future<Profile?> getProfile() async {
    final user = SupabaseConfig.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return Profile.fromJson(response);
  }

  /// Update profile fields
  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? gamertag,
    String? bio,
    String? favouriteGame,
    String? avatarUrl,
    String? fcmToken,
  }) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) return;

    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (phone != null) updates['phone'] = phone;
    if (gamertag != null) updates['gamertag'] = gamertag;
    if (bio != null) updates['bio'] = bio;
    if (favouriteGame != null) updates['favourite_game'] = favouriteGame;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (fcmToken != null) updates['fcm_token'] = fcmToken;

    if (updates.isNotEmpty) {
      await _client.from('profiles').update(updates).eq('id', user.id);
    }
  }

  /// Upload avatar image to Supabase Storage
  Future<String> uploadAvatar(String filePath, List<int> bytes) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final path = 'avatars/${user.id}/$filePath';
    await _client.storage.from('avatars').uploadBinary(path, bytes as dynamic);
    return _client.storage.from('avatars').getPublicUrl(path);
  }
}
