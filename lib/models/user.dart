class UserModel {
  final String id;
  final String name;
  final String email;
  final String? emailVerifiedAt;
  final String? createdAt;
  final String? updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        emailVerifiedAt: json['email_verified_at'] as String?,
        createdAt: json['created_at'] as String?,
        updatedAt: json['updated_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'email_verified_at': emailVerifiedAt,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel.fromJson(map);

  Map<String, dynamic> toMap() => toJson();

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? emailVerifiedAt,
    String? createdAt,
    String? updatedAt,
  }) =>
      UserModel(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
