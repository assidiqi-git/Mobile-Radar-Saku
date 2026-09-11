import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../database/database_helper.dart';
import '../models/transfer.dart';
import '../models/wallet.dart';
import '../providers/auth_provider.dart';

class TransferProvider extends ChangeNotifier {
  List<TransferModel> _transfers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<TransferModel> get transfers =>
      _transfers.where((t) => t.deletedAt == null).toList();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 5 most recent transfers, for the dashboard "Transaksi Terkini" section.
  List<TransferModel> get recentTransfers => transfers.take(5).toList();

  bool _isLoggedIn = false;

  void updateAuth(AuthProvider auth) {
    _isLoggedIn = auth.isAuthenticated || auth.isGuest;
    if (_isLoggedIn) {
      Future.microtask(() => loadTransfers());
    } else {
      Future.microtask(() {
        _transfers = [];
        notifyListeners();
      });
    }
  }

  Future<void> loadTransfers() async {
    _isLoading = true;
    notifyListeners();
    try {
      final rows = await DatabaseHelper.instance.rawQuery('''
        SELECT tf.*,
          fw.name as from_wallet_name, fw.type as from_wallet_type, fw.balance as from_wallet_balance,
          tw.name as to_wallet_name, tw.type as to_wallet_type, tw.balance as to_wallet_balance
        FROM ${AppConstants.tableTransfers} tf
        LEFT JOIN ${AppConstants.tableWallets} fw ON tf.from_wallet_id = fw.id
        LEFT JOIN ${AppConstants.tableWallets} tw ON tf.to_wallet_id = tw.id
        WHERE tf.deleted_at IS NULL
        ORDER BY tf.transfer_date DESC, tf.created_at DESC
      ''');

      _transfers = rows.map((row) {
        WalletModel? fromWallet;
        final fromId = row['from_wallet_id'] as String?;
        if (fromId != null && row['from_wallet_name'] != null) {
          fromWallet = WalletModel(
            id: fromId,
            name: row['from_wallet_name'] as String? ?? '',
            type: row['from_wallet_type'] as String? ?? '',
            balance: row['from_wallet_balance']?.toString() ?? '0',
          );
        }

        WalletModel? toWallet;
        final toId = row['to_wallet_id'] as String?;
        if (toId != null && row['to_wallet_name'] != null) {
          toWallet = WalletModel(
            id: toId,
            name: row['to_wallet_name'] as String? ?? '',
            type: row['to_wallet_type'] as String? ?? '',
            balance: row['to_wallet_balance']?.toString() ?? '0',
          );
        }

        return TransferModel.fromMap(row).copyWith(
          fromWallet: fromWallet,
          toWallet: toWallet,
        );
      }).toList();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('[TransferProvider] loadTransfers error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Filter transfers in-memory.
  List<TransferModel> filterTransfers({
    String? searchText,
    String? walletId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return transfers.where((tf) {
      // 1. Search: note field
      if (searchText != null && searchText.isNotEmpty) {
        final q = searchText.toLowerCase();
        final noteMatch = tf.note?.toLowerCase().contains(q) ?? false;
        final fromMatch =
            tf.fromWallet?.name.toLowerCase().contains(q) ?? false;
        final toMatch = tf.toWallet?.name.toLowerCase().contains(q) ?? false;
        if (!noteMatch && !fromMatch && !toMatch) return false;
      }

      // 2. Wallet filter (either side of the transfer)
      if (walletId != null && walletId.isNotEmpty) {
        if (tf.fromWalletId != walletId && tf.toWalletId != walletId) {
          return false;
        }
      }

      // 3. Date range filter (based on transfer_date)
      if (startDate != null || endDate != null) {
        final tfDate =
            DateTime.tryParse(tf.transferDate) ??
            DateTime.tryParse(tf.createdAt ?? '');
        if (tfDate == null) return false;
        if (startDate != null && tfDate.isBefore(startDate)) return false;
        if (endDate != null) {
          final endOfDay = DateTime(
            endDate.year,
            endDate.month,
            endDate.day,
            23,
            59,
            59,
          );
          if (tfDate.isAfter(endOfDay)) return false;
        }
      }

      return true;
    }).toList();
  }

  /// Notify this provider after a new transfer was saved (e.g. from WalletProvider).
  Future<void> refresh() => loadTransfers();
}
