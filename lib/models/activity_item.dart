import 'transaction.dart';
import 'transfer.dart';

/// Represents either a [TransactionModel] or a [TransferModel] in the
/// unified activity feed (Transaksi Terkini & Semua Aktivitas).
class ActivityItem {
  final TransactionModel? transaction;
  final TransferModel? transfer;

  /// The date used for sorting and date-group headers.
  final DateTime date;

  const ActivityItem._({
    this.transaction,
    this.transfer,
    required this.date,
  });

  factory ActivityItem.fromTransaction(TransactionModel t) {
    final date =
        DateTime.tryParse(t.createdAt ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
    return ActivityItem._(transaction: t, date: date);
  }

  factory ActivityItem.fromTransfer(TransferModel tf) {
    // Prefer transferDate; fall back to createdAt if unparseable
    final date =
        DateTime.tryParse(tf.transferDate) ??
        DateTime.tryParse(tf.createdAt ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return ActivityItem._(transfer: tf, date: date);
  }

  bool get isTransfer => transfer != null;
  bool get isTransaction => transaction != null;
}
