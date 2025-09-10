import 'dart:developer' as developer;
import 'power_sync_service.dart';

/// Database migration helper for handling schema changes
class DatabaseMigration {
  static const int _currentSchemaVersion = 2; // Increment when schema changes
  static const String _versionKey = 'schema_version';

  /// Check if database migration is needed and perform it
  static Future<bool> checkAndMigrate() async {
    try {
      final powerSync = PowerSyncService.instance;
      
      // Give PowerSync a moment to fully initialize
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!powerSync.isInitialized) {
        developer.log('❌ PowerSync not initialized, cannot check migration', name: 'DatabaseMigration');
        return false;
      }

      // Get current schema version from database
      int currentVersion = await _getCurrentSchemaVersion();
      
      developer.log('📊 Current schema version: $currentVersion, Target version: $_currentSchemaVersion', name: 'DatabaseMigration');

      if (currentVersion < _currentSchemaVersion) {
        developer.log('🔄 Schema migration needed from v$currentVersion to v$_currentSchemaVersion', name: 'DatabaseMigration');
        
        // For major schema changes (like adding primary keys), we need to reset the database
        if (currentVersion < 2) {
          await _performMajorSchemaMigration();
        }
        
        // Update schema version
        await _setSchemaVersion(_currentSchemaVersion);
        
        developer.log('✅ Database migration completed successfully', name: 'DatabaseMigration');
        return true;
      } else {
        developer.log('✅ Database schema is up to date', name: 'DatabaseMigration');
        return false;
      }
    } catch (e) {
      developer.log('❌ Database migration failed: $e', name: 'DatabaseMigration');
      return false;
    }
  }

  /// Get current schema version from database
  static Future<int> _getCurrentSchemaVersion() async {
    try {
      final powerSync = PowerSyncService.instance;
      
      // Try to get version from a metadata table (if it exists)
      try {
        final result = await powerSync.get(
          'SELECT value FROM app_metadata WHERE key = ?',
          [_versionKey]
        );
        
        if (result != null && result['value'] != null) {
          return int.tryParse(result['value'].toString()) ?? 1;
        }
      } catch (e) {
        // Metadata table might not exist, check if we have the old schema
        developer.log('📊 No metadata table found, checking schema structure', name: 'DatabaseMigration');
      }

      // Check if the chat_messages table has the id column (new schema)
      try {
        await powerSync.execute('SELECT id FROM chat_messages LIMIT 1');
        // If this succeeds, we have the new schema
        return _currentSchemaVersion;
      } catch (e) {
        // If this fails, we have the old schema without id columns
        return 1;
      }
    } catch (e) {
      developer.log('❌ Error checking schema version: $e', name: 'DatabaseMigration');
      return 1; // Default to old version
    }
  }

  /// Set schema version in database
  static Future<void> _setSchemaVersion(int version) async {
    try {
      final powerSync = PowerSyncService.instance;
      
      // Create metadata table if it doesn't exist
      await powerSync.execute('''
        CREATE TABLE IF NOT EXISTS app_metadata (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
      
      // Insert or update schema version
      await powerSync.execute('''
        INSERT OR REPLACE INTO app_metadata (key, value) 
        VALUES (?, ?)
      ''', [_versionKey, version.toString()]);
      
      developer.log('✅ Schema version set to: $version', name: 'DatabaseMigration');
    } catch (e) {
      developer.log('❌ Error setting schema version: $e', name: 'DatabaseMigration');
      rethrow;
    }
  }

  /// Perform major schema migration (requires database reset)
  static Future<void> _performMajorSchemaMigration() async {
    try {
      developer.log('🔄 Performing major schema migration - resetting local database', name: 'DatabaseMigration');
      
      final powerSync = PowerSyncService.instance;
      
      // Disconnect from PowerSync
      await powerSync.disconnect();
      
      // Close and delete the local database
      await powerSync.close();
      
      // Reinitialize PowerSync with new schema
      await powerSync.initialize();
      
      // Reconnect to PowerSync backend
      await powerSync.connectWithSupabaseAuth();
      
      // Trigger full sync from Supabase
      await powerSync.triggerPostAuthSync();
      
      developer.log('✅ Major schema migration completed - database reset and resynced', name: 'DatabaseMigration');
    } catch (e) {
      developer.log('❌ Major schema migration failed: $e', name: 'DatabaseMigration');
      rethrow;
    }
  }

  /// Force reset database (for testing or emergency recovery)
  static Future<void> forceReset() async {
    try {
      developer.log('⚠️ Force resetting database', name: 'DatabaseMigration');
      await _performMajorSchemaMigration();
      await _setSchemaVersion(_currentSchemaVersion);
      developer.log('✅ Force reset completed', name: 'DatabaseMigration');
    } catch (e) {
      developer.log('❌ Force reset failed: $e', name: 'DatabaseMigration');
      rethrow;
    }
  }
}
