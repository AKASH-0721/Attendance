class AttendanceRecord {
  final String id;
  final String studentRollNumber;
  final String studentId;
  final String teacherId;
  final String subject;
  final String section;
  final DateTime date;
  final bool isPresent;
  final String? remarks;

  AttendanceRecord({
    required this.id,
    required this.studentRollNumber,
    required this.studentId,
    required this.teacherId,
    required this.subject,
    required this.section,
    required this.date,
    required this.isPresent,
    this.remarks,
  });

  // Convert AttendanceRecord object → Firestore map
  Map<String, dynamic> toMap() {
    return {
      'studentRollNumber': studentRollNumber,
      'studentId': studentId,
      'teacherId': teacherId,
      'subject': subject,
      'section': section,
      'date': date.toIso8601String(),
      'isPresent': isPresent,
      'remarks': remarks,
    };
  }

  // Convert Firestore map → AttendanceRecord object
  factory AttendanceRecord.fromMap(String id, Map<String, dynamic> data) {
    return AttendanceRecord(
      id: id,
      studentRollNumber: data['studentRollNumber'] ?? '',
      studentId: data['studentId'] ?? '',
      teacherId: data['teacherId'] ?? '',
      subject: data['subject'] ?? '',
      section: data['section'] ?? '',
      date: DateTime.parse(data['date'] ?? DateTime.now().toIso8601String()),
      isPresent: data['isPresent'] ?? false,
      remarks: data['remarks'],
    );
  }

  // Create a copy with updated fields
  AttendanceRecord copyWith({
    String? id,
    String? studentRollNumber,
    String? studentId,
    String? teacherId,
    String? subject,
    String? section,
    DateTime? date,
    bool? isPresent,
    String? remarks,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      studentRollNumber: studentRollNumber ?? this.studentRollNumber,
      studentId: studentId ?? this.studentId,
      teacherId: teacherId ?? this.teacherId,
      subject: subject ?? this.subject,
      section: section ?? this.section,
      date: date ?? this.date,
      isPresent: isPresent ?? this.isPresent,
      remarks: remarks ?? this.remarks,
    );
  }
}

class AttendanceSummary {
  final String studentRollNumber;
  final String studentId;
  final String studentName;
  final int totalClasses;
  final int attendedClasses;
  final double attendancePercentage;
  final Map<String, SubjectAttendance> subjectWise;

  AttendanceSummary({
    required this.studentRollNumber,
    required this.studentId,
    required this.studentName,
    required this.totalClasses,
    required this.attendedClasses,
    required this.attendancePercentage,
    required this.subjectWise,
  });
}

class SubjectAttendance {
  final String subject;
  final int totalClasses;
  final int attendedClasses;
  final double percentage;

  SubjectAttendance({
    required this.subject,
    required this.totalClasses,
    required this.attendedClasses,
    required this.percentage,
  });
}