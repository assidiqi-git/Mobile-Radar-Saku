class WalletModel {
  final String id;
  final String name;
  final String type; // checking, savings, cash, investment
  final String balance;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;

  const WalletModel({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  double get balanceDouble => double.tryParse(balance) ?? 0.0;

  bool get isDeleted => deletedAt != null;

  factory WalletModel.fromJson(Map<String, dynamic> json) => WalletModel(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        balance: (json['balance'] ?? '0').toString(),
        createdAt: json['created_at'] as String?,
        updatedAt: json['updated_at'] as String?,
        deletedAt: json['deleted_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'balance': balance,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'deleted_at': deletedAt,
      };

  factory WalletModel.fromMap(Map<String, dynamic> map) => WalletModel.fromJson(map);

  Map<String, dynamic> toMap() => toJson();

  WalletModel copyWith({
    String? id,
    String? name,
    String? type,
    String? balance,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
  }) =>
      WalletModel(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        balance: balance ?? this.balance,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
      );

  /// Returns icon name for wallet type.
  String get typeIcon {
    switch (type) {
      case 'checking':
        return 'account_balance';
      case 'savings':
        return 'savings';
      case 'cash':
        return 'payments';
      case 'investment':
        return 'trending_up';
      default:
        return 'wallet';
    }
  }

  /// Returns human-readable wallet type.
  String get typeLabel {
    switch (type) {
      case 'checking':
        return 'Giro';
      case 'savings':
        return 'Tabungan';
      case 'cash':
        return 'Tunai';
      case 'investment':
        return 'Investasi';
      default:
        return type;
    }
  }
}
