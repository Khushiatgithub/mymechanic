/// Authenticated customer model representing a MyMechanic user account.
///
/// Phase 3 Step 4.4: Authentication & User Identity Foundation.
/// Matches the backend User schema and JSON serialization contract.
class AuthUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final bool isActive;
  final String? profileImage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.isActive = true,
    this.profileImage,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates an [AuthUser] from backend JSON dictionary.
  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: json['phone'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      profileImage: json['profileImage'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  /// Converts the [AuthUser] to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      if (phone != null) 'phone': phone,
      'isActive': isActive,
      if (profileImage != null) 'profileImage': profileImage,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  AuthUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    bool? isActive,
    String? profileImage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AuthUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          phone == other.phone &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      email.hashCode ^
      phone.hashCode ^
      isActive.hashCode;

  @override
  String toString() => 'AuthUser(id: $id, name: $name, email: $email, isActive: $isActive)';
}
