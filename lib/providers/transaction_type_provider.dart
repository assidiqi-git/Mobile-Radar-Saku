import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/formatters.dart';
import '../core/utils/ulid_generator.dart';
import '../database/database_helper.dart';
import '../models/transaction_type.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class TransactionTypeProvider extends ChangeNotifier {
  List<TransactionTypeModel> _types = [];
  bool _isLoading = false;
  String? _errorMessage;

  /// All non-deleted transaction types.
  List<TransactionTypeModel> get types => _types;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final _db = DatabaseHelper.instance;

  // ---- Auth lifecycle -------------------------------------------------------

  void updateAuth(AuthProvider auth) {
    if (auth.isAuthenticated) {
      loadAll();
    } else {
      _types = [];
      notifyListeners();
    }
  }

  // ---- Read -----------------------------------------------------------------

  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rows = await _db.query(
        AppConstants.tableTransactionTypes,
        where: 'deleted_at IS NULL',
        orderBy: 'name ASC',
      );
      _types = rows.map(TransactionTypeModel.fromMap).toList();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('[TransactionTypeProvider] loadAll error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ---- Create ---------------------------------------------------------------

  Future<TransactionTypeModel> add({
    required String name,
    required String action,
    String? description,
  }) async {
    final now = DateFormatter.toApiString(DateTime.now());
    final model = TransactionTypeModel(
      id: UlidGenerator.generate(),
      name: name,
      action: action,
      description: description,
      createdAt: now,
      updatedAt: now,
    );

    await _db.insert(AppConstants.tableTransactionTypes, {
      ...model.toMap(),
      'sync_status': AppConstants.syncStatusPending,
    });

    _types
      ..add(model)
      ..sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();

    // Background push
    ApiService.instance.storeTransactionType(
      name: name,
      action: action,
      description: description,
    ).then((serverModel) async {
      // Update local db with new ID from server if changed, and set synced
      await _db.update(
        AppConstants.tableTransactionTypes,
        {
          ...serverModel.toMap(),
          'sync_status': AppConstants.syncStatusSynced,
          'sync_error_message': null,
        },
        'id = ?',
        [model.id],
      );
      final idx = _types.indexWhere((t) => t.id == model.id);
      if (idx != -1) {
        _types[idx] = serverModel;
        notifyListeners();
      }
    }).catchError((dynamic e) {
      debugPrint('[TransactionTypeProvider] store push failed: $e');
    });

    return model;
  }

  // ---- Update ---------------------------------------------------------------

  Future<void> update(
    String id, {
    String? name,
    String? action,
    String? description,
  }) async {
    final idx = _types.indexWhere((t) => t.id == id);
    if (idx == -1) return;

    final existing = _types[idx];
    final now = DateFormatter.toApiString(DateTime.now());

    final updated = TransactionTypeModel(
      id: id,
      name: name ?? existing.name,
      action: action ?? existing.action,
      description: description ?? existing.description,
      createdAt: existing.createdAt,
      updatedAt: now,
    );

    await _db.update(
      AppConstants.tableTransactionTypes,
      {
        ...updated.toMap(),
        'sync_status': AppConstants.syncStatusPending,
      },
      'id = ?',
      [id],
    );

    _types[idx] = updated;
    _types.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();

    // Background push
    ApiService.instance.updateTransactionType(
      id,
      name: name,
      action: action,
      description: description,
    ).then((_) async {
      await _db.update(
        AppConstants.tableTransactionTypes,
        {
          'sync_status': AppConstants.syncStatusSynced,
          'sync_error_message': null,
        },
        'id = ?',
        [id],
      );
    }).catchError((dynamic e) {
      debugPrint('[TransactionTypeProvider] update push failed: $e');
    });
  }

  // ---- Delete (soft) --------------------------------------------------------

  Future<void> delete(String id) async {
    // 1. Local Check: pastikan tidak ada kategori yang masih menggunakan tipe ini
    final checkRows = await _db.rawQuery(
      "SELECT COUNT(*) as count FROM ${AppConstants.tableTransactionCategories} WHERE transaction_type_id = ? AND deleted_at IS NULL",
      [id],
    );
    final count = checkRows.first['count'] as int? ?? 0;
    if (count > 0) {
      throw Exception('Tipe ini tidak dapat dihapus karena masih digunakan oleh kategori.');
    }

    // 2. Server Check / Push
    try {
      await ApiService.instance.deleteTransactionType(id);
      // Hard delete locally if server succeeds
      await _db.delete(
        AppConstants.tableTransactionTypes,
        'id = ?',
        [id],
      );
    } catch (e) {
      // If the error is an ApiException with status 409, abort and rethrow
      if (e is ApiException && e.statusCode == 409) {
        throw Exception(e.message);
      }
      
      // Other errors (like offline network error): Soft delete locally
      final now = DateFormatter.toApiString(DateTime.now());
      await _db.update(
        AppConstants.tableTransactionTypes,
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
    _types.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  // ---- Helper ---------------------------------------------------------------

  /// Returns the sync_status for a given type id (reads from DB for accuracy).
  Future<String> syncStatusOf(String id) async {
    final rows = await _db.rawQuery(
      "SELECT sync_status FROM ${AppConstants.tableTransactionTypes} WHERE id = ?",
      [id],
    );
    if (rows.isEmpty) return AppConstants.syncStatusSynced;
    return rows.first['sync_status'] as String? ?? AppConstants.syncStatusSynced;
  }
}
