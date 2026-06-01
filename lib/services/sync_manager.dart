import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/formatters.dart';
import '../database/database_helper.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';

/// SyncManager handles the offline-first synchronization logic.
///
/// Push: LOCAL → SERVER (transactions where synced_at IS NULL)
/// Pull: SERVER → LOCAL (delta updates since last_synced_at)
class SyncManager {
  SyncManager._();
  static final SyncManager instance = SyncManager._();

  final _db = DatabaseHelper.instance;
  final _api = ApiService.instance;

  /// Push unsynced local transactions to the server.
  /// Returns the number of transactions successfully synced.
  Future<int> push() async {
    // Fetch all unsynced transactions (including tombstones)
    final unsyncedRows = await _db.query(
      AppConstants.tableTransactions,
      where: 'synced_at IS NULL',
      orderBy: 'created_at ASC',
      limit: AppConstants.syncBatchSize,
    );

    if (unsyncedRows.isEmpty) return 0;

    final transactions =
        unsyncedRows.map(TransactionModel.fromMap).toList();

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
          {'synced_at': now},
          where: 'id = ?',
          whereArgs: [tx.id],
        );
      }
      await batch.commit(noResult: true);

      return synced;
    } catch (e) {
      debugPrint('[SyncManager] Push error: $e');
      return 0;
    }
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

        if (existing.isEmpty) {
          // New record — insert
          batch.insert(
            AppConstants.tableTransactions,
            tx.copyWith(syncedAt: DateTime.now().toIso8601String()).toMap(),
          );
        } else {
          // Existing record — update (handles soft-delete tombstones)
          batch.update(
            AppConstants.tableTransactions,
            tx.copyWith(syncedAt: DateTime.now().toIso8601String()).toMap(),
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
      'SELECT COUNT(*) as count FROM ${AppConstants.tableTransactions} WHERE synced_at IS NULL',
    );
    return rows.first['count'] as int? ?? 0;
  }

  /// Reset sync cursor (force full sync on next pull).
  Future<void> resetSyncCursor() async {
    await _db.setSyncMetaValue(AppConstants.lastSyncedAtKey, null);
  }
}
