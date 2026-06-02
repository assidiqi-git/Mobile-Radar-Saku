import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../core/constants/app_constants.dart';
import '../database/database_helper.dart';
import '../models/transaction.dart';
import '../models/transaction_category.dart';
import '../models/transaction_type.dart';
import '../models/wallet.dart';
import 'api_service.dart';

/// Callback fired on each sync step with the step index and a human-readable
/// status message.
typedef SyncProgressCallback = void Function(int step, String message);

/// Handles the one-time initial data pull that runs right after the first
/// successful login (or register).  This is intentionally separate from
/// [SyncManager] which deals with ongoing delta sync.
///
/// Steps:
///  1-3  (parallel)  GET /wallets + GET /transaction-types + GET /transaction-categories
///  4    (sequential) GET /sync/transactions/pull  (no last_synced_at = full pull)
///  5    (safety-net) POST /sync/transactions if there are pending local records
class InitialSyncService {
  InitialSyncService._();
  static final InitialSyncService instance = InitialSyncService._();

  final _db = DatabaseHelper.instance;
  final _api = ApiService.instance;

  /// Total number of logical sync steps (used for progress calculation).
  static const int totalSteps = 5;

  /// Run the full initial sync.
  ///
  /// [onProgress] is called before each step starts so the UI can update.
  /// Returns `true` on success, throws on unrecoverable error.
  Future<bool> runInitialSync({SyncProgressCallback? onProgress}) async {
    // Step 0 – preparation
    onProgress?.call(0, 'Menyiapkan catatan Anda...');
    await Future<void>.delayed(const Duration(milliseconds: 300));

    // Steps 1-3 run in parallel (wallets, types, categories)
    onProgress?.call(1, 'Mengunduh data dompet & kategori...');
    try {
      await _fetchMasterData();
    } catch (e) {
      debugPrint('[InitialSync] _fetchMasterData failed: $e');
      rethrow;
    }

    // Step 4 – full transaction pull
    onProgress?.call(4, 'Menyinkronkan transaksi...');
    try {
      await _pullTransactions();
    } catch (e) {
      debugPrint('[InitialSync] _pullTransactions failed: $e');
      rethrow;
    }

    // Step 5 – safety-net push of any offline-created records
    onProgress?.call(5, 'Mengunggah data lokal...');
    await _pushPendingTransactions();

    onProgress?.call(6, 'Selesai! Selamat datang 🎉');
    return true;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Pull wallets, transaction types and transaction categories in parallel,
  /// then bulk-upsert all of them into SQLite.
  Future<void> _fetchMasterData() async {
    final results = await Future.wait([
      _api.getWallets(),
      _api.getTransactionTypes(),
      _api.getTransactionCategories(),
    ]);

    final wallets = results[0] as List<WalletModel>;
    final txTypes = results[1] as List<TransactionTypeModel>;
    final txCategories = results[2] as List<TransactionCategoryModel>;

    final db = await _db.database;

    await db.transaction((txn) async {
      // Wallets
      for (final w in wallets) {
        await txn.insert(
          AppConstants.tableWallets,
          w.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Transaction types (must come before categories due to FK)
      for (final t in txTypes) {
        await txn.insert(
          AppConstants.tableTransactionTypes,
          t.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Transaction categories
      for (final c in txCategories) {
        await txn.insert(
          AppConstants.tableTransactionCategories,
          c.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });

    debugPrint(
      '[InitialSync] Master data: ${wallets.length} wallets, '
      '${txTypes.length} types, ${txCategories.length} categories',
    );
  }

  /// Pull all transactions from the server (no cursor = full sync) and
  /// upsert them locally. Updates the last_synced_at cursor on success.
  Future<void> _pullTransactions() async {
    // No last_synced_at → full initial pull
    final serverTransactions = await _api.pullTransactions();

    if (serverTransactions.isEmpty) {
      debugPrint('[InitialSync] No transactions on server.');
      return;
    }

    final db = await _db.database;
    String? latestUpdatedAt;

    await db.transaction((txn) async {
      for (final tx in serverTransactions) {
        // Skip rows that are missing required FK references to avoid SQLite
        // foreign-key constraint violations (can happen when API returns
        // nested objects without the flat _id field).
        if (tx.walletId.isEmpty || tx.transactionCategoryId.isEmpty) {
          debugPrint('[InitialSync] Skipping tx ${tx.id}: missing FK ids.');
          continue;
        }

        final serverRow = tx
            .copyWith(
              syncStatus: AppConstants.syncStatusSynced,
              syncErrorMessage: null,
            )
            .toMap();

        await txn.insert(
          AppConstants.tableTransactions,
          serverRow,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Track the newest updated_at to advance the delta-sync cursor
        if (tx.updatedAt != null) {
          if (latestUpdatedAt == null ||
              tx.updatedAt!.compareTo(latestUpdatedAt!) > 0) {
            latestUpdatedAt = tx.updatedAt;
          }
        }
      }
    });

    // Persist the sync cursor for future delta syncs
    if (latestUpdatedAt != null) {
      await _db.setSyncMetaValue(AppConstants.lastSyncedAtKey, latestUpdatedAt);
    }

    debugPrint(
        '[InitialSync] Pulled ${serverTransactions.length} transactions.');
  }

  /// Push any locally-created transactions that are still pending.
  /// This is a safety-net for edge cases (e.g. user created data offline
  /// before the initial sync completed).  Silently ignores errors.
  Future<void> _pushPendingTransactions() async {
    try {
      final pendingRows = await _db.query(
        AppConstants.tableTransactions,
        where: "sync_status = '${AppConstants.syncStatusPending}'",
        orderBy: 'created_at ASC',
        limit: AppConstants.syncBatchSize,
      );

      if (pendingRows.isEmpty) {
        debugPrint('[InitialSync] No pending local transactions to push.');
        return;
      }

      final transactions = pendingRows.map(TransactionModel.fromMap).toList();
      final result = await _api.pushTransactions(transactions);
      final synced = result['data']?['synced'] as int? ?? 0;
      debugPrint('[InitialSync] Pushed $synced local transactions.');
    } catch (e) {
      // Non-fatal — the data stays pending and will be pushed on next sync
      debugPrint('[InitialSync] Safety-net push failed (non-fatal): $e');
    }
  }
}


