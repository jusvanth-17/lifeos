import 'dart:html' as html;
import 'dart:async';

/// Web-specific implementation of session sync service
class WebSessionSyncService {
  html.EventListener? _storageListener;

  /// Initialize cross-tab session synchronization for web
  void initialize(StreamController<String> sessionChangeController) {
    // Listen for storage events (fired when localStorage changes in other tabs)
    _storageListener = (html.Event event) {
      final storageEvent = event as html.StorageEvent;

      // Check if any Supabase auth-related key changed
      if (storageEvent.key != null &&
          (storageEvent.key!.contains('supabase.auth.token') ||
              storageEvent.key!.contains('sb-') ||
              storageEvent.key == 'lifeOS.session.sync')) {
        print('🔄 SessionSyncService: Detected session change in another tab');
        print('🔑 Changed key: ${storageEvent.key}');

        // Handle our custom sync trigger
        if (storageEvent.key == 'lifeOS.session.sync') {
          print('🔄 SessionSyncService: Custom sync trigger detected');
          sessionChangeController.add('session_sync_trigger');
          return;
        }

        // Notify listeners about the session change
        if (storageEvent.newValue != null &&
            storageEvent.newValue!.isNotEmpty) {
          print('✅ SessionSyncService: Session updated in another tab');
          sessionChangeController.add('session_updated');
        } else {
          print('🚪 SessionSyncService: Session cleared in another tab');
          sessionChangeController.add('session_cleared');
        }
      }
    };

    html.window.addEventListener('storage', _storageListener!);
  }

  /// Manually trigger a session sync event
  void triggerSessionSync() {
    try {
      // Update a sync key to trigger storage event in other tabs
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      html.window.localStorage['lifeOS.session.sync'] = timestamp;

      // Remove it immediately (we just needed to trigger the event)
      html.window.localStorage.remove('lifeOS.session.sync');

      print('🔄 SessionSyncService: Triggered session sync across tabs');
    } catch (e) {
      print('❌ SessionSyncService: Error triggering session sync: $e');
    }
  }

  /// Clean up resources
  void dispose() {
    if (_storageListener != null) {
      html.window.removeEventListener('storage', _storageListener!);
      _storageListener = null;
    }
  }
}
