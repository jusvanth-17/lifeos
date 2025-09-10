import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '../services/supabase_auth_service.dart';
import '../services/session_manager.dart';
import '../services/user_service.dart';
import '../services/power_sync_service.dart';
import '../services/session_sync_service.dart';
import '../models/user.dart' as app_models;

// Auth mode enum
enum AuthMode { login, register }

// Auth state class
class AppAuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final bool isSigningIn;
  final bool isRegistering;
  final app_models.User? user;
  final String? error;
  final AuthMode mode;

  const AppAuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.isSigningIn = false,
    this.isRegistering = false,
    this.user,
    this.error,
    this.mode = AuthMode.login,
  });

  AppAuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    bool? isSigningIn,
    bool? isRegistering,
    app_models.User? user,
    String? error,
    AuthMode? mode,
  }) {
    return AppAuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      isSigningIn: isSigningIn ?? this.isSigningIn,
      isRegistering: isRegistering ?? this.isRegistering,
      user: user ?? this.user,
      error: error ?? this.error,
      mode: mode ?? this.mode,
    );
  }
}

// Auth notifier
class AuthNotifier extends StateNotifier<AppAuthState> {
  final SupabaseAuthService _authService;

  AuthNotifier(this._authService) : super(const AppAuthState()) {
    // Listen to auth state changes
    _authService.authStateChanges.listen((supabaseAuthState) {
      _handleAuthStateChange(supabaseAuthState);
    });

    // Initialize cross-tab session synchronization
    SessionSyncService.instance.initialize();

    // Listen for session changes from other tabs
    SessionSyncService.instance.sessionChanges.listen((event) {
      print('🔄 AuthProvider: Cross-tab session event: $event');

      if (event == 'session_updated' || event == 'session_sync_trigger') {
        // Another tab logged in or triggered a sync - refresh our session
        print('✅ AuthProvider: Refreshing session due to cross-tab event');
        loadSavedSession();
      } else if (event == 'session_cleared') {
        // Another tab logged out - clear our session
        print('🚪 AuthProvider: Clearing session due to cross-tab logout');
        state = const AppAuthState();
      }
    });
  }

  /// Sign in with email and password
  Future<void> signInWithPassword(String email, String password) async {
    state = state.copyWith(isSigningIn: true, error: null);

    try {
      await _authService.signInWithPassword(email, password);
      // State will be updated by the auth state change listener
      state = state.copyWith(isSigningIn: false);
    } catch (e) {
      state = state.copyWith(
        isSigningIn: false,
        error: _getErrorMessage(e),
      );
    }
  }

  /// Sign up with email and password
  Future<void> signUpWithPassword(
      String email, String password, String displayName) async {
    state = state.copyWith(isRegistering: true, error: null);

    try {
      await _authService.signUpWithPassword(email, password, displayName);
      // State will be updated by the auth state change listener
      state = state.copyWith(isRegistering: false);
    } catch (e) {
      state = state.copyWith(
        isRegistering: false,
        error: _getErrorMessage(e),
      );
    }
  }

  /// Reset password for email
  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authService.resetPassword(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
    }
  }

  /// Switch between login and register modes
  void switchAuthMode(AuthMode mode) {
    state = state.copyWith(mode: mode, error: null);
  }

  /// Handle auth state changes from Supabase
  void _handleAuthStateChange(AuthState supabaseAuthState) async {
    print('🔄 AuthProvider: Auth state change detected');
    print('📍 Event: ${supabaseAuthState.event}');
    print(
        '👤 Session: ${supabaseAuthState.session != null ? "Present" : "Null"}');

    if (supabaseAuthState.event == AuthChangeEvent.signedIn) {
      print('✅ AuthProvider: User signed in');
      final user = _authService.getCurrentUser();
      if (user != null) {
        print('👤 AuthProvider: User data retrieved - ${user.email}');
        state = state.copyWith(
          isAuthenticated: true,
          user: user,
          isLoading: false,
          error: null,
        );
        print('✅ AuthProvider: State updated - isAuthenticated: true');

        // Save session to local storage
        await SessionManager.instance.saveSession(
          isLoggedIn: true,
          user: user,
        );
        print('💾 AuthProvider: Session saved to local storage');

        // Sync user to local database for chat functionality
        try {
          await UserService.instance.syncUserFromAuth(
            supabaseId: user.id,
            email: user.email,
            displayName: user.displayName,
            avatarUrl: user.avatarUrl,
          );
          print('✅ User synced to local database: ${user.email}');
        } catch (e) {
          print('❌ Error syncing user to local database: $e');
        }

        // Initialize PowerSync for this user (handles new devices and offline periods)
        try {
          await PowerSyncService.instance.initialize();
          await PowerSyncService.instance.connectWithSupabaseAuth();
          print('✅ PowerSync initialized for user: ${user.email}');
        } catch (e) {
          print('❌ Error initializing PowerSync for user: $e');
          // Don't fail auth if sync fails - app should still work offline
        }
      } else {
        print('❌ AuthProvider: User data is null despite signedIn event');
      }
    } else if (supabaseAuthState.event == AuthChangeEvent.signedOut) {
      print('🚪 AuthProvider: User signed out');
      state = const AppAuthState();
      await SessionManager.instance.clearSession();
      print('✅ AuthProvider: State cleared and session removed');
    } else {
      print('ℹ️ AuthProvider: Other auth event - ${supabaseAuthState.event}');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      // State will be updated by the auth state change listener
    } catch (e) {
      state = state.copyWith(error: _getErrorMessage(e));
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Load saved session on app startup
  Future<void> loadSavedSession() async {
    state = state.copyWith(isLoading: true);

    try {
      print('🔄 AuthProvider: Loading saved session...');

      // Check if we have a current user from Supabase
      // Supabase handles session recovery automatically on initialization
      final user = _authService.getCurrentUser();
      final currentSession = _authService.currentSession;

      print('📍 Current session exists: ${currentSession != null}');
      print('📍 Current user exists: ${user != null}');

      if (currentSession != null && user != null) {
        print('✅ AuthProvider: Found valid Supabase session - ${user.email}');

        // Validate session is not expired
        final sessionValid = _authService.hasValidSession();
        print('📍 Session validity check: $sessionValid');

        if (sessionValid) {
          // Try to refresh session if it's close to expiring
          await _authService.ensureValidSession();
          state = state.copyWith(
            isAuthenticated: true,
            isLoading: false,
            user: user,
            error: null,
          );

          // Update local session for offline fallback
          await SessionManager.instance.saveSession(
            isLoggedIn: true,
            user: user,
          );
          print('💾 AuthProvider: Session saved to local storage');

          // Sync user to local database for chat functionality
          try {
            await UserService.instance.syncUserFromAuth(
              supabaseId: user.id,
              email: user.email,
              displayName: user.displayName,
              avatarUrl: user.avatarUrl,
            );
            print(
                '✅ User synced to local database on app startup: ${user.email}');
          } catch (e) {
            print('❌ Error syncing user to local database on startup: $e');
          }

          print('✅ AuthProvider: Session loaded successfully');
          return;
        } else {
          print('⚠️ AuthProvider: Session validation failed - session expired');
        }
      }

      // No valid Supabase session found - check local storage as fallback
      print(
          '⚠️ AuthProvider: No valid Supabase session found, checking local storage...');
      final isLocallyLoggedIn = await SessionManager.instance.isLoggedIn();
      final localUser = await SessionManager.instance.getSavedUser();

      if (isLocallyLoggedIn && localUser != null) {
        print('📱 AuthProvider: Found stale local session - clearing it');
        // Clear the stale local session since Supabase session is invalid
        await SessionManager.instance.clearSession();
      }

      print(
          '🚪 AuthProvider: No valid session found - user needs to authenticate');
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        user: null,
        error: null,
      );
    } catch (e) {
      print('❌ AuthProvider: Error loading saved session: $e');
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        user: null,
        error: null,
      );
    }
  }

  /// Save current route for session restoration
  Future<void> saveCurrentRoute(String route) async {
    await SessionManager.instance.saveCurrentRoute(route);
  }

  /// Get last saved route
  Future<String?> getLastRoute() async {
    return await SessionManager.instance.getLastRoute();
  }

  /// Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    if (error is AuthException) {
      switch (error.message.toLowerCase()) {
        case 'invalid email':
        case 'invalid_email':
          return 'Please enter a valid email address.';
        case 'email not confirmed':
        case 'email_not_confirmed':
          return 'Please check your email and click the confirmation link.';
        case 'invalid credentials':
        case 'invalid_credentials':
          return 'Invalid email or password.';
        case 'email rate limit exceeded':
        case 'rate_limit_exceeded':
          return 'Too many requests. Please wait before trying again.';
        case 'network error':
        case 'network_error':
          return 'Network error. Please check your connection and try again.';
        case 'signup_disabled':
          return 'New user registration is currently disabled.';
        case 'email_address_invalid':
          return 'The email address format is invalid.';
        case 'weak_password':
          return 'Password is too weak. Please choose a stronger password.';
        default:
          // Return the original message if no specific mapping found
          return error.message.isNotEmpty
              ? error.message
              : 'Authentication failed. Please try again.';
      }
    }

    // Handle network and other exceptions
    if (error.toString().contains('SocketException') ||
        error.toString().contains('TimeoutException')) {
      return 'Network error. Please check your connection and try again.';
    }

    if (error.toString().contains('FormatException')) {
      return 'Invalid response format. Please try again.';
    }

    return 'An unexpected error occurred. Please try again.';
  }
}

// Providers
final supabaseAuthServiceProvider = Provider<SupabaseAuthService>((ref) {
  return SupabaseAuthService.instance;
});

final authProvider = StateNotifierProvider<AuthNotifier, AppAuthState>((ref) {
  final authService = ref.watch(supabaseAuthServiceProvider);
  return AuthNotifier(authService);
});
