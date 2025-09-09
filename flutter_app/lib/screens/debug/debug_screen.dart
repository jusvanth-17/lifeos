import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart' show SyncStatus;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../models/user.dart' as app_user;
import '../../services/power_sync_service.dart';
import '../../services/user_service.dart';
import '../../widgets/layout/four_panel_layout.dart';

class DebugScreen extends ConsumerStatefulWidget {
  const DebugScreen({super.key});

  @override
  ConsumerState<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends ConsumerState<DebugScreen> {
  List<app_user.User> _localUsers = [];
  List<Map<String, dynamic>> _supabaseUsers = [];
  SyncStatus? _syncStatus;
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _lastSyncError;
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _loadDebugData();
    _listenToSyncStatus();
  }

  void _listenToSyncStatus() {
    PowerSyncService.instance.syncStatusStream.listen((status) {
      if (mounted) {
        setState(() {
          _syncStatus = status;
        });
      }
    });
  }

  Future<void> _loadDebugData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load local users
      final localUsers = await UserService.instance.getAllUsers();

      // Load Supabase users
      final supabaseUsers = await _fetchSupabaseUsers();

      setState(() {
        _localUsers = localUsers;
        _supabaseUsers = supabaseUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _lastSyncError = e.toString();
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSupabaseUsers() async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('id, email, display_name, avatar_url, created_at, updated_at')
          .limit(50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching Supabase users: $e');
      return [];
    }
  }

  Future<void> _triggerManualSync() async {
    setState(() {
      _isSyncing = true;
      _lastSyncError = null;
    });

    try {
      // Fetch users from Supabase and sync to local database
      await _syncUsersFromSupabase();

      // Reload local data
      await _loadDebugData();

      setState(() {
        _lastSyncTime = DateTime.now();
        _isSyncing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Manual sync completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSyncing = false;
        _lastSyncError = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _syncUsersFromSupabase() async {
    // Use the UserService's manual sync method which handles everything
    await UserService.instance.triggerManualSync();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FourPanelLayout(
      title: 'Debug & Sync',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sync Status Card
                  _buildSyncStatusCard(theme),
                  const SizedBox(height: AppConstants.spacingL),

                  // Manual Sync Button
                  _buildManualSyncSection(theme),
                  const SizedBox(height: AppConstants.spacingL),

                  // Local Users Section
                  _buildLocalUsersSection(theme),
                  const SizedBox(height: AppConstants.spacingL),

                  // Supabase Users Section
                  _buildSupabaseUsersSection(theme),
                  const SizedBox(height: AppConstants.spacingL),

                  // Sync Logs Section
                  _buildSyncLogsSection(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildSyncStatusCard(ThemeData theme) {
    final isConnected = _syncStatus?.connected ?? false;
    final statusColor = isConnected ? Colors.green : Colors.red;
    final statusText = isConnected ? 'Connected' : 'Disconnected';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: statusColor,
                ),
                const SizedBox(width: AppConstants.spacingS),
                Text(
                  'PowerSync Status',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingS),
                Text(statusText, style: theme.textTheme.bodyMedium),
              ],
            ),
            if (_syncStatus != null) ...[
              const SizedBox(height: AppConstants.spacingS),
              Text(
                'Last Activity: ${_syncStatus!.lastSyncedAt?.toString() ?? 'Never'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildManualSyncSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manual Sync',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              'Trigger a manual sync to fetch users from Supabase and store them locally.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isSyncing ? null : _triggerManualSync,
                  icon: _isSyncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync),
                  label: Text(_isSyncing ? 'Syncing...' : 'Sync Now'),
                ),
                const SizedBox(width: AppConstants.spacingM),
                TextButton.icon(
                  onPressed: _loadDebugData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Data'),
                ),
              ],
            ),
            if (_lastSyncTime != null) ...[
              const SizedBox(height: AppConstants.spacingS),
              Text(
                'Last manual sync: ${_lastSyncTime!.toString()}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocalUsersSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.storage,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppConstants.spacingS),
                Text(
                  'Local Users (PowerSync)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Chip(
                  label: Text('${_localUsers.length}'),
                  backgroundColor: theme.colorScheme.primaryContainer,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            if (_localUsers.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingL),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  border: Border.all(
                    color: theme.colorScheme.error.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: AppConstants.spacingS),
                    Expanded(
                      child: Text(
                        'No local users found. This might be why user search is not working.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...(_localUsers.take(10).map((user) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        user.displayName.substring(0, 1).toUpperCase() ?? 'U',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(user.displayName ?? 'Unknown User'),
                    subtitle: Text(user.email ?? 'No email'),
                    trailing: Text(
                      user.id.substring(0, 8),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ))),
            if (_localUsers.length > 10)
              Padding(
                padding: const EdgeInsets.only(top: AppConstants.spacingS),
                child: Text(
                  '... and ${_localUsers.length - 10} more users',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupabaseUsersSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: AppConstants.spacingS),
                Text(
                  'Supabase Users',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Chip(
                  label: Text('${_supabaseUsers.length}'),
                  backgroundColor: theme.colorScheme.secondaryContainer,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            if (_supabaseUsers.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingL),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppConstants.spacingS),
                    const Expanded(
                      child:
                          Text('No Supabase users found or connection failed.'),
                    ),
                  ],
                ),
              )
            else
              ...(_supabaseUsers.take(10).map((userData) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.secondary,
                      child: Text(
                        (userData['display_name'] as String?)
                                ?.substring(0, 1)
                                .toUpperCase() ??
                            'U',
                        style: TextStyle(
                          color: theme.colorScheme.onSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(userData['display_name'] ?? 'Unknown User'),
                    subtitle: Text(userData['email'] ?? 'No email'),
                    trailing: Text(
                      (userData['id'] as String).substring(0, 8),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ))),
            if (_supabaseUsers.length > 10)
              Padding(
                padding: const EdgeInsets.only(top: AppConstants.spacingS),
                child: Text(
                  '... and ${_supabaseUsers.length - 10} more users',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncLogsSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bug_report,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: AppConstants.spacingS),
                Text(
                  'Sync Logs & Errors',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            if (_lastSyncError != null)
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  border: Border.all(
                    color: theme.colorScheme.error.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.error,
                          color: theme.colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: AppConstants.spacingS),
                        Text(
                          'Last Sync Error:',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingS),
                    Text(
                      _lastSyncError!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    SizedBox(width: AppConstants.spacingS),
                    Text('No recent sync errors'),
                  ],
                ),
              ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              'Sync Comparison:',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.spacingS),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppConstants.spacingM),
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(AppConstants.radiusS),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${_localUsers.length}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Local Users',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppConstants.spacingM),
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.secondaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(AppConstants.radiusS),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${_supabaseUsers.length}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Supabase Users',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
