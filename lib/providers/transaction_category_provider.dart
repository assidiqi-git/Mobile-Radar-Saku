import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/formatters.dart';
import '../core/utils/ulid_generator.dart';
import '../database/database_helper.dart';
import '../models/transaction_category.dart';
import '../models/transaction_type.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class TransactionCategoryProvider extends ChangeNotifier {
  List<TransactionCategoryModel> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  /// All non-deleted transaction categories (with nested type).
  List<TransactionCategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final _db = DatabaseHelper.instance;

  // ---- Auth lifecycle -------------------------------------------------------

  void updateAuth(AuthProvider auth) {
    if (auth.isAuthenticated) {
      loadAll();
    } else {
      _categories = [];
      notifyListeners();
    }
  }

  // ---- Read -----------------------------------------------------------------

  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rows = await _db.rawQuery('''
        SELECT c.*,
          tt.id   AS type_id,
          tt.name AS type_name,
          tt.action AS type_action,
          tt.description AS type_description
        FROM ${AppConstants.tableTransactionCategories} c
        LEFT JOIN ${AppConstants.tableTransactionTypes} tt
          ON c.transaction_type_id = tt.id
        WHERE c.deleted_at IS NULL
        ORDER BY tt.name ASC, c.name ASC
      ''');

      _categories = rows.map((row) {
        final typeModel = row['type_id'] != null
            ? TransactionTypeModel(
                id: row['type_id'] as String,
                name: row['type_name'] as String? ?? '',
                action: row['type_action'] as String? ?? AppConstants.actionNeutral,
                description: row['type_description'] as String?,
              )
            : null;

        return TransactionCategoryModel.fromMap(row).copyWith(
          transactionType: typeModel,
        );
      }).toList();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('[TransactionCategoryProvider] loadAll error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ---- Create ---------------------------------------------------------------

  Future<TransactionCategoryModel> add({
    required String transactionTypeId,
    required String name,
    String? description,
    TransactionTypeModel? typeModel,
  }) async {
    final now = DateFormatter.toApiString(DateTime.now());
    final model = TransactionCategoryModel(
      id: UlidGenerator.generate(),
      transactionTypeId: transactionTypeId,
      name: name,
      description: description,
      transactionType: typeModel,
      createdAt: now,
      updatedAt: now,
    );

    await _db.insert(AppConstants.tableTransactionCategories, {
      ...model.toMap(),
      'sync_status': AppConstants.syncStatusPending,
    });

    _categories.add(model);
    _categories.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();

    // Background push
    ApiService.instance.storeTransactionCategory(
      transactionTypeId: transactionTypeId,
      name: name,
      description: description,
    ).then((serverModel) async {
      final updatedModel = serverModel.copyWith(transactionType: typeModel);
      // Update local db with new ID from server if changed, and set synced
      await _db.update(
        AppConstants.tableTransactionCategories,
        {
          ...updatedModel.toMap(),
          'sync_status': AppConstants.syncStatusSynced,
          'sync_error_message': null,
        },
        'id = ?',
        [model.id],
      );
      final idx = _categories.indexWhere((c) => c.id == model.id);
      if (idx != -1) {
        _categories[idx] = updatedModel;
        notifyListeners();
      }
    }).catchError((dynamic e) {
      debugPrint('[TransactionCategoryProvider] store push failed: $e');
    });

    return model;
  }

  // ---- Update ---------------------------------------------------------------

  Future<void> update(
    String id, {
    String? transactionTypeId,
    String? name,
    String? description,
    TransactionTypeModel? typeModel,
  }) async {
    final idx = _categories.indexWhere((c) => c.id == id);
    if (idx == -1) return;

    final existing = _categories[idx];
    final now = DateFormatter.toApiString(DateTime.now());

    final updated = TransactionCategoryModel(
      id: id,
      transactionTypeId: transactionTypeId ?? existing.transactionTypeId,
      name: name ?? existing.name,
      description: description ?? existing.description,
      transactionType: typeModel ?? existing.transactionType,
      createdAt: existing.createdAt,
      updatedAt: now,
    );

    await _db.update(
      AppConstants.tableTransactionCategories,
      {
        ...updated.toMap(),
        'sync_status': AppConstants.syncStatusPending,
      },
      'id = ?',
      [id],
    );

    _categories[idx] = updated;
    _categories.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();

    // Background push
    ApiService.instance.updateTransactionCategory(
      id,
      transactionTypeId: transactionTypeId,
      name: name,
      description: description,
    ).then((_) async {
      await _db.update(
        AppConstants.tableTransactionCategories,
        {
          'sync_status': AppConstants.syncStatusSynced,
          'sync_error_message': null,
        },
        'id = ?',
        [id],
      );
    }).catchError((dynamic e) {
      debugPrint('[TransactionCategoryProvider] update push failed: $e');
    });
  }

  // ---- Delete (soft) --------------------------------------------------------

  Future<void> delete(String id) async {
    // 1. Local Check: pastikan tidak ada transaksi yang masih menggunakan kategori ini
    final checkRows = await _db.rawQuery(
      "SELECT COUNT(*) as count FROM ${AppConstants.tableTransactions} WHERE transaction_category_id = ? AND deleted_at IS NULL",
      [id],
    );
    final count = checkRows.first['count'] as int? ?? 0;
    if (count > 0) {
      throw Exception('Kategori ini tidak dapat dihapus karena masih digunakan oleh transaksi.');
    }

    // 2. Server Check / Push
    try {
      await ApiService.instance.deleteTransactionCategory(id);
      // Hard delete locally if server succeeds
      await _db.delete(
        AppConstants.tableTransactionCategories,
        'id = ?',
        [id],
      );
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        throw Exception(e.message);
      }

      // Offline or other error -> Soft delete locally
      final now = DateFormatter.toApiString(DateTime.now());
      await _db.update(
        AppConstants.tableTransactionCategories,
        {
          'deleted_at': now,
          'sync_status': AppConstants.syncStatusPending,
          'updated_at': now,
        },
        'id = ?',
        [id],
      );
    }

    // 3. Update UI state
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}
