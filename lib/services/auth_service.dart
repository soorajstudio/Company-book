import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  // Internal email domain for username-based login
  static const String _domain = 'companybook.local';

  String _emailFromUsername(String username) {
    return '${username.toLowerCase().trim()}@$_domain';
  }

  // Check if username is already taken
  Future<bool> isUsernameTaken(String username) async {
    final result = await supabase
        .from('profiles')
        .select('username')
        .eq('username', username.trim())
        .maybeSingle();

    return result != null;
  }

  // Register a new sole company member account
  Future<void> register(
    String username,
    String password, {
    String? fullName,
    String? phone,
  }) async {
    final cleanUsername = username.trim();

    final taken = await isUsernameTaken(cleanUsername);
    if (taken) {
      throw Exception('Username "$cleanUsername" is already in use.');
    }

    final fakeEmail = _emailFromUsername(cleanUsername);

    final response = await supabase.auth.signUp(
      email: fakeEmail,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Registration failed. Please check your credentials.');
    }

    // Create the profile row
    await supabase.from('profiles').insert({
      'id': response.user!.id,
      'username': cleanUsername,
      'full_name': fullName?.trim(),
      'phone': phone?.trim(),
      'is_admin': false,
    });
  }

  // Admin user creation helper
  Future<void> adminCreateUser(
    String username,
    String password, {
    bool isAdmin = false,
    String? fullName,
  }) async {
    final cleanUsername = username.trim();

    final taken = await isUsernameTaken(cleanUsername);
    if (taken) {
      throw Exception('Username already taken');
    }

    final fakeEmail = _emailFromUsername(cleanUsername);

    final response = await supabase.auth.signUp(
      email: fakeEmail,
      password: password,
    );

    if (response.user == null) {
      throw Exception('User creation failed');
    }

    await supabase.from('profiles').insert({
      'id': response.user!.id,
      'username': cleanUsername,
      'full_name': fullName?.trim(),
      'is_admin': isAdmin,
    });
  }

  // Log in with username + password
  Future<void> login(String username, String password) async {
    final fakeEmail = _emailFromUsername(username.trim());

    await supabase.auth.signInWithPassword(
      email: fakeEmail,
      password: password,
    );
  }

  // Get current user's profile
  Future<Map<String, dynamic>?> getProfile() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final result = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    return result;
  }

  // Device label for session tracking
  Future<String> getDeviceInfo() async {
    if (kIsWeb) return 'Web Browser';

    final plugin = DeviceInfoPlugin();
    try {
      final androidInfo = await _tryAndroidInfo(plugin);
      if (androidInfo != null) return androidInfo;

      final iosInfo = await _tryIosInfo(plugin);
      if (iosInfo != null) return iosInfo;

      final windowsInfo = await _tryWindowsInfo(plugin);
      if (windowsInfo != null) return windowsInfo;
    } catch (_) {}
    return 'Authorized Device';
  }

  Future<String?> _tryAndroidInfo(DeviceInfoPlugin plugin) async {
    try {
      final info = await plugin.androidInfo;
      return '${info.brand} ${info.model}';
    } catch (_) {
      return null;
    }
  }

  Future<String?> _tryIosInfo(DeviceInfoPlugin plugin) async {
    try {
      final info = await plugin.iosInfo;
      return '${info.name} ${info.model}';
    } catch (_) {
      return null;
    }
  }

  Future<String?> _tryWindowsInfo(DeviceInfoPlugin plugin) async {
    try {
      final info = await plugin.windowsInfo;
      return 'Windows PC (${info.computerName})';
    } catch (_) {
      return null;
    }
  }

  // Record login session
  Future<void> recordLoginSession() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      final device = await getDeviceInfo();

      await supabase.from('login_sessions').insert({
        'user_id': userId,
        'device_info': device,
        'is_active': true,
      });
    } catch (_) {}
  }

  // Sign out
  Future<void> signOut() async {
    final userId = supabase.auth.currentUser?.id;

    if (userId != null) {
      try {
        await supabase
            .from('login_sessions')
            .update({
              'is_active': false,
              'logged_out_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('is_active', true);
      } catch (_) {}
    }

    await supabase.auth.signOut();
  }

  bool get isLoggedIn => supabase.auth.currentSession != null;
}
