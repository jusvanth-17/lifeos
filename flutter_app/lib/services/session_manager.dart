import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class SessionManager {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserData = 'user_data';
  static const String _keyLastRoute = 'last_route';

  static SessionManager? _instance;
  SharedPreferences? _prefs;

  SessionManager._();

  static SessionManager get instance {
    _instance ??= SessionManager._();
    return _instance!;
  }

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Session state methods
  Future<void> saveSession({
    required bool isLoggedIn,
    User? user,
    String? lastRoute,
  }) async {
    await initialize();

    await _prefs!.setBool(_keyIsLoggedIn, isLoggedIn);

    if (user != null) {
      final userJson = jsonEncode({
        'id': user.id,
        'email': user.email,
        'displayName': user.displayName,
      });
      await _prefs!.setString(_keyUserData, userJson);
    }

    if (lastRoute != null) {
      await _prefs!.setString(_keyLastRoute, lastRoute);
    }
  }

  Future<bool> isLoggedIn() async {
    await initialize();
    return _prefs!.getBool(_keyIsLoggedIn) ?? false;
  }

  Future<User?> getSavedUser() async {
    await initialize();
    final userDataString = _prefs!.getString(_keyUserData);

    if (userDataString == null) return null;

    try {
      final userMap = jsonDecode(userDataString) as Map<String, dynamic>;
      return User(
        id: userMap['id'] as String,
        email: userMap['email'] as String,
        displayName: userMap['displayName'] as String,
      );
    } catch (e) {
      // If there's an error parsing the user data, return null
      return null;
    }
  }

  Future<String?> getLastRoute() async {
    await initialize();
    return _prefs!.getString(_keyLastRoute);
  }

  Future<void> clearSession() async {
    await initialize();
    await _prefs!.remove(_keyIsLoggedIn);
    await _prefs!.remove(_keyUserData);
    await _prefs!.remove(_keyLastRoute);
  }

  // Helper method to save current route
  Future<void> saveCurrentRoute(String route) async {
    await initialize();
    await _prefs!.setString(_keyLastRoute, route);
  }

  // Method to check if session is valid (dummy implementation)
  Future<bool> isSessionValid() async {
    await initialize();
    final isLoggedIn = await this.isLoggedIn();
    final user = await getSavedUser();

    // Simple validation: session is valid if user is logged in and user data exists
    return isLoggedIn && user != null;
  }
}
