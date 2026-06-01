import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// ConnectivityService listens for network state changes and fires
/// [onReconnect] when the device transitions from offline → online.
///
/// Features:
/// - Singleton: one listener for the entire app lifetime.
/// - Debounce: waits [debounceDelay] after a reconnect event before
///   triggering the sync, preventing rapid-fire calls on network flicker.
/// - Guard: skips if [isSyncing] returns true or [isAuthenticated] is false.
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  /// How long to wait after detecting reconnection before syncing.
  static const Duration debounceDelay = Duration(seconds: 2);

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _debounceTimer;

  /// The last known connectivity state (starts as none on first run).
  ConnectivityResult _lastResult = ConnectivityResult.none;

  /// Whether a sync is currently in progress (prevents double-sync).
  bool Function()? _isSyncing;

  /// Whether the user is logged in (skips sync when not authenticated).
  bool Function()? _isAuthenticated;

  /// Called when a genuine offline→online transition is detected and
  /// all guards pass.
  Future<void> Function()? _onReconnect;

  /// Call this once when the user logs in (or on app start if already logged in).
  ///
  /// [isAuthenticated] — returns current auth state.
  /// [isSyncing]       — returns true when a sync is already running.
  /// [onReconnect]     — async callback to execute the actual sync.
  void init({
    required bool Function() isAuthenticated,
    required bool Function() isSyncing,
    required Future<void> Function() onReconnect,
  }) {
    _isAuthenticated = isAuthenticated;
    _isSyncing = isSyncing;
    _onReconnect = onReconnect;

    // Cancel any existing subscription before starting a new one.
    _subscription?.cancel();

    _subscription = Connectivity()
        .onConnectivityChanged
        .listen(_handleConnectivityChange);

    debugPrint('[ConnectivityService] Initialized and listening.');
  }

  /// Cancel the subscription and debounce timer. Call on logout or app dispose.
  void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _isAuthenticated = null;
    _isSyncing = null;
    _onReconnect = null;
    _lastResult = ConnectivityResult.none;
    debugPrint('[ConnectivityService] Disposed.');
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    // Take the first meaningful result from the list.
    final current = results.isNotEmpty ? results.first : ConnectivityResult.none;

    final wasOffline = _lastResult == ConnectivityResult.none;
    final isOnline = current != ConnectivityResult.none;

    debugPrint(
        '[ConnectivityService] State: $_lastResult → $current'
        ' (wasOffline: $wasOffline, isOnline: $isOnline)');

    _lastResult = current;

    // Only react to offline → online transitions.
    if (!wasOffline || !isOnline) return;

    debugPrint('[ConnectivityService] Reconnect detected — scheduling sync.');

    // Debounce: cancel pending timer and start fresh.
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDelay, _triggerSync);
  }

  Future<void> _triggerSync() async {
    // Guard 1: auth check
    if (_isAuthenticated == null || !_isAuthenticated!()) {
      debugPrint('[ConnectivityService] Not authenticated — skipping auto-sync.');
      return;
    }

    // Guard 2: already syncing
    if (_isSyncing != null && _isSyncing!()) {
      debugPrint('[ConnectivityService] Sync already in progress — skipping.');
      return;
    }

    debugPrint('[ConnectivityService] Auto-sync triggered by reconnect.');
    try {
      await _onReconnect?.call();
    } catch (e) {
      // Errors are handled inside onReconnect; swallow here to be safe.
      debugPrint('[ConnectivityService] Auto-sync error: $e');
    }
  }
}
