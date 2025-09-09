import 'package:uuid/uuid.dart';
import '../models/user.dart';
import 'power_sync_service.dart';

class UserService {
  static UserService? _instance;
  static UserService get instance => _instance ??= UserService._();

  UserService._();

  final PowerSyncService _powerSync = PowerSyncService.instance;
  final Uuid _uuid = const Uuid();

  /// Create a new user
  Future<User?> createUser({
    required String email,
    required String displayName,
    String? avatarUrl,
  }) async {
    try {
      final userId = _uuid.v4();
      final now = DateTime.now();

      final userData = {
        'id': userId,
        'email': email,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      await _powerSync.insert('users', userData);

      return User(
        id: userId,
        email: email,
        displayName: displayName,
        avatarUrl: avatarUrl,
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      print('Error creating user: $e');
      return null;
    }
  }

  /// Get user by ID
  Future<User?> getUserById(String userId) async {
    try {
      final results = await _powerSync.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (results.isEmpty) return null;

      return _mapRowToUser(results.first);
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  /// Get user by email
  Future<User?> getUserByEmail(String email) async {
    try {
      final results = await _powerSync.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
        limit: 1,
      );

      if (results.isEmpty) return null;

      return _mapRowToUser(results.first);
    } catch (e) {
      print('Error getting user by email: $e');
      return null;
    }
  }

  /// Search users by name or email
  Future<List<User>> searchUsers(String query) async {
    try {
      final results = await _powerSync.query(
        'users',
        where: 'display_name LIKE ? OR email LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'display_name ASC',
        limit: 20,
      );

      return results.map((row) => _mapRowToUser(row)).toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  /// Sync user from Supabase auth to local database
  Future<User?> syncUserFromAuth({
    required String id,
    required String email,
    required String displayName,
    String? avatarUrl,
  }) async {
    try {
      // Check if user already exists
      final existingUser = await getUserById(id);

      if (existingUser != null) {
        // Update existing user
        final updates = <String, dynamic>{};
        bool needsUpdate = false;

        if (existingUser.email != email) {
          updates['email'] = email;
          needsUpdate = true;
        }
        if (existingUser.displayName != displayName) {
          updates['display_name'] = displayName;
          needsUpdate = true;
        }
        if (existingUser.avatarUrl != avatarUrl) {
          updates['avatar_url'] = avatarUrl;
          needsUpdate = true;
        }

        if (needsUpdate) {
          return await updateUser(id, updates);
        }
        return existingUser;
      } else {
        // Create new user
        final now = DateTime.now();
        final userData = {
          'id': id,
          'email': email,
          'display_name': displayName,
          'avatar_url': avatarUrl,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };

        await _powerSync.insert('users', userData);

        return User(
          id: id,
          email: email,
          displayName: displayName,
          avatarUrl: avatarUrl,
          createdAt: now,
          updatedAt: now,
        );
      }
    } catch (e) {
      print('Error syncing user from auth: $e');
      return null;
    }
  }

  /// Get all users (for admin purposes or user listing)
  Future<List<User>> getAllUsers({int limit = 50}) async {
    try {
      final results = await _powerSync.query(
        'users',
        orderBy: 'display_name ASC',
        limit: limit,
      );

      return results.map((row) => _mapRowToUser(row)).toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  /// Update user
  Future<User?> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      final updateData = Map<String, dynamic>.from(updates);
      updateData['updated_at'] = DateTime.now().toIso8601String();

      await _powerSync.update(
        'users',
        updateData,
        where: 'id = ?',
        whereArgs: [userId],
      );

      return await getUserById(userId);
    } catch (e) {
      print('Error updating user: $e');
      return null;
    }
  }

  /// Store WebAuthn credential
  Future<bool> storeWebAuthnCredential({
    required String userId,
    required String credentialId,
    required String publicKey,
    int counter = 0,
  }) async {
    try {
      final credId = _uuid.v4();
      final now = DateTime.now();

      final credentialData = {
        'id': credId,
        'user_id': userId,
        'credential_id': credentialId,
        'public_key': publicKey,
        'counter': counter,
        'created_at': now.toIso8601String(),
      };

      await _powerSync.insert('webauthn_credentials', credentialData);
      return true;
    } catch (e) {
      print('Error storing WebAuthn credential: $e');
      return false;
    }
  }

  /// Get WebAuthn credentials for user
  Future<List<Map<String, dynamic>>> getWebAuthnCredentials(
      String userId) async {
    try {
      return await _powerSync.query(
        'webauthn_credentials',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
    } catch (e) {
      print('Error getting WebAuthn credentials: $e');
      return [];
    }
  }

  /// Create user session
  Future<String?> createUserSession(String userId) async {
    try {
      final sessionId = _uuid.v4();
      final token = _uuid.v4();
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 30)); // 30 day expiry

      final sessionData = {
        'id': sessionId,
        'user_id': userId,
        'token': token,
        'expires_at': expiresAt.toIso8601String(),
        'created_at': now.toIso8601String(),
      };

      await _powerSync.insert('user_sessions', sessionData);
      return token;
    } catch (e) {
      print('Error creating user session: $e');
      return null;
    }
  }

  /// Get user by session token
  Future<User?> getUserBySessionToken(String token) async {
    try {
      final results = await _powerSync.execute('''
        SELECT u.* FROM users u
        JOIN user_sessions s ON u.id = s.user_id
        WHERE s.token = ? AND s.expires_at > ?
      ''', [token, DateTime.now().toIso8601String()]);

      if (results.isEmpty) return null;

      return _mapRowToUser(results.first);
    } catch (e) {
      print('Error getting user by session token: $e');
      return null;
    }
  }

  /// Delete user session
  Future<bool> deleteUserSession(String token) async {
    try {
      await _powerSync.delete(
        'user_sessions',
        where: 'token = ?',
        whereArgs: [token],
      );

      return true;
    } catch (e) {
      print('Error deleting user session: $e');
      return false;
    }
  }

  /// Clean up expired sessions
  Future<void> cleanupExpiredSessions() async {
    try {
      await _powerSync.delete(
        'user_sessions',
        where: 'expires_at < ?',
        whereArgs: [DateTime.now().toIso8601String()],
      );
    } catch (e) {
      print('Error cleaning up expired sessions: $e');
    }
  }

  /// Trigger manual sync from Supabase
  Future<void> triggerManualSync() async {
    try {
      print('🔄 UserService: Triggering manual sync...');
      await _powerSync.syncUsersFromSupabase();
      print('✅ UserService: Manual sync completed');
    } catch (e) {
      print('❌ UserService: Manual sync failed: $e');
      rethrow;
    }
  }

  /// Debug method to check user sync status
  Future<void> debugUserSync() async {
    try {
      print('🔍 UserService: Debugging user sync...');

      final localUsers = await getAllUsers();
      print('📱 UserService: Local users count: ${localUsers.length}');

      if (localUsers.isNotEmpty) {
        print('📱 UserService: Local users:');
        for (final user in localUsers) {
          print('  - ${user.displayName} (${user.email}) - ID: ${user.id}');
        }
      } else {
        print('📱 UserService: No local users found');
      }

      // Try to trigger a manual sync to see if that helps
      try {
        await triggerManualSync();
        final updatedUsers = await getAllUsers();
        print(
            '📱 UserService: After sync - Local users count: ${updatedUsers.length}');
      } catch (e) {
        print('❌ UserService: Sync during debug failed: $e');
      }

      // PowerSync handles sync automatically
      print(
          '📱 UserService: PowerSync sync status available via syncStatusStream');
    } catch (e) {
      print('❌ UserService: Error debugging user sync: $e');
    }
  }

  /// Map database row to User object
  User _mapRowToUser(Map<String, dynamic> row) {
    return User(
      id: row['id'] as String,
      email: row['email'] as String,
      displayName: row['display_name'] as String,
      avatarUrl: row['avatar_url'] as String?,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : null,
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
    );
  }
}
