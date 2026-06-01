import 'wallet.dart';
import 'transaction_category.dart';

class TransactionModel {
  final String id;
  final String walletId;
  final String transactionCategoryId;
  final String name;
  final String amount;
  final String? note;
  final String? photoUrl;
  final String? syncedAt; // null = pending sync
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;

  // Joined data (not stored in SQLite)
  final WalletModel? wallet;
  final TransactionCategoryModel? transactionCategory;

  const TransactionModel({
    required this.id,
    required this.walletId,
    required this.transactionCategoryId,
    required this.name,
    required this.amount,
    this.note,
    this.photoUrl,
    this.syncedAt,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.wallet,
    this.transactionCategory,
  });

  double get amountDouble => double.tryParse(amount) ?? 0.0;
  bool get isSynced => syncedAt != null;
  bool get isDeleted => deletedAt != null;

  bool get isIncome {
    final action = transactionCategory?.transactionType?.action;
    return action == 'addition';
  }

  bool get isExpense {
    final action = transactionCategory?.transactionType?.action;
    return action == 'deduction';
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id'] as String,
        walletId: json['wallet_id'] as String? ??
            (json['wallet'] != null
                ? (json['wallet'] as Map<String, dynamic>)['id'] as String
                : ''),
        transactionCategoryId: json['transaction_category_id'] as String? ??
            (json['transaction_category'] != null
                ? (json['transaction_category'] as Map<String, dynamic>)['id']
                    as String
                : ''),
        name: json['name'] as String,
        amount: (json['amount'] ?? '0').toString(),
        note: json['note'] as String?,
        photoUrl: json['photo_url'] as String?,
        syncedAt: json['synced_at'] as String?,
        createdAt: json['created_at'] as String?,
        updatedAt: json['updated_at'] as String?,
        deletedAt: json['deleted_at'] as String?,
        wallet: json['wallet'] != null
            ? WalletModel.fromJson(json['wallet'] as Map<String, dynamic>)
            : null,
        transactionCategory: json['transaction_category'] != null
            ? TransactionCategoryModel.fromJson(
                json['transaction_category'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'wallet_id': walletId,
        'transaction_category_id': transactionCategoryId,
        'name': name,
        'amount': amount,
        'note': note,
        'photo_url': photoUrl,
        'synced_at': syncedAt,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'deleted_at': deletedAt,
      };

  /// Payload for POST /sync/transactions
  Map<String, dynamic> toSyncPayload() => {
        'id': id,
        'wallet_id': walletId,
        'transaction_category_id': transactionCategoryId,
        'name': name,
        'amount': amountDouble,
        'note': note,
        'created_at': createdAt,
        'deleted_at': deletedAt,
      };

  factory TransactionModel.fromMap(Map<String, dynamic> map) =>
      TransactionModel(
        id: map['id'] as String,
        walletId: map['wallet_id'] as String,
        transactionCategoryId: map['transaction_category_id'] as String,
        name: map['name'] as String,
        amount: (map['amount'] ?? '0').toString(),
        note: map['note'] as String?,
        photoUrl: map['photo_url'] as String?,
        syncedAt: map['synced_at'] as String?,
        createdAt: map['created_at'] as String?,
        updatedAt: map['updated_at'] as String?,
        deletedAt: map['deleted_at'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'wallet_id': walletId,
        'transaction_category_id': transactionCategoryId,
        'name': name,
        'amount': amount,
        'note': note,
        'photo_url': photoUrl,
        'synced_at': syncedAt,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'deleted_at': deletedAt,
      };

  TransactionModel copyWith({
    String? id,
    String? walletId,
    String? transactionCategoryId,
    String? name,
    String? amount,
    String? note,
    String? photoUrl,
    String? syncedAt,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
    WalletModel? wallet,
    TransactionCategoryModel? transactionCategory,
  }) =>
      TransactionModel(
        id: id ?? this.id,
        walletId: walletId ?? this.walletId,
        transactionCategoryId:
            transactionCategoryId ?? this.transactionCategoryId,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        note: note ?? this.note,
        photoUrl: photoUrl ?? this.photoUrl,
        syncedAt: syncedAt ?? this.syncedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        wallet: wallet ?? this.wallet,
        transactionCategory: transactionCategory ?? this.transactionCategory,
      );
}
