import 'dart:async';
import 'package:flutter/foundation.dart';

// Conditional imports for web-specific functionality
import 'session_sync_service_web.dart'
    if (dart.library.io) 'session_sync_service_stub.dart';

/// Service to handle cross-tab session synchronization
class SessionSyncService {
  static SessionSyncService? _instance;
  static SessionSyncService get instance =>
      _instance ??= SessionSyncService._();

  SessionSyncService._();

  StreamController<String>? _sessionChangeController;
  final _webService = WebSessionSyncService();

  /// Initialize cross-tab session synchronization
  void initialize() {
    if (!kIsWeb) {
      print(
          'ℹ️ SessionSyncService: Cross-tab sync not available on this platform');
      return;
    }

    _sessionChangeController = StreamController<String>.broadcast();
    _webService.initialize(_sessionChangeController!);
    print('✅ SessionSyncService: Cross-tab session sync initialized');
  }

  /// Stream of session change events from other tabs
  Stream<String> get sessionChanges {
    if (_sessionChangeController == null) {
      initialize();
    }
    return _sessionChangeController?.stream ?? const Stream.empty();
  }

  /// Manually trigger a session sync event
  void triggerSessionSync() {
    if (!kIsWeb) return;
    _webService.triggerSessionSync();
  }

  /// Clean up resources
  void dispose() {
    _webService.dispose();
    _sessionChangeController?.close();
    _sessionChangeController = null;
    print('🧹 SessionSyncService: Disposed');
  }
}
