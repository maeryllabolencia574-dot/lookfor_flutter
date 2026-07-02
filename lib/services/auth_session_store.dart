import 'package:shared_preferences/shared_preferences.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.isAdmin,
    this.email,
  });

  final String accessToken;
  final bool isAdmin;
  final String? email;
}

class AuthSessionStore {
  static const String _accessTokenKey = 'auth_access_token';
  static const String _isAdminKey = 'auth_is_admin';
  static const String _emailKey = 'auth_email';

  static Future<void> save({
    required String accessToken,
    required bool isAdmin,
    String? email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setBool(_isAdminKey, isAdmin);

    final normalizedEmail = email?.trim();
    if (normalizedEmail != null && normalizedEmail.isNotEmpty) {
      await prefs.setString(_emailKey, normalizedEmail);
    }
  }

  static Future<AuthSession?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_accessTokenKey);

    if (token == null || token.isEmpty) {
      return null;
    }

    return AuthSession(
      accessToken: token,
      isAdmin: prefs.getBool(_isAdminKey) ?? false,
      email: prefs.getString(_emailKey),
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_isAdminKey);
    await prefs.remove(_emailKey);
  }
}
