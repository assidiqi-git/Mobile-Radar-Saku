import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// Push unsynced local transactions to the server in batches of 500.
  /// Returns the total number of transactions successfully synced.
  ///
  /// On 422: marks the batch records as [AppConstants.syncStatusError] (quarantine).
  /// On network error: silently returns 0 (will retry next time).
  Future<int> push() async {
    int offset = 0;
    int totalSynced = 0;
    const batchSize = AppConstants.syncBatchSize;

    while (true) {
      // Fetch next batch of pending transactions (excluding quarantined error ones)
      final pendingRows = await _db.rawQuery(
        "SELECT * FROM ${AppConstants.tableTransactions} "
        "WHERE sync_status = '${AppConstants.syncStatusPending}' "
        "ORDER BY created_at ASC "
        "LIMIT $batchSize OFFSET $offset",
      );

      if (pendingRows.isEmpty) break;

      final transactions = pendingRows.map(TransactionModel.fromMap).toList();

      try {
        final result = await _api.pushTransactions(transactions);
        final synced = result['data']?['synced'] as int? ?? 0;

        // Mark batch as synced
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
        totalSynced += synced;

        // If the batch had fewer records than the limit, we've exhausted all pending
        if (transactions.length < batchSize) break;
        // OFFSET does NOT advance because synced records are no longer 'pending'
        // — next iteration will fetch the next batch starting from offset 0 of remaining pending
      } on ValidationException catch (e) {
        // 422: The batch was rejected — quarantine all records in this batch
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
        // Advance offset past quarantined records so next batch doesn't refetch them
        offset += transactions.length;
        // Continue loop — might still have other pending records beyond this batch
      } catch (e) {
        // Network error or unexpected — silent, will retry next push
        debugPrint('[SyncManager] Push error: $e');
        return totalSynced;
      }
    }

    return totalSynced;
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
  ///
  /// Returns immediately with zeros if the current session is guest-only (offline mode).
  Future<({int pushed, int pulled})> sync() async {
    // Guest mode: no network operations allowed
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(AppConstants.isGuestKey) ?? false) {
      debugPrint('[SyncManager] Guest mode — skipping sync.');
      return (pushed: 0, pulled: 0);
    }

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
