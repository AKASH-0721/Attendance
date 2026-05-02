import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/student_model.dart';

class StudentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Register new student
  Future<void> registerStudent(Student student) async {
    try {
      await _firestore
          .collection('students')
          .doc(student.id)
          .set(student.toMap());
    } catch (e) {
      throw Exception('Failed to register student: ${e.toString()}');
    }
  }

  // Update student profile
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

  // Upload student photo
  Future<String> uploadStudentPhoto(String studentId, File imageFile) async {
    try {
      String fileName = 'student_photos/$studentId.jpg';
      Reference ref = _storage.ref().child(fileName);
      
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload photo: ${e.toString()}');
    }
  }

  // Get all students
  Future<List<Student>> getAllStudents() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('students').get();
      return querySnapshot.docs
          .map((doc) => Student.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get students: ${e.toString()}');
    }
  }

  // Get students by section
  Future<List<Student>> getStudentsBySection(String section) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('students')
          .where('section', isEqualTo: section)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Student.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get students by section: ${e.toString()}');
    }
  }

  // Get students by department
  Future<List<Student>> getStudentsByDepartment(String department) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('students')
          .where('department', isEqualTo: department)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Student.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get students by department: ${e.toString()}');
    }
  }

  // Get student by ID
  Future<Student?> getStudentById(String studentId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('students').doc(studentId).get();
      if (doc.exists) {
        return Student.fromMap(studentId, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get student: ${e.toString()}');
    }
  }

  // Get student by roll number
  Future<Student?> getStudentByRollNumber(String rollNumber) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('students')
          .where('rollNumber', isEqualTo: rollNumber)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        var doc = querySnapshot.docs.first;
        return Student.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get student by roll number: ${e.toString()}');
    }
  }

  // Delete student
  Future<void> deleteStudent(String studentId) async {
    try {
      await _firestore.collection('students').doc(studentId).delete();
    } catch (e) {
      throw Exception('Failed to delete student: ${e.toString()}');
    }
  }

  // Search students by name or roll number
  Future<List<Student>> searchStudents(String query) async {
    try {
      // Search by name
      QuerySnapshot nameQuery = await _firestore
          .collection('students')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .get();
      
      // Search by roll number
      QuerySnapshot rollQuery = await _firestore
          .collection('students')
          .where('rollNumber', isGreaterThanOrEqualTo: query)
          .where('rollNumber', isLessThanOrEqualTo: query + '\uf8ff')
          .get();
      
      Set<Student> students = {};
      
      // Add results from name search
      for (var doc in nameQuery.docs) {
        students.add(Student.fromMap(doc.id, doc.data() as Map<String, dynamic>));
      }
      
      // Add results from roll number search
      for (var doc in rollQuery.docs) {
        students.add(Student.fromMap(doc.id, doc.data() as Map<String, dynamic>));
      }
      
      return students.toList();
    } catch (e) {
      throw Exception('Failed to search students: ${e.toString()}');
    }
  }

  // Get students count by section
  Future<Map<String, int>> getStudentsCountBySection() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('students').get();
      Map<String, int> sectionCounts = {};
      
      for (var doc in querySnapshot.docs) {
        String section = doc.get('section') ?? 'Unknown';
        sectionCounts[section] = (sectionCounts[section] ?? 0) + 1;
      }
      
      return sectionCounts;
    } catch (e) {
      throw Exception('Failed to get section counts: ${e.toString()}');
    }
  }
}