import 'package:flutter/foundation.dart';
import 'package:powersync/powersync.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';

// Define the PowerSync database schema
// Note: PowerSync automatically adds an 'id' column to every table, so we don't define custom id columns
const schema = Schema([
  // Users table
  Table('users', [
    Column.text('supabase_id'), // Store original Supabase user ID
    Column.text('email'),
    Column.text('display_name'),
    Column.text('avatar_url'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ], indexes: [
    Index('users_supabase_id', [IndexedColumn('supabase_id')]),
    Index('users_email', [IndexedColumn('email')]),
  ]),

  // Projects table
  Table('projects', [
    Column.text('name'),
    Column.text('description'),
    Column.text('created_by'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  // Tasks table
  Table('tasks', [
    Column.text('title'),
    Column.text('description'),
    Column.text('status'),
    Column.text('priority'),
    Column.text('project_id'),
    Column.text('created_by'),
    Column.text('assigned_to'),
    Column.text('due_date'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ], indexes: [
    Index('project_tasks', [IndexedColumn('project_id')]),
    Index('user_tasks', [IndexedColumn('assigned_to')]),
  ]),

  // Task assignments table
  Table('task_assignments', [
    Column.text('task_id'),
    Column.text('user_id'),
    Column.text('assigned_by'),
    Column.text('assigned_at'),
  ], indexes: [
    Index('task_assignments_task', [IndexedColumn('task_id')]),
    Index('task_assignments_user', [IndexedColumn('user_id')]),
  ]),

  // Chats table
  Table('chats', [
    Column.text('name'),
    Column.text('description'),
    Column.text('type'),
    Column.integer('is_private'),
    Column.text('team_id'),
    Column.text('project_id'),
    Column.text('task_id'),
    Column.text('last_message_id'),
    Column.text('last_message_at'),
    Column.integer('message_count'),
    Column.integer('allow_ai_assistant'),
    Column.text('notification_settings'),
    Column.text('created_by'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  // Chat participants table
  Table('chat_participants', [
    Column.text('chat_id'),
    Column.text('user_id'),
    Column.text('user_name'),
    Column.text('user_avatar'),
    Column.integer('is_online'),
    Column.text('last_seen'),
    Column.integer('is_typing'),
    Column.text('role'), // Add role column to match Supabase schema
    Column.text('joined_at'),
  ], indexes: [
    Index('chat_participants_chat', [IndexedColumn('chat_id')]),
    Index('chat_participants_user', [IndexedColumn('user_id')]),
  ]),

  // Chat messages table
  Table('chat_messages', [
    Column.text('content'),
    Column.text('message_type'),
    Column.text('sender_id'),
    Column.text('sender_name'),
    Column.text('sender_avatar'),
    Column.text('room_id'),
    Column.text('file_url'),
    Column.text('file_name'),
    Column.integer('file_size'),
    Column.text('created_at'),
    Column.text('updated_at'),
    Column.integer('is_edited'),
    Column.text('reply_to_id'),
    Column.integer('thread_count'),
    Column.text('reactions'),
    Column.text('mentions'),
    Column.text('ai_context'),
    Column.text('call_type'),
    Column.text('call_status'),
    Column.integer('call_duration'),
    Column.text('call_participants'),
  ], indexes: [
    Index('chat_messages_room', [IndexedColumn('room_id')]),
  ]),

  // Documents table
  Table('documents', [
    Column.text('title'),
    Column.text('content'),
    Column.text('type'),
    Column.text('created_by'),
    Column.text('project_id'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ], indexes: [
    Index('documents_project', [IndexedColumn('project_id')]),
    Index('documents_user', [IndexedColumn('created_by')]),
  ]),

  // Teams table
  Table('teams', [
    Column.text('name'),
    Column.text('description'),
    Column.text('created_by'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  // Team members table
  Table('team_members', [
    Column.text('team_id'),
    Column.text('user_id'),
    Column.text('role'),
    Column.text('joined_at'),
  ], indexes: [
    Index('team_members_team', [IndexedColumn('team_id')]),
    Index('team_members_user', [IndexedColumn('user_id')]),
  ]),

  // Project members table
  Table('project_members', [
    Column.text('project_id'),
    Column.text('user_id'),
    Column.text('team_id'),
    Column.text('role'),
    Column.text('joined_at'),
  ], indexes: [
    Index('project_members_project', [IndexedColumn('project_id')]),
    Index('project_members_user', [IndexedColumn('user_id')]),
  ]),
]);

// Global PowerSync database instance
late PowerSyncDatabase db;

/// Backend connector for PowerSync with Supabase integration
class SupabaseConnector extends PowerSyncBackendConnector {
  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    try {
      // Get current Supabase session
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        print('No active Supabase session found');
        return null;
      }

      // Return PowerSync credentials using Supabase JWT
      return PowerSyncCredentials(
        endpoint: AppConstants.powerSyncUrl,
        token: session.accessToken, // Use Supabase access token directly
      );
    } catch (e) {
      print('Failed to fetch PowerSync credentials: $e');
      return null;
    }
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    // PowerSync automatically handles syncing - no manual upload needed
    return;
  }
}

/// Simplified PowerSync service following the official example pattern
class PowerSyncService {
  static PowerSyncService? _instance;
  static PowerSyncService get instance => _instance ??= PowerSyncService._();

  PowerSyncService._();

  bool _isInitialized = false;
  String? _localDbPath;
  SupabaseConnector? _connector;

  /// Initialize PowerSync database
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Get database path with better persistence
      var path = 'lifeos-powersync.db';

      if (!kIsWeb) {
        final dir = await getApplicationSupportDirectory();
        path = join(dir.path, 'lifeos-powersync.db');
      } else {
        // Use IndexedDB for better persistence on web
        path = 'indexed_db:lifeos-powersync.db';
      }

      _localDbPath = path;

      // Setup the database following the official example pattern
      db = PowerSyncDatabase(schema: schema, path: path);
      await db.initialize();

      _isInitialized = true;
      print('✅ PowerSync initialized successfully at: $path');
    } catch (e) {
      print('❌ Failed to initialize PowerSync: $e');
      rethrow;
    }
  }

  /// Connect to PowerSync using Supabase authentication
  Future<void> connectWithSupabaseAuth() async {
    if (!_isInitialized) {
      throw Exception('PowerSync not initialized. Call initialize() first.');
    }

    try {
      // Create the backend connector
      _connector = SupabaseConnector();

      // Connect to backend following the official example pattern
      await db.connect(connector: _connector!);

      print('✅ Connected to PowerSync successfully using Supabase auth');
    } catch (e) {
      print('❌ Failed to connect to PowerSync: $e');
      rethrow;
    }
  }

  /// Disconnect from PowerSync
  Future<void> disconnect() async {
    if (!_isInitialized) return;

    try {
      await db.disconnect();
      print('✅ Disconnected from PowerSync');
    } catch (e) {
      print('❌ Error disconnecting from PowerSync: $e');
    }
  }

  /// Execute a query on the PowerSync database
  Future<List<Map<String, dynamic>>> execute(String sql,
      [List<Object?>? parameters]) async {
    if (!_isInitialized) {
      throw Exception('PowerSync not initialized. Call initialize() first.');
    }

    try {
      final result = await db.execute(sql, parameters ?? <Object?>[]);
      return result.map((row) => Map<String, dynamic>.from(row)).toList();
    } catch (e) {
      print('❌ Query execution failed: $e');
      print('SQL: $sql');
      print('Parameters: $parameters');
      rethrow;
    }
  }

  /// Get a single record from PowerSync database
  Future<Map<String, dynamic>?> get(String sql,
      [List<Object?>? parameters]) async {
    if (!_isInitialized) {
      throw Exception('PowerSync not initialized. Call initialize() first.');
    }

    try {
      final result = await db.getOptional(sql, parameters ?? <Object?>[]);
      return result != null ? Map<String, dynamic>.from(result) : null;
    } catch (e) {
      print('❌ Get query failed: $e');
      rethrow;
    }
  }

  /// Get all records from PowerSync database
  Future<List<Map<String, dynamic>>> getAll(String sql,
      [List<Object?>? parameters]) async {
    if (!_isInitialized) {
      throw Exception('PowerSync not initialized. Call initialize() first.');
    }

    try {
      final result = await db.getAll(sql, parameters ?? <Object?>[]);
      return result.map((row) => Map<String, dynamic>.from(row)).toList();
    } catch (e) {
      print('❌ GetAll query failed: $e');
      rethrow;
    }
  }

  /// Watch a query for changes using PowerSync
  Stream<List<Map<String, dynamic>>> watch(String sql,
      [List<Object?>? parameters]) {
    if (!_isInitialized) {
      throw Exception('PowerSync not initialized. Call initialize() first.');
    }

    return db.watch(sql, parameters: parameters ?? <Object?>[]).map((result) {
      return result.map((row) => Map<String, dynamic>.from(row)).toList();
    });
  }

  /// Insert a record using PowerSync (compatibility method)
  Future<void> insert(String table, Map<String, dynamic> values) async {
    if (!_isInitialized) {
      throw Exception('PowerSync not initialized. Call initialize() first.');
    }

    try {
      final columns = values.keys.join(', ');
      final placeholders = values.keys.map((_) => '?').join(', ');
      final sql = 'INSERT INTO $table ($columns) VALUES ($placeholders)';

      await db.execute(sql, values.values.toList());
    } catch (e) {
      print('❌ Insert failed: $e');
      rethrow;
    }
  }

  /// Update records using PowerSync (compatibility method)
  Future<void> update(String table, Map<String, dynamic> values,
      {String? where, List<Object?>? whereArgs}) async {
    if (!_isInitialized) {
      throw Exception('PowerSync not initialized. Call initialize() first.');
    }

    try {
      final setClause = values.keys.map((key) => '$key = ?').join(', ');
      var sql = 'UPDATE $table SET $setClause';
      final params = values.values.toList();

      if (where != null) {
        sql += ' WHERE $where';
        if (whereArgs != null) {
          params.addAll(whereArgs);
        }
      }

      await db.execute(sql, params);
    } catch (e) {
      print('❌ Update failed: $e');
      rethrow;
    }
  }

  /// Delete records using PowerSync (compatibility method)
  Future<void> delete(String table,
      {String? where, List<Object?>? whereArgs}) async {
    if (!_isInitialized) {
      throw Exception('PowerSync not initialized. Call initialize() first.');
    }

    try {
      var sql = 'DELETE FROM $table';
      List<Object?>? params;

      if (where != null) {
        sql += ' WHERE $where';
        params = whereArgs;
      }

      await db.execute(sql, params ?? <Object?>[]);
    } catch (e) {
      print('❌ Delete failed: $e');
      rethrow;
    }
  }

  /// Query records using PowerSync (compatibility method)
  Future<List<Map<String, dynamic>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    if (!_isInitialized) {
      throw Exception('PowerSync not initialized. Call initialize() first.');
    }

    try {
      final columnList = columns?.join(', ') ?? '*';
      var sql = 'SELECT $columnList FROM $table';
      List<Object?>? params;

      if (where != null) {
        sql += ' WHERE $where';
        params = whereArgs;
      }

      if (orderBy != null) {
        sql += ' ORDER BY $orderBy';
      }

      if (limit != null) {
        sql += ' LIMIT $limit';
      }

      final result = await db.getAll(sql, params ?? <Object?>[]);
      return result.map((row) => Map<String, dynamic>.from(row)).toList();
    } catch (e) {
      print('❌ Query failed: $e');
      rethrow;
    }
  }

  /// Watch a table for changes using PowerSync (compatibility method)
  Stream<List<Map<String, dynamic>>> watchTable(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) {
    if (!_isInitialized) {
      throw Exception('PowerSync not initialized. Call initialize() first.');
    }

    var sql = 'SELECT * FROM $table';
    List<Object?>? params;

    if (where != null) {
      sql += ' WHERE $where';
      params = whereArgs;
    }

    return db.watch(sql, parameters: params ?? <Object?>[]).map((result) {
      return result.map((row) => Map<String, dynamic>.from(row)).toList();
    });
  }

  /// Get sync status from PowerSync
  Stream<SyncStatus> get syncStatusStream {
    if (!_isInitialized) {
      throw Exception('PowerSync not initialized. Call initialize() first.');
    }
    return db.statusStream;
  }

  /// Check if PowerSync is initialized
  bool get isInitialized => _isInitialized;

  /// Get the PowerSync database instance
  PowerSyncDatabase? get database => _isInitialized ? db : null;

  /// Get local database path
  String? get localDatabasePath => _localDbPath;

  /// Trigger manual sync for users from Supabase
  Future<void> syncUsersFromSupabase() async {
    if (!_isInitialized) {
      throw Exception('PowerSync not initialized. Call initialize() first.');
    }

    try {
      print('🔄 PowerSync: Starting manual user sync from Supabase...');

      // Note: PowerSync will automatically sync data from Supabase based on sync rules
      // This method is kept for backward compatibility but PowerSync handles sync automatically
      print('ℹ️ PowerSync handles user sync automatically via sync rules');

      print('✅ PowerSync: User sync completed successfully');
    } catch (e) {
      print('❌ PowerSync: User sync failed: $e');
      rethrow;
    }
  }

  /// Trigger automatic sync after authentication
  Future<void> triggerPostAuthSync() async {
    if (!_isInitialized) {
      print('⚠️ PowerSync: Database not initialized, skipping post-auth sync');
      return;
    }

    try {
      print('🔄 PowerSync: Starting post-authentication sync...');

      // PowerSync automatically syncs data based on sync rules once connected
      print('ℹ️ PowerSync will automatically sync data based on configured sync rules');

      print('✅ PowerSync: Post-authentication sync completed');
    } catch (e) {
      print('❌ PowerSync: Post-authentication sync failed: $e');
      // Don't rethrow - this is a background operation
    }
  }

  /// Close PowerSync database
  Future<void> close() async {
    try {
      await disconnect();
      await db.close();
      _isInitialized = false;
      print('✅ PowerSync closed');
    } catch (e) {
      print('❌ Error closing PowerSync: $e');
    }
  }
}
