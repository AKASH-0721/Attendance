import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/admin_model.dart';
import '../models/teacher_model.dart';
import '../models/student_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Register new admin
  Future<void> registerAdmin(Admin admin) async {
    try {
      await _firestore
          .collection('admins')
          .doc(admin.id)
          .set(admin.toMap());
    } catch (e) {
      throw Exception('Failed to register admin: ${e.toString()}');
    }
  }

  // Get admin by ID
  Future<Admin?> getAdminById(String adminId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('admins').doc(adminId).get();
      if (doc.exists) {
        return Admin.fromMap(adminId, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get admin: ${e.toString()}');
    }
  }

  // Get all admins
  Future<List<Admin>> getAllAdmins() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('admins').get();
      return querySnapshot.docs
          .map((doc) => Admin.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get admins: ${e.toString()}');
    }
  }

  // Update admin profile
  Future<void> updateAdminProfile(String adminId, Admin admin) async {
    try {
      await _firestore
          .collection('admins')
          .doc(adminId)
          .update(admin.toMap());
    } catch (e) {
      throw Exception('Failed to update admin profile: ${e.toString()}');
    }
  }

  // Delete admin
  Future<void> deleteAdmin(String adminId) async {
    try {
      await _firestore.collection('admins').doc(adminId).delete();
    } catch (e) {
      throw Exception('Failed to delete admin: ${e.toString()}');
    }
  }

  // Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      // Get counts
      final teachersSnapshot = await _firestore.collection('teachers').get();
      final studentsSnapshot = await _firestore.collection('students').get();
      final adminsSnapshot = await _firestore.collection('admins').get();

      // Get students by department
      Map<String, int> departmentCounts = {};
      for (var doc in studentsSnapshot.docs) {
        String department = doc.get('department') ?? 'Unknown';
        departmentCounts[department] = (departmentCounts[department] ?? 0) + 1;
      }

      // Get students by section
      Map<String, int> sectionCounts = {};
      for (var doc in studentsSnapshot.docs) {
        String section = doc.get('section') ?? 'Unknown';
        sectionCounts[section] = (sectionCounts[section] ?? 0) + 1;
      }

      return {
        'totalTeachers': teachersSnapshot.docs.length,
        'totalStudents': studentsSnapshot.docs.length,
        'totalAdmins': adminsSnapshot.docs.length,
        'departmentCounts': departmentCounts,
        'sectionCounts': sectionCounts,
      };
    } catch (e) {
      throw Exception('Failed to get dashboard stats: ${e.toString()}');
    }
  }

  // Get all teachers for admin management
  Future<List<Teacher>> getAllTeachersForAdmin() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('teachers').get();
      return querySnapshot.docs
          .map((doc) => Teacher.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get teachers: ${e.toString()}');
    }
  }

  // Get all students for admin management
  Future<List<Student>> getAllStudentsForAdmin() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('students').get();
      return querySnapshot.docs
          .map((doc) => Student.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get students: ${e.toString()}');
    }
  }

  // Delete teacher (admin function)
  Future<void> deleteTeacher(String teacherId) async {
    try {
      await _firestore.collection('teachers').doc(teacherId).delete();
    } catch (e) {
      throw Exception('Failed to delete teacher: ${e.toString()}');
    }
  }

  // Delete student (admin function)
  Future<void> deleteStudent(String studentId) async {
    try {
      await _firestore.collection('students').doc(studentId).delete();
    } catch (e) {
      throw Exception('Failed to delete student: ${e.toString()}');
    }
  }

  // Update teacher profile (admin function)
  Future<void> updateTeacherProfile(String teacherId, Teacher teacher) async {
    try {
      await _firestore
          .collection('teachers')
          .doc(teacherId)
          .update(teacher.toMap());
    } catch (e) {
      throw Exception('Failed to update teacher profile: ${e.toString()}');
    }
  }

  // Update student profile (admin function)
  Future<void> updateStudentProfile(String studentId, Student student) async {
    try {
      await _firestore
          .collection('students')
          .doc(studentId)
          .update(student.toMap());
    } catch (e) {
      throw Exception('Failed to update student profile: ${e.toString()}');
    }
  }

  // Search users (teachers, students, admins)
  Future<Map<String, List<dynamic>>> searchAllUsers(String query) async {
    try {
      // Search teachers
      QuerySnapshot teachersQuery = await _firestore
          .collection('teachers')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      // Search students
      QuerySnapshot studentsQuery = await _firestore
          .collection('students')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      // Search admins
      QuerySnapshot adminsQuery = await _firestore
          .collection('admins')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      return {
        'teachers': teachersQuery.docs
            .map((doc) => Teacher.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList(),
        'students': studentsQuery.docs
            .map((doc) => Student.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList(),
        'admins': adminsQuery.docs
            .map((doc) => Admin.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList(),
      };
    } catch (e) {
      throw Exception('Failed to search users: ${e.toString()}');
    }
  }

  // Upload admin photo
  Future<String> uploadAdminPhoto(String adminId, File imageFile) async {
    try {
      String fileName = 'admin_photos/$adminId.jpg';
      Reference ref = _storage.ref().child(fileName);
      
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload photo: ${e.toString()}');
    }
  }

  // Check if user is admin
  Future<bool> isAdmin(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('admins').doc(userId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Get recent activities (for admin dashboard)
  Future<List<Map<String, dynamic>>> getRecentActivities() async {
    try {
      // This would typically come from an activities/logs collection
      // For now, we'll return recent user registrations
      
      final recentTeachers = await _firestore
          .collection('teachers')
          .orderBy('mail') // Using mail as a proxy for creation time
          .limit(5)
          .get();

      final recentStudents = await _firestore
          .collection('students')
          .orderBy('email') // Using email as a proxy for creation time
          .limit(5)
          .get();

      List<Map<String, dynamic>> activities = [];

      for (var doc in recentTeachers.docs) {
        activities.add({
          'type': 'teacher_registration',
          'message': 'New teacher registered: ${doc.get('name')}',
          'timestamp': DateTime.now().subtract(Duration(days: activities.length)),
          'icon': 'school',
        });
      }

      for (var doc in recentStudents.docs) {
        activities.add({
          'type': 'student_registration',
          'message': 'New student registered: ${doc.get('name')}',
          'timestamp': DateTime.now().subtract(Duration(days: activities.length + 5)),
          'icon': 'person',
        });
      }

      // Sort by timestamp
      activities.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
      
      return activities.take(10).toList();
    } catch (e) {
      throw Exception('Failed to get recent activities: ${e.toString()}');
    }
  }
}