class Teacher {
  final String id;
  final String name;
  final String photo;
  final String designation;
  final List<String> classes;
  final String mail;

  Teacher({
    required this.id,
    required this.name,
    required this.photo,
    required this.designation,
    required this.classes,
    required this.mail,
  });

  // Convert Teacher object → Firestore map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'photo': photo,
      'designation': designation,
      'classes': classes,
      'mail': mail,
    };
  }

  // Convert Firestore map → Teacher object
  factory Teacher.fromMap(String id, Map<String, dynamic> data) {
    return Teacher(
      id: id,
      name: data['name'] ?? '',
      photo: data['photo'] ?? '',
      designation: data['designation'] ?? '',
      classes: List<String>.from(data['classes'] ?? []),
      mail: data['mail'] ?? '',
    );
  }

  // Create a copy with updated fields
  Teacher copyWith({
    String? id,
    String? name,
    String? photo,
    String? designation,
    List<String>? classes,
    String? mail,
  }) {
    return Teacher(
      id: id ?? this.id,
      name: name ?? this.name,
      photo: photo ?? this.photo,
      designation: designation ?? this.designation,
      classes: classes ?? this.classes,
      mail: mail ?? this.mail,
    );
  }
}
