import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_model.dart';
import '../models/student_model.dart';
import 'student_service.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StudentService _studentService = StudentService();

  // Save attendance records for multiple students
  Future<void> saveAttendanceRecords({
    required List<String> presentStudentRolls,
    required String teacherId,
    required String subject,
    required String section,
    DateTime? date,
    String? remarks,
  }) async {
    try {
      final attendanceDate = date ?? DateTime.now();
      final batch = _firestore.batch();

      // Get all students in the section
      List<Student> sectionStudents = await _studentService.getStudentsBySection(section);
      
      for (Student student in sectionStudents) {
        bool isPresent = presentStudentRolls.contains(student.rollNumber);
        
        // Create attendance record
        AttendanceRecord record = AttendanceRecord(
          id: '', // Will be set by Firestore
          studentRollNumber: student.rollNumber,
          studentId: student.id,
          teacherId: teacherId,
          subject: subject,
          section: section,
          date: attendanceDate,
          isPresent: isPresent,
          remarks: remarks,
        );

        // Add to batch
        DocumentReference docRef = _firestore.collection('attendance').doc();
        batch.set(docRef, record.toMap());
      }

      // Commit batch
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to save attendance records: ${e.toString()}');
    }
  }

  // Get attendance records for a specific student
  Future<List<AttendanceRecord>> getStudentAttendance({
    required String studentRollNumber,
    DateTime? startDate,
    DateTime? endDate,
    String? subject,
  }) async {
    try {
      // Use a simpler query to avoid composite index requirements
      QuerySnapshot querySnapshot = await _firestore
          .collection('attendance')
          .where('studentRollNumber', isEqualTo: studentRollNumber)
          .get();
      
      List<AttendanceRecord> records = querySnapshot.docs
          .map((doc) => AttendanceRecord.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      // Filter by date and subject in memory to avoid composite index requirements
      if (startDate != null) {
        records = records.where((record) => record.date.isAfter(startDate) || record.date.isAtSameMomentAs(startDate)).toList();
      }
      
      if (endDate != null) {
        records = records.where((record) => record.date.isBefore(endDate) || record.date.isAtSameMomentAs(endDate)).toList();
      }

      if (subject != null && subject.isNotEmpty) {
        records = records.where((record) => record.subject == subject).toList();
      }

      // Sort by date descending
      records.sort((a, b) => b.date.compareTo(a.date));
      
      return records;
    } catch (e) {
      throw Exception('Failed to get student attendance: ${e.toString()}');
    }
  }

  // Get attendance summary for a student
  Future<AttendanceSummary> getStudentAttendanceSummary({
    required String studentRollNumber,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Get student details
      Student? student = await _studentService.getStudentByRollNumber(studentRollNumber);
      if (student == null) {
        throw Exception('Student not found');
      }

      // Get attendance records
      List<AttendanceRecord> records = await getStudentAttendance(
        studentRollNumber: studentRollNumber,
        startDate: startDate,
        endDate: endDate,
      );

      // Calculate overall statistics
      int totalClasses = records.length;
      int attendedClasses = records.where((record) => record.isPresent).length;
      double attendancePercentage = totalClasses > 0 ? (attendedClasses / totalClasses) * 100 : 0.0;

      // Calculate subject-wise statistics
      Map<String, SubjectAttendance> subjectWise = {};
      Map<String, List<AttendanceRecord>> subjectRecords = {};

      // Group records by subject
      for (AttendanceRecord record in records) {
        if (!subjectRecords.containsKey(record.subject)) {
          subjectRecords[record.subject] = [];
        }
        subjectRecords[record.subject]!.add(record);
      }

      // Calculate subject-wise attendance
      subjectRecords.forEach((subject, subjectRecordList) {
        int subjectTotal = subjectRecordList.length;
        int subjectAttended = subjectRecordList.where((record) => record.isPresent).length;
        double subjectPercentage = subjectTotal > 0 ? (subjectAttended / subjectTotal) * 100 : 0.0;

        subjectWise[subject] = SubjectAttendance(
          subject: subject,
          totalClasses: subjectTotal,
          attendedClasses: subjectAttended,
          percentage: subjectPercentage,
        );
      });

      return AttendanceSummary(
        studentRollNumber: studentRollNumber,
        studentId: student.id,
        studentName: student.name,
        totalClasses: totalClasses,
        attendedClasses: attendedClasses,
        attendancePercentage: attendancePercentage,
        subjectWise: subjectWise,
      );
    } catch (e) {
      throw Exception('Failed to get attendance summary: ${e.toString()}');
    }
  }

  // Get attendance for a specific date and section
  Future<List<AttendanceRecord>> getAttendanceByDateAndSection({
    required DateTime date,
    required String section,
    String? subject,
  }) async {
    try {
      // Use simpler query and filter in memory
      QuerySnapshot querySnapshot = await _firestore
          .collection('attendance')
          .where('section', isEqualTo: section)
          .get();
      
      List<AttendanceRecord> records = querySnapshot.docs
          .map((doc) => AttendanceRecord.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      // Filter by date in memory
      DateTime startOfDay = DateTime(date.year, date.month, date.day);
      DateTime endOfDay = DateTime(date.year, date.month, date.day + 1);
      
      records = records.where((record) => 
        record.date.isAfter(startOfDay) || record.date.isAtSameMomentAs(startOfDay) &&
        record.date.isBefore(endOfDay)
      ).toList();

      if (subject != null && subject.isNotEmpty) {
        records = records.where((record) => record.subject == subject).toList();
      }
      
      return records;
    } catch (e) {
      throw Exception('Failed to get attendance by date and section: ${e.toString()}');
    }
  }

  // Get recent attendance records for a student (last 10 records)
  Future<List<AttendanceRecord>> getRecentAttendance(String studentRollNumber) async {
    try {
      // Get all records for the student and sort in memory
      QuerySnapshot querySnapshot = await _firestore
          .collection('attendance')
          .where('studentRollNumber', isEqualTo: studentRollNumber)
          .get();
      
      List<AttendanceRecord> records = querySnapshot.docs
          .map((doc) => AttendanceRecord.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      
      // Sort by date descending and take first 10
      records.sort((a, b) => b.date.compareTo(a.date));
      
      return records.take(10).toList();
    } catch (e) {
      throw Exception('Failed to get recent attendance: ${e.toString()}');
    }
  }

  // Delete attendance record
  Future<void> deleteAttendanceRecord(String recordId) async {
    try {
      await _firestore.collection('attendance').doc(recordId).delete();
    } catch (e) {
      throw Exception('Failed to delete attendance record: ${e.toString()}');
    }
  }

  // Update attendance record
  Future<void> updateAttendanceRecord(String recordId, AttendanceRecord record) async {
    try {
      await _firestore.collection('attendance').doc(recordId).update(record.toMap());
    } catch (e) {
      throw Exception('Failed to update attendance record: ${e.toString()}');
    }
  }

  // Get attendance statistics for teacher dashboard
  Future<Map<String, dynamic>> getAttendanceStatistics({
    required String section,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Use simpler query and filter in memory
      QuerySnapshot querySnapshot = await _firestore
          .collection('attendance')
          .where('section', isEqualTo: section)
          .get();
      
      List<AttendanceRecord> records = querySnapshot.docs
          .map((doc) => AttendanceRecord.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      // Filter by date in memory
      if (startDate != null) {
        records = records.where((record) => record.date.isAfter(startDate) || record.date.isAtSameMomentAs(startDate)).toList();
      }
      
      if (endDate != null) {
        records = records.where((record) => record.date.isBefore(endDate) || record.date.isAtSameMomentAs(endDate)).toList();
      }

      int totalRecords = records.length;
      int presentRecords = records.where((record) => record.isPresent).length;
      double overallPercentage = totalRecords > 0 ? (presentRecords / totalRecords) * 100 : 0.0;

      // Get unique students count
      Set<String> uniqueStudents = records.map((record) => record.studentRollNumber).toSet();
      int totalStudents = uniqueStudents.length;

      return {
        'totalRecords': totalRecords,
        'presentRecords': presentRecords,
        'absentRecords': totalRecords - presentRecords,
        'overallPercentage': overallPercentage,
        'totalStudents': totalStudents,
      };
    } catch (e) {
      throw Exception('Failed to get attendance statistics: ${e.toString()}');
    }
  }
}