import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/ulid_generator.dart';
import '../core/utils/formatters.dart';
import '../database/database_helper.dart';
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
}
