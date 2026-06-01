import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/ulid_generator.dart';
import '../core/utils/formatters.dart';
import '../database/database_helper.dart';
import '../models/transaction.dart';
import '../models/transaction_category.dart';
import '../models/transaction_type.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class TransactionProvider extends ChangeNotifier {
  List<TransactionModel> _transactions = [];
  List<TransactionTypeModel> _transactionTypes = [];
  List<TransactionCategoryModel> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<TransactionModel> get transactions =>
      _transactions.where((t) => t.deletedAt == null).toList();
  List<TransactionTypeModel> get transactionTypes => _transactionTypes;
  List<TransactionCategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<TransactionModel> get recentTransactions =>
      transactions.take(20).toList();

  void updateAuth(AuthProvider auth) {
    if (auth.isAuthenticated) {
      loadAll();
    } else {
      _transactions = [];
      _transactionTypes = [];
      _categories = [];
      notifyListeners();
    }
  }

  Future<void> loadAll() async {
    await Future.wait([
      loadTransactions(),
      loadCategories(),
      loadTransactionTypes(),
    ]);
  }

  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();
    try {
      final rows = await DatabaseHelper.instance.rawQuery('''
        SELECT t.*,
          w.name as wallet_name, w.type as wallet_type, w.balance as wallet_balance,
          c.name as category_name, c.transaction_type_id,
          tt.name as type_name, tt.action as type_action
        FROM ${AppConstants.tableTransactions} t
        LEFT JOIN ${AppConstants.tableWallets} w ON t.wallet_id = w.id
        LEFT JOIN ${AppConstants.tableTransactionCategories} c ON t.transaction_category_id = c.id
        LEFT JOIN ${AppConstants.tableTransactionTypes} tt ON c.transaction_type_id = tt.id
        WHERE t.deleted_at IS NULL
        ORDER BY t.created_at DESC
      ''');

      _transactions = rows.map((row) {
        final tx = TransactionModel.fromMap(row);
        return tx;
      }).toList();
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    try {
      final rows = await DatabaseHelper.instance.rawQuery('''
        SELECT c.*, tt.id as type_id, tt.name as type_name, tt.action as type_action
        FROM ${AppConstants.tableTransactionCategories} c
        LEFT JOIN ${AppConstants.tableTransactionTypes} tt ON c.transaction_type_id = tt.id
        ORDER BY tt.action, c.name
      ''');

      _categories = rows.map((row) {
        final typeModel = TransactionTypeModel(
          id: row['transaction_type_id'] as String? ?? '',
          name: row['type_name'] as String? ?? '',
          action: row['type_action'] as String? ?? AppConstants.actionNeutral,
        );
        return TransactionCategoryModel.fromMap(row).copyWith(
          transactionType: typeModel,
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('[TransactionProvider] loadCategories error: $e');
    }
  }

  Future<void> loadTransactionTypes() async {
    try {
      final rows = await DatabaseHelper.instance.query(
        AppConstants.tableTransactionTypes,
        orderBy: 'name ASC',
      );
      _transactionTypes = rows.map(TransactionTypeModel.fromMap).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('[TransactionProvider] loadTransactionTypes error: $e');
    }
  }

  /// Fetch types and categories from server and persist locally.
  Future<void> fetchCategoriesFromServer() async {
    try {
      final types = await ApiService.instance.getTransactionTypes();
      final cats = await ApiService.instance.getTransactionCategories();

      final db = DatabaseHelper.instance;
      for (final type in types) {
        await db.insert(AppConstants.tableTransactionTypes, type.toMap());
      }
      for (final cat in cats) {
        await db.insert(AppConstants.tableTransactionCategories, cat.toMap());
      }
      await loadCategories();
      await loadTransactionTypes();
    } catch (e) {
      debugPrint('[TransactionProvider] fetchCategoriesFromServer error: $e');
    }
  }

  /// Add a transaction locally. Set synced_at = null for pending sync.
  Future<TransactionModel> addTransaction({
    required String walletId,
    required String transactionCategoryId,
    required String name,
    required double amount,
    String? note,
  }) async {
    final now = DateFormatter.toApiString(DateTime.now());
    final tx = TransactionModel(
      id: UlidGenerator.generate(),
      walletId: walletId,
      transactionCategoryId: transactionCategoryId,
      name: name,
      amount: amount.toString(),
      note: note,
      syncedAt: null, // pending
      createdAt: now,
      updatedAt: now,
    );

    await DatabaseHelper.instance.insert(
      AppConstants.tableTransactions,
      tx.toMap(),
    );

    _transactions.insert(0, tx);
    notifyListeners();

    return tx;
  }

  /// Soft-delete a transaction locally, mark as unsynced (tombstone).
  Future<void> deleteTransaction(String id) async {
    final now = DateFormatter.toApiString(DateTime.now());
    await DatabaseHelper.instance.update(
      AppConstants.tableTransactions,
      {'deleted_at': now, 'synced_at': null},
      'id = ?',
      [id],
    );

    final idx = _transactions.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _transactions.removeAt(idx);
    }
    notifyListeners();
  }

  List<TransactionCategoryModel> getCategoriesByAction(String action) {
    return _categories
        .where((c) => c.transactionType?.action == action)
        .toList();
  }
}
