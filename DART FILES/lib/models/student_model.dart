class Student {
  final String id;
  final String name;
  final String rollNumber;
  final String email;
  final String photo;
  final String section;
  final String department;
  final String year;
  final String phoneNumber;
  final String parentContact;
  final DateTime dateOfBirth;
  final String address;

  Student({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.email,
    required this.photo,
    required this.section,
    required this.department,
    required this.year,
    required this.phoneNumber,
    required this.parentContact,
    required this.dateOfBirth,
    required this.address,
  });

  // Convert Student object → Firestore map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'rollNumber': rollNumber,
      'email': email,
      'photo': photo,
      'section': section,
      'department': department,
      'year': year,
      'phoneNumber': phoneNumber,
      'parentContact': parentContact,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'address': address,
    };
  }

  // Convert Firestore map → Student object
  factory Student.fromMap(String id, Map<String, dynamic> data) {
    return Student(
      id: id,
      name: data['name'] ?? '',
      rollNumber: data['rollNumber'] ?? '',
      email: data['email'] ?? '',
      photo: data['photo'] ?? '',
      section: data['section'] ?? '',
      department: data['department'] ?? '',
      year: data['year'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      parentContact: data['parentContact'] ?? '',
      dateOfBirth: DateTime.parse(data['dateOfBirth'] ?? DateTime.now().toIso8601String()),
      address: data['address'] ?? '',
    );
  }

  // Create a copy with updated fields
  Student copyWith({
    String? id,
    String? name,
    String? rollNumber,
    String? email,
    String? photo,
    String? section,
    String? department,
    String? year,
    String? phoneNumber,
    String? parentContact,
    DateTime? dateOfBirth,
    String? address,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      rollNumber: rollNumber ?? this.rollNumber,
      email: email ?? this.email,
      photo: photo ?? this.photo,
      section: section ?? this.section,
      department: department ?? this.department,
      year: year ?? this.year,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      parentContact: parentContact ?? this.parentContact,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
    );
  }
}