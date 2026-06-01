import 'wallet.dart';

class TransferModel {
  final String id;
  final String fromWalletId;
  final String toWalletId;
  final String amount;
  final String fee;
  final String transferDate;
  final String? note;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;

  // Joined (not stored in SQLite)
  final WalletModel? fromWallet;
  final WalletModel? toWallet;

  const TransferModel({
    required this.id,
    required this.fromWalletId,
    required this.toWalletId,
    required this.amount,
    required this.fee,
    required this.transferDate,
    this.note,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.fromWallet,
    this.toWallet,
  });

  double get amountDouble => double.tryParse(amount) ?? 0.0;
  double get feeDouble => double.tryParse(fee) ?? 0.0;
  double get totalDebit => amountDouble + feeDouble;

  factory TransferModel.fromJson(Map<String, dynamic> json) => TransferModel(
        id: json['id'] as String,
        fromWalletId: json['from_wallet_id'] as String? ??
            (json['from_wallet'] != null
                ? (json['from_wallet'] as Map<String, dynamic>)['id'] as String
                : ''),
        toWalletId: json['to_wallet_id'] as String? ??
            (json['to_wallet'] != null
                ? (json['to_wallet'] as Map<String, dynamic>)['id'] as String
                : ''),
        amount: (json['amount'] ?? '0').toString(),
        fee: (json['fee'] ?? '0').toString(),
        transferDate: json['transfer_date'] as String? ?? '',
        note: json['note'] as String?,
        createdAt: json['created_at'] as String?,
        updatedAt: json['updated_at'] as String?,
        deletedAt: json['deleted_at'] as String?,
        fromWallet: json['from_wallet'] != null
            ? WalletModel.fromJson(json['from_wallet'] as Map<String, dynamic>)
            : null,
        toWallet: json['to_wallet'] != null
            ? WalletModel.fromJson(json['to_wallet'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'from_wallet_id': fromWalletId,
        'to_wallet_id': toWalletId,
        'amount': amount,
        'fee': fee,
        'transfer_date': transferDate,
        'note': note,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'deleted_at': deletedAt,
      };

  factory TransferModel.fromMap(Map<String, dynamic> map) => TransferModel(
        id: map['id'] as String,
        fromWalletId: map['from_wallet_id'] as String,
        toWalletId: map['to_wallet_id'] as String,
        amount: (map['amount'] ?? '0').toString(),
        fee: (map['fee'] ?? '0').toString(),
        transferDate: map['transfer_date'] as String? ?? '',
        note: map['note'] as String?,
        createdAt: map['created_at'] as String?,
        updatedAt: map['updated_at'] as String?,
        deletedAt: map['deleted_at'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'from_wallet_id': fromWalletId,
        'to_wallet_id': toWalletId,
        'amount': amount,
        'fee': fee,
        'transfer_date': transferDate,
        'note': note,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'deleted_at': deletedAt,
      };
}
