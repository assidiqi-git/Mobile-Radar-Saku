import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/ulid_generator.dart';
import '../database/database_helper.dart';

class DefaultDataService {
  /// Checks if the database is empty, and if so, inserts default template data.
  static Future<void> initDefaultData() async {
    try {
      final dbHelper = DatabaseHelper.instance;

      // Check if there's already any data in the wallets table
      // (Assuming if wallets exist, the app has already been initialized with data)
      final existingWallets = await dbHelper.query(AppConstants.tableWallets, limit: 1);
      final existingTypes = await dbHelper.query(AppConstants.tableTransactionTypes, limit: 1);
      
      print('========== [DefaultDataService] START ==========');
      print('[DefaultDataService] existingWallets length: ${existingWallets.length}');
      print('[DefaultDataService] existingTypes length: ${existingTypes.length}');

      if (existingWallets.isNotEmpty || existingTypes.isNotEmpty) {
        // Data already exists, skip inserting defaults
        print('[DefaultDataService] Data exists, skipping defaults');
        return;
      }

      print('[DefaultDataService] Inserting default data...');

    final now = DateTime.now().toIso8601String();

    // 1. Insert Default Wallet
    final walletId = UlidGenerator.generate();
    await dbHelper.insert(AppConstants.tableWallets, {
      'id': walletId,
      'name': 'Dompet',
      'type': 'cash',
      'balance': '0',
      'created_at': now,
      'updated_at': now,
    });

    // 2. Insert Default Transaction Types
    final typePemasukanId = UlidGenerator.generate();
    await dbHelper.insert(AppConstants.tableTransactionTypes, {
      'id': typePemasukanId,
      'name': 'Pemasukan',
      'action': AppConstants.actionAddition,
      'description': 'Tipe default untuk pemasukan',
      'sync_status': AppConstants.syncStatusPending,
      'created_at': now,
      'updated_at': now,
    });

    final typePengeluaranId = UlidGenerator.generate();
    await dbHelper.insert(AppConstants.tableTransactionTypes, {
      'id': typePengeluaranId,
      'name': 'Pengeluaran',
      'action': AppConstants.actionDeduction,
      'description': 'Tipe default untuk pengeluaran',
      'sync_status': AppConstants.syncStatusPending,
      'created_at': now,
      'updated_at': now,
    });

    final typeNetralId = UlidGenerator.generate();
    await dbHelper.insert(AppConstants.tableTransactionTypes, {
      'id': typeNetralId,
      'name': 'Netral',
      'action': AppConstants.actionNeutral,
      'description': 'Tipe default untuk netral',
      'sync_status': AppConstants.syncStatusPending,
      'created_at': now,
      'updated_at': now,
    });

    // 3. Insert Default Transaction Categories
    final categoryGajiId = UlidGenerator.generate();
    await dbHelper.insert(AppConstants.tableTransactionCategories, {
      'id': categoryGajiId,
      'transaction_type_id': typePemasukanId,
      'name': 'Gaji',
      'description': 'Kategori default pemasukan',
      'sync_status': AppConstants.syncStatusPending,
      'created_at': now,
      'updated_at': now,
    });

    final categoryBelanjaId = UlidGenerator.generate();
    await dbHelper.insert(AppConstants.tableTransactionCategories, {
      'id': categoryBelanjaId,
      'transaction_type_id': typePengeluaranId,
      'name': 'Belanja',
      'description': 'Kategori default pengeluaran',
      'sync_status': AppConstants.syncStatusPending,
      'created_at': now,
      'updated_at': now,
    });

    final categoryTabunganId = UlidGenerator.generate();
    await dbHelper.insert(AppConstants.tableTransactionCategories, {
      'id': categoryTabunganId,
      'transaction_type_id': typeNetralId,
      'name': 'Tabungan',
      'description': 'Kategori default netral',
      'sync_status': AppConstants.syncStatusPending,
      'created_at': now,
      'updated_at': now,
    });

    // 4. Insert Dummy Transactions
    // final transactionId1 = UlidGenerator.generate();
    // await dbHelper.insert(AppConstants.tableTransactions, {
    //   'id': transactionId1,
    //   'wallet_id': walletId,
    //   'transaction_category_id': categoryGajiId,
    //   'name': 'Gaji Bulan Ini',
    //   'amount': '5000000',
    //   'sync_status': AppConstants.syncStatusPending,
    //   'created_at': now,
    //   'updated_at': now,
    // });

    // final transactionId2 = UlidGenerator.generate();
    // await dbHelper.insert(AppConstants.tableTransactions, {
    //   'id': transactionId2,
    //   'wallet_id': walletId,
    //   'transaction_category_id': categoryBelanjaId,
    //   'name': 'Beli Makanan',
    //   'amount': '50000',
    //   'sync_status': AppConstants.syncStatusPending,
    //   'created_at': now,
    //   'updated_at': now,
    // });
    
    // Update the wallet balance to reflect the transactions (5000000 - 50000 = 4950000)
    // await dbHelper.update(
    //   AppConstants.tableWallets,
    //   {'balance': '4950000'},
    //   'id = ?',
    //   [walletId],
    // );

    print('[DefaultDataService] Successfully inserted default dummy data.');
    print('========== [DefaultDataService] END ==========');
  } catch (e, stackTrace) {
    print('========== [DefaultDataService] ERROR ==========');
    print('[DefaultDataService] Error inserting default data: $e');
    print('[DefaultDataService] StackTrace: $stackTrace');
  }
}
}
