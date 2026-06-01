import 'transaction_type.dart';

class TransactionCategoryModel {
  final String id;
  final String transactionTypeId;
  final String name;
  final String? description;
  final TransactionTypeModel? transactionType;
  final String? createdAt;
  final String? updatedAt;

  const TransactionCategoryModel({
    required this.id,
    required this.transactionTypeId,
    required this.name,
    this.description,
    this.transactionType,
    this.createdAt,
    this.updatedAt,
  });

  factory TransactionCategoryModel.fromJson(Map<String, dynamic> json) =>
      TransactionCategoryModel(
        id: json['id'] as String,
        transactionTypeId: json['transaction_type_id'] as String? ??
            (json['transaction_type'] != null
                ? (json['transaction_type'] as Map<String, dynamic>)['id'] as String
                : ''),
        name: json['name'] as String,
        description: json['description'] as String?,
        transactionType: json['transaction_type'] != null
            ? TransactionTypeModel.fromJson(
                json['transaction_type'] as Map<String, dynamic>)
            : null,
        createdAt: json['created_at'] as String?,
        updatedAt: json['updated_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'transaction_type_id': transactionTypeId,
        'name': name,
        'description': description,
        'transaction_type': transactionType?.toJson(),
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  /// For SQLite storage (flat, no nested objects).
  factory TransactionCategoryModel.fromMap(Map<String, dynamic> map) =>
      TransactionCategoryModel(
        id: map['id'] as String,
        transactionTypeId: map['transaction_type_id'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        createdAt: map['created_at'] as String?,
        updatedAt: map['updated_at'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'transaction_type_id': transactionTypeId,
        'name': name,
        'description': description,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  TransactionCategoryModel copyWith({
    String? id,
    String? transactionTypeId,
    String? name,
    String? description,
    TransactionTypeModel? transactionType,
    String? createdAt,
    String? updatedAt,
  }) =>
      TransactionCategoryModel(
        id: id ?? this.id,
        transactionTypeId: transactionTypeId ?? this.transactionTypeId,
        name: name ?? this.name,
        description: description ?? this.description,
        transactionType: transactionType ?? this.transactionType,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
