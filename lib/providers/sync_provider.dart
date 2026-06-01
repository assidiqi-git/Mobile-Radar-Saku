import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../database/database_helper.dart';
import '../providers/auth_provider.dart';
import '../services/connectivity_service.dart';
import '../services/sync_manager.dart';

enum SyncStatus { idle, syncing, success, error }

class SyncProvider extends ChangeNotifier {
  SyncStatus _status = SyncStatus.idle;
  DateTime? _lastSyncedAt;
  int _pendingCount = 0;
  String? _errorMessage;

  SyncStatus get status => _status;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  int get pendingCount => _pendingCount;
  String? get errorMessage => _errorMessage;
  bool get isSyncing => _status == SyncStatus.syncing;
  bool get hasPending => _pendingCount > 0;

  /// Called by [ChangeNotifierProxyProvider] whenever [AuthProvider] changes.
  void updateAuth(AuthProvider auth) {
    if (auth.isAuthenticated) {
      refreshPendingCount();
      _loadLastSyncedAt();
      _initConnectivityService(auth);
    } else {
      _pendingCount = 0;
      _lastSyncedAt = null;
      _status = SyncStatus.idle;
      // Stop listening when logged out — no need to auto-sync unauthenticated
      ConnectivityService.instance.dispose();
      notifyListeners();
    }
  }

  void _initConnectivityService(AuthProvider auth) {
    ConnectivityService.instance.init(
      // Pass live getters so ConnectivityService always reads the current state.
      isAuthenticated: () => auth.isAuthenticated,
      isSyncing: () => isSyncing,
      onReconnect: _autoSync,
    );
  }

  /// Triggered by [ConnectivityService] after an offline→online transition.
  /// Runs a full sync and refreshes the pending badge.
  Future<void> _autoSync() async {
    debugPrint('[SyncProvider] Auto-sync triggered by network reconnect.');
    await sync();
  }

  Future<void> _loadLastSyncedAt() async {
    final value = await DatabaseHelper.instance
        .getSyncMetaValue(AppConstants.lastSyncedAtKey);
    if (value != null) {
      _lastSyncedAt = DateTime.tryParse(value);
      notifyListeners();
    }
  }

  Future<void> refreshPendingCount() async {
    _pendingCount = await SyncManager.instance.pendingCount();
    notifyListeners();
  }

  /// Trigger a full sync (push then pull).
  Future<bool> sync() async {
    if (_status == SyncStatus.syncing) return false;

    _status = SyncStatus.syncing;
    _errorMessage = null;
    notifyListeners();

    bool success = false;
    try {
      final result = await SyncManager.instance.sync();
      _lastSyncedAt = DateTime.now();
      await DatabaseHelper.instance.setSyncMetaValue(
        AppConstants.lastSyncedAtKey,
        _lastSyncedAt!.toIso8601String(),
      );
      _status = SyncStatus.success;
      success = true;
      debugPrint(
          '[SyncProvider] Sync done. Pushed: ${result.pushed}, Pulled: ${result.pulled}');
    } catch (e) {
      _errorMessage = 'Sync gagal: ${e.toString()}';
      _status = SyncStatus.error;
      debugPrint('[SyncProvider] Sync error: $e');
    } finally {
      // Always refresh from DB so the badge shows the real count,
      // regardless of whether push/pull succeeded or failed.
      _pendingCount = await SyncManager.instance.pendingCount();
      notifyListeners();
    }
    return success;
  }

  /// Increment pending count when a new local transaction is saved.
  void incrementPending() {
    _pendingCount++;
    notifyListeners();
  }

  /// Decrement pending count after a background push succeeds.
  /// Clamps to 0 to avoid negative values.
  void decrementPending() {
    if (_pendingCount > 0) {
      _pendingCount--;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    ConnectivityService.instance.dispose();
    super.dispose();
  }
}
