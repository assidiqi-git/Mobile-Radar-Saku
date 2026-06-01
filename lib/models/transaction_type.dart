import '../core/constants/app_constants.dart';

class TransactionTypeModel {
  final String id;
  final String name;
  final String action; // addition, deduction, neutral
  final String? description;
  final String? createdAt;
  final String? updatedAt;

  const TransactionTypeModel({
    required this.id,
    required this.name,
    required this.action,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  bool get isAddition => action == AppConstants.actionAddition;
  bool get isDeduction => action == AppConstants.actionDeduction;
  bool get isNeutral => action == AppConstants.actionNeutral;

  factory TransactionTypeModel.fromJson(Map<String, dynamic> json) =>
      TransactionTypeModel(
        id: json['id'] as String,
        name: json['name'] as String,
        action: json['action'] as String,
        description: json['description'] as String?,
        createdAt: json['created_at'] as String?,
        updatedAt: json['updated_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'action': action,
        'description': description,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory TransactionTypeModel.fromMap(Map<String, dynamic> map) =>
      TransactionTypeModel.fromJson(map);

  Map<String, dynamic> toMap() => toJson();
}
