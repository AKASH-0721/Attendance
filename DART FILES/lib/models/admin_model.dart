class Admin {
  final String id;
  final String name;
  final String email;
  final String photo;
  final String role;
  final List<String> permissions;
  final DateTime createdAt;

  Admin({
    required this.id,
    required this.name,
    required this.email,
    required this.photo,
    required this.role,
    required this.permissions,
    required this.createdAt,
  });

  // Convert Admin object → Firestore map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'photo': photo,
      'role': role,
      'permissions': permissions,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Convert Firestore map → Admin object
  factory Admin.fromMap(String id, Map<String, dynamic> data) {
    return Admin(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      photo: data['photo'] ?? '',
      role: data['role'] ?? 'admin',
      permissions: List<String>.from(data['permissions'] ?? []),
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Create a copy with updated fields
  Admin copyWith({
    String? id,
    String? name,
    String? email,
    String? photo,
    String? role,
    List<String>? permissions,
    DateTime? createdAt,
  }) {
    return Admin(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photo: photo ?? this.photo,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}