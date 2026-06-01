import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/formatters.dart';
import '../database/database_helper.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';

/// SyncManager handles the offline-first synchronization logic.
///
/// Push: LOCAL → SERVER (transactions where sync_status == 'pending')
/// Pull: SERVER → LOCAL (delta updates since last_synced_at)
///
/// Quarantine: If a record fails with 422, it is marked sync_status = 'error'
/// and NOT discarded. It shows in the UI with an error badge.
class SyncManager {
  SyncManager._();
  static final SyncManager instance = SyncManager._();

  final _db = DatabaseHelper.instance;
  final _api = ApiService.instance;

  /// Push unsynced local transactions to the server.
  /// Returns the number of transactions successfully synced.
  ///
  /// On 422: marks the record as [AppConstants.syncStatusError] (quarantine).
  /// On network error: silently returns 0 (will retry next time).
  Future<int> push() async {
    // Fetch all pending transactions (not error ones — those need user action)
    final pendingRows = await _db.query(
      AppConstants.tableTransactions,
      where: "sync_status = '${AppConstants.syncStatusPending}'",
      orderBy: 'created_at ASC',
      limit: AppConstants.syncBatchSize,
    );

    if (pendingRows.isEmpty) return 0;

    final transactions = pendingRows.map(TransactionModel.fromMap).toList();
    int syncedCount = 0;

    try {
      final result = await _api.pushTransactions(transactions);
      final synced = result['data']?['synced'] as int? ?? 0;

      // Mark all as synced
      final now = DateFormatter.toApiString(DateTime.now());
      final db = await _db.database;
      final batch = db.batch();
      for (final tx in transactions) {
        batch.update(
          AppConstants.tableTransactions,
          {
            'sync_status': AppConstants.syncStatusSynced,
            'sync_error_message': null,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [tx.id],
        );
      }
      await batch.commit(noResult: true);
      syncedCount = synced;
    } on ValidationException catch (e) {
      // 422: The batch was rejected — quarantine all pending records
      debugPrint('[SyncManager] Push 422: ${e.message}');
      final errorMessage = e.message;
      final db = await _db.database;
      final batch = db.batch();
      for (final tx in transactions) {
        batch.update(
          AppConstants.tableTransactions,
          {
            'sync_status': AppConstants.syncStatusError,
            'sync_error_message': errorMessage,
          },
          where: 'id = ?',
          whereArgs: [tx.id],
        );
      }
      await batch.commit(noResult: true);
      // Return 0 — nothing was synced, but we handled it
    } catch (e) {
      // Network error or unexpected — silent, will retry next push
      debugPrint('[SyncManager] Push error: $e');
      return 0;
    }

    return syncedCount;
  }

  /// Pull delta updates from the server and merge into local DB.
  /// Returns the number of records pulled.
  Future<int> pull() async {
    // Get last sync timestamp from meta table
    final lastSyncedAt =
        await _db.getSyncMetaValue(AppConstants.lastSyncedAtKey);

    try {
      final serverTransactions = await _api.pullTransactions(
        lastSyncedAt: lastSyncedAt,
      );

      if (serverTransactions.isEmpty) return 0;

      final db = await _db.database;
      final batch = db.batch();

      String? latestUpdatedAt;

      for (final tx in serverTransactions) {
        final existing = await _db.query(
          AppConstants.tableTransactions,
          where: 'id = ?',
          whereArgs: [tx.id],
        );

        // Records from server are always marked as synced
        final serverRow = tx.copyWith(
          syncStatus: AppConstants.syncStatusSynced,
          syncErrorMessage: null,
        ).toMap();

        if (existing.isEmpty) {
          batch.insert(AppConstants.tableTransactions, serverRow);
        } else {
          batch.update(
            AppConstants.tableTransactions,
            serverRow,
            where: 'id = ?',
            whereArgs: [tx.id],
          );
        }

        // Track latest updated_at to advance cursor
        if (tx.updatedAt != null) {
          if (latestUpdatedAt == null ||
              tx.updatedAt!.compareTo(latestUpdatedAt) > 0) {
            latestUpdatedAt = tx.updatedAt;
          }
        }
      }

      await batch.commit(noResult: true);

      // Advance the last_synced_at cursor
      if (latestUpdatedAt != null) {
        await _db.setSyncMetaValue(
            AppConstants.lastSyncedAtKey, latestUpdatedAt);
      }

      return serverTransactions.length;
    } catch (e) {
      debugPrint('[SyncManager] Pull error: $e');
      rethrow;
    }
  }

  /// Full sync: push first, then pull.
  /// Returns a record with pushed and pulled counts.
  Future<({int pushed, int pulled})> sync() async {
    final pushed = await push();
    final pulled = await pull();
    return (pushed: pushed, pulled: pulled);
  }

  /// Count of pending (unsynced) local transactions.
  Future<int> pendingCount() async {
    final rows = await _db.rawQuery(
      "SELECT COUNT(*) as count FROM ${AppConstants.tableTransactions} WHERE sync_status = '${AppConstants.syncStatusPending}'",
    );
    return rows.first['count'] as int? ?? 0;
  }

  /// Count of quarantined (error) local transactions.
  Future<int> errorCount() async {
    final rows = await _db.rawQuery(
      "SELECT COUNT(*) as count FROM ${AppConstants.tableTransactions} WHERE sync_status = '${AppConstants.syncStatusError}'",
    );
    return rows.first['count'] as int? ?? 0;
  }

  /// Reset sync cursor (force full sync on next pull).
  Future<void> resetSyncCursor() async {
    await _db.setSyncMetaValue(AppConstants.lastSyncedAtKey, null);
  }
}
