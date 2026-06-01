import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/ulid_generator.dart';
import '../core/utils/formatters.dart';
import '../database/database_helper.dart';
import '../models/transfer.dart';
import '../models/wallet.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class WalletProvider extends ChangeNotifier {
  List<WalletModel> _wallets = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<WalletModel> get wallets =>
      _wallets.where((w) => w.deletedAt == null).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get totalBalance =>
      wallets.fold(0.0, (sum, w) => sum + w.balanceDouble);

  void updateAuth(AuthProvider auth) {
    if (auth.isAuthenticated) {
      loadFromLocal();
    } else {
      _wallets = [];
      notifyListeners();
    }
  }

  /// Load wallets from local SQLite.
  Future<void> loadFromLocal() async {
    _isLoading = true;
    notifyListeners();
    try {
      final rows = await DatabaseHelper.instance.query(
        AppConstants.tableWallets,
        where: 'deleted_at IS NULL',
        orderBy: 'created_at ASC',
      );
      _wallets = rows.map(WalletModel.fromMap).toList();
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Sync wallets from server and persist locally.
  Future<void> fetchFromServer() async {
    try {
      final serverWallets = await ApiService.instance.getWallets();
      final db = DatabaseHelper.instance;
      for (final wallet in serverWallets) {
        await db.insert(AppConstants.tableWallets, wallet.toMap());
      }
      await loadFromLocal();
    } catch (e) {
      debugPrint('[WalletProvider] fetchFromServer error: $e');
    }
  }

  /// Create wallet locally (for offline use) and optionally push to server.
  Future<WalletModel?> createWallet({
    required String name,
    required String type,
    double balance = 0.0,
  }) async {
    final now = DateFormatter.toApiString(DateTime.now());
    final wallet = WalletModel(
      id: UlidGenerator.generate(),
      name: name,
      type: type,
      balance: balance.toString(),
      createdAt: now,
      updatedAt: now,
    );

    await DatabaseHelper.instance.insert(
      AppConstants.tableWallets,
      wallet.toMap(),
    );

    _wallets.add(wallet);
    notifyListeners();

    // Try to push to server
    try {
      final serverWallet = await ApiService.instance.storeWallet(
        name: name,
        type: type,
        balance: balance,
      );
      // Update local with server-assigned ID if needed
      await DatabaseHelper.instance.update(
        AppConstants.tableWallets,
        serverWallet.toMap(),
        'id = ?',
        [wallet.id],
      );
    } catch (e) {
      debugPrint('[WalletProvider] createWallet server error: $e');
    }

    return wallet;
  }

  /// Update wallet and sync to server.
  Future<void> updateWallet(
    String id, {
    String? name,
    String? type,
    double? balance,
  }) async {
    final existing = _wallets.indexWhere((w) => w.id == id);
    if (existing == -1) return;

    final updated = _wallets[existing].copyWith(
      name: name,
      type: type,
      balance: balance?.toString(),
      updatedAt: DateFormatter.toApiString(DateTime.now()),
    );

    await DatabaseHelper.instance.update(
      AppConstants.tableWallets,
      updated.toMap(),
      'id = ?',
      [id],
    );

    _wallets[existing] = updated;
    notifyListeners();

    try {
      await ApiService.instance.updateWallet(
        id,
        name: name,
        type: type,
        balance: balance,
      );
    } catch (e) {
      debugPrint('[WalletProvider] updateWallet server error: $e');
    }
  }

  /// Soft-delete wallet locally and on server.
  Future<void> deleteWallet(String id) async {
    final now = DateFormatter.toApiString(DateTime.now());
    await DatabaseHelper.instance.update(
      AppConstants.tableWallets,
      {'deleted_at': now},
      'id = ?',
      [id],
    );

    _wallets.removeWhere((w) => w.id == id);
    notifyListeners();

    try {
      await ApiService.instance.deleteWallet(id);
    } catch (e) {
      debugPrint('[WalletProvider] deleteWallet server error: $e');
    }
  }

  WalletModel? getById(String id) {
    try {
      return _wallets.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Mutate a wallet's balance locally (SQLite + in-memory).
  /// [delta] is positive for credit, negative for debit.
  Future<void> mutateBalance(String walletId, double delta) async {
    if (delta == 0) return;

    // Update SQLite atomically
    await DatabaseHelper.instance.rawUpdate(
      'UPDATE ${AppConstants.tableWallets}'
      ' SET balance = CAST((CAST(balance AS REAL) + ?) AS TEXT),'
      ' updated_at = ? WHERE id = ?',
      [delta, DateFormatter.toApiString(DateTime.now()), walletId],
    );

    // Mirror in memory so UI reflects instantly
    final idx = _wallets.indexWhere((w) => w.id == walletId);
    if (idx != -1) {
      final newBalance = _wallets[idx].balanceDouble + delta;
      _wallets[idx] = _wallets[idx].copyWith(
        balance: newBalance.toStringAsFixed(2),
      );
      notifyListeners();
    }
  }

  /// Save a transfer locally first, mutate wallet balances instantly,
  /// then push to the server in the background (fire-and-forget).
  Future<void> doTransfer({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    double fee = 0.0,
    required String transferDate,
    String? note,
  }) async {
    final now = DateFormatter.toApiString(DateTime.now());
    final transfer = TransferModel(
      id: UlidGenerator.generate(),
      fromWalletId: fromWalletId,
      toWalletId: toWalletId,
      amount: amount.toString(),
      fee: fee.toString(),
      transferDate: transferDate,
      note: note,
      createdAt: now,
      updatedAt: now,
    );

    // 1. Persist transfer locally
    await DatabaseHelper.instance.insert(
      AppConstants.tableTransfers,
      transfer.toMap(),
    );

    // 2. Instantly mutate both wallet balances
    await mutateBalance(fromWalletId, -(amount + fee));
    await mutateBalance(toWalletId, amount);

    // 3. Fire-and-forget: push to server in background
    ApiService.instance.storeTransfer(
      fromWalletId: fromWalletId,
      toWalletId: toWalletId,
      amount: amount,
      fee: fee > 0 ? fee : null,
      transferDate: transferDate,
      note: note,
    ).then((_) {
      debugPrint('[WalletProvider] Transfer synced to server: ${transfer.id}');
    }).catchError((dynamic e) {
      debugPrint('[WalletProvider] Transfer background sync failed: $e');
      // Data stays in SQLite — will remain available locally.
    });
  }
}
