import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../core/constants/app_constants.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  static const int _dbVersion = 2;
  static const String _dbName = 'radar_saku.db';

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableUsers} (
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        email_verified_at TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableWallets} (
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance TEXT NOT NULL DEFAULT '0',
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableTransactionTypes} (
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        action TEXT NOT NULL,
        description TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableTransactionCategories} (
        id TEXT PRIMARY KEY NOT NULL,
        transaction_type_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (transaction_type_id)
          REFERENCES ${AppConstants.tableTransactionTypes}(id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableTransactions} (
        id TEXT PRIMARY KEY NOT NULL,
        wallet_id TEXT NOT NULL,
        transaction_category_id TEXT NOT NULL,
        name TEXT NOT NULL,
        amount TEXT NOT NULL,
        note TEXT,
        photo_url TEXT,
        sync_status TEXT NOT NULL DEFAULT '${AppConstants.syncStatusPending}',
        sync_error_message TEXT,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT,
        FOREIGN KEY (wallet_id)
          REFERENCES ${AppConstants.tableWallets}(id),
        FOREIGN KEY (transaction_category_id)
          REFERENCES ${AppConstants.tableTransactionCategories}(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableTransfers} (
        id TEXT PRIMARY KEY NOT NULL,
        from_wallet_id TEXT NOT NULL,
        to_wallet_id TEXT NOT NULL,
        amount TEXT NOT NULL,
        fee TEXT NOT NULL DEFAULT '0',
        transfer_date TEXT NOT NULL,
        note TEXT,
        sync_status TEXT NOT NULL DEFAULT '${AppConstants.syncStatusPending}',
        sync_error_message TEXT,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableSyncMeta} (
        key TEXT PRIMARY KEY NOT NULL,
        value TEXT
      )
    ''');

    // Indexes for performance
    await db.execute('''
      CREATE INDEX idx_transactions_wallet_id
      ON ${AppConstants.tableTransactions}(wallet_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_transactions_sync_status
      ON ${AppConstants.tableTransactions}(sync_status)
    ''');
    await db.execute('''
      CREATE INDEX idx_transactions_deleted_at
      ON ${AppConstants.tableTransactions}(deleted_at)
    ''');
    await db.execute('''
      CREATE INDEX idx_tx_categories_type_id
      ON ${AppConstants.tableTransactionCategories}(transaction_type_id)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migrate transactions: drop synced_at, add sync_status + sync_error_message
      await db.execute(
          "ALTER TABLE ${AppConstants.tableTransactions} ADD COLUMN sync_status TEXT NOT NULL DEFAULT '${AppConstants.syncStatusPending}'");
      await db.execute(
          'ALTER TABLE ${AppConstants.tableTransactions} ADD COLUMN sync_error_message TEXT');
      // Migrate existing synced records
      await db.execute(
          "UPDATE ${AppConstants.tableTransactions} SET sync_status = '${AppConstants.syncStatusSynced}' WHERE synced_at IS NOT NULL");
      // Migrate transfers: add sync_status + sync_error_message
      await db.execute(
          "ALTER TABLE ${AppConstants.tableTransfers} ADD COLUMN sync_status TEXT NOT NULL DEFAULT '${AppConstants.syncStatusPending}'");
      await db.execute(
          'ALTER TABLE ${AppConstants.tableTransfers} ADD COLUMN sync_error_message TEXT');
    }
  }

  // ---- Generic helpers ----

  Future<int> insert(String table, Map<String, dynamic> row) async {
    final db = await database;
    return db.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> update(
    String table,
    Map<String, dynamic> row,
    String where,
    List<Object?> whereArgs,
  ) async {
    final db = await database;
    return db.update(table, row, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table,
    String where,
    List<Object?> whereArgs,
  ) async {
    final db = await database;
    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final db = await database;
    return db.rawQuery(sql, arguments);
  }

  Future<int> rawUpdate(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final db = await database;
    return db.rawUpdate(sql, arguments);
  }

  /// Clear all user data (on logout)
  Future<void> clearAllUserData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(AppConstants.tableTransactions);
      await txn.delete(AppConstants.tableTransfers);
      await txn.delete(AppConstants.tableTransactionCategories);
      await txn.delete(AppConstants.tableTransactionTypes);
      await txn.delete(AppConstants.tableWallets);
      await txn.delete(AppConstants.tableUsers);
      await txn.delete(AppConstants.tableSyncMeta);
    });
  }

  // ---- SyncMeta helpers ----

  Future<String?> getSyncMetaValue(String key) async {
    final rows = await query(
      AppConstants.tableSyncMeta,
      where: 'key = ?',
      whereArgs: [key],
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setSyncMetaValue(String key, String? value) async {
    final db = await database;
    await db.insert(
      AppConstants.tableSyncMeta,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
