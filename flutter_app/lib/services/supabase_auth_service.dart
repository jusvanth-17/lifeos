import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_models;

class SupabaseAuthService {
  static SupabaseAuthService? _instance;
  static SupabaseAuthService get instance =>
      _instance ??= SupabaseAuthService._();

  SupabaseAuthService._();

  SupabaseClient get _supabase => Supabase.instance.client;

  /// Sign in with email and password
  Future<void> signInWithPassword(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<void> signUpWithPassword(
      String email, String password, String displayName) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Reset password for email
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  /// Get current authenticated user
  app_models.User? getCurrentUser() {
    final supabaseUser = _supabase.auth.currentUser;
    if (supabaseUser == null) return null;

    return app_models.User(
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
      displayName: supabaseUser.userMetadata?['display_name'] ??
          supabaseUser.email?.split('@').first ??
          'User',
      avatarUrl: supabaseUser.userMetadata?['avatar_url'],
    );
  }

  /// Check if user is currently authenticated
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  /// Get current session
  Session? get currentSession => _supabase.auth.currentSession;

  /// Sign out current user
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Check if there's a valid session available
  /// Supabase handles session recovery automatically on initialization
  bool hasValidSession() {
    final session = currentSession;
    if (session == null) return false;

    // Check if session is expired
    final expiresAt =
        DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
    final now = DateTime.now();

    return now.isBefore(expiresAt);
  }

  /// Refresh the current session
  Future<AuthResponse?> refreshSession() async {
    try {
      final response = await _supabase.auth.refreshSession();
      return response;
    } catch (e) {
      print('Error refreshing session: $e');
      return null;
    }
  }

  /// Check if session is expired and refresh if needed
  Future<bool> ensureValidSession() async {
    final session = currentSession;
    if (session == null) return false;

    // Check if session is close to expiring (within 5 minutes)
    final expiresAt =
        DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
    final now = DateTime.now();
    final timeUntilExpiry = expiresAt.difference(now);

    if (timeUntilExpiry.inMinutes <= 5) {
      print('Session expiring soon, refreshing...');
      final refreshResponse = await refreshSession();
      return refreshResponse?.session != null;
    }

    return true;
  }

  /// Update user profile
  Future<UserResponse> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{};

    if (displayName != null) {
      updates['display_name'] = displayName;
    }

    if (avatarUrl != null) {
      updates['avatar_url'] = avatarUrl;
    }

    return await _supabase.auth.updateUser(
      UserAttributes(data: updates),
    );
  }

  /// Get user profile from database (if you have a profiles table)
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }
}
