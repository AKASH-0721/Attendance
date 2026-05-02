import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/teacher_model.dart';

class TeacherService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Update teacher profile
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

  // Upload teacher photo
  Future<String> uploadTeacherPhoto(String teacherId, File imageFile) async {
    try {
      String fileName = 'teacher_photos/$teacherId.jpg';
      Reference ref = _storage.ref().child(fileName);
      
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload photo: ${e.toString()}');
    }
  }

  // Get all teachers
  Future<List<Teacher>> getAllTeachers() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('teachers').get();
      return querySnapshot.docs
          .map((doc) => Teacher.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get teachers: ${e.toString()}');
    }
  }

  // Get teacher by ID
  Future<Teacher?> getTeacherById(String teacherId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('teachers').doc(teacherId).get();
      if (doc.exists) {
        return Teacher.fromMap(teacherId, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get teacher: ${e.toString()}');
    }
  }

  // Delete teacher
  Future<void> deleteTeacher(String teacherId) async {
    try {
      await _firestore.collection('teachers').doc(teacherId).delete();
    } catch (e) {
      throw Exception('Failed to delete teacher: ${e.toString()}');
    }
  }

  // Search teachers by name or email
  Future<List<Teacher>> searchTeachers(String query) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('teachers')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .get();
      
      return querySnapshot.docs
          .map((doc) => Teacher.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to search teachers: ${e.toString()}');
    }
  }
}