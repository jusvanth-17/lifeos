import 'dart:async';

/// Stub implementation of session sync service for non-web platforms
class WebSessionSyncService {
  /// Initialize cross-tab session synchronization (no-op for non-web platforms)
  void initialize(StreamController<String> sessionChangeController) {
    // No-op for non-web platforms
    print(
        'ℹ️ WebSessionSyncService: Cross-tab sync not available on this platform');
  }

  /// Manually trigger a session sync event (no-op for non-web platforms)
  void triggerSessionSync() {
    // No-op for non-web platforms
  }

  /// Clean up resources (no-op for non-web platforms)
  void dispose() {
    // No-op for non-web platforms
  }
}
