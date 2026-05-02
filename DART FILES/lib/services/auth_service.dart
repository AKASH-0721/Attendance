import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/teacher_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register teacher with email and password
  Future<UserCredential?> registerTeacher({
    required String email,
    required String password,
    required Teacher teacherData,
  }) async {
    try {
      // Create user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save teacher data to Firestore
      await _firestore
          .collection('teachers')
          .doc(userCredential.user!.uid)
          .set(teacherData.toMap());

      return userCredential;
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  // Login teacher
  Future<UserCredential?> loginTeacher({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  // Get teacher data from Firestore
  Future<Teacher?> getTeacherData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('teachers').doc(uid).get();
      if (doc.exists) {
        return Teacher.fromMap(uid, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get teacher data: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Check if user is teacher
  Future<bool> isTeacher(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('teachers').doc(uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Failed to send password reset email: ${e.toString()}');
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      } else {
        throw Exception('No user logged in');
      }
    } catch (e) {
      throw Exception('Failed to update password: ${e.toString()}');
    }
  }

  // Update email
  Future<void> updateEmail(String newEmail) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updateEmail(newEmail);
      } else {
        throw Exception('No user logged in');
      }
    } catch (e) {
      throw Exception('Failed to update email: ${e.toString()}');
    }
  }

  // Register student with email and password
  Future<UserCredential?> registerStudent({
    required String email,
    required String password,
    required Map<String, dynamic> studentData,
  }) async {
    try {
      // Create user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save student data to Firestore
      await _firestore
          .collection('students')
          .doc(userCredential.user!.uid)
          .set(studentData);

      return userCredential;
    } catch (e) {
      throw Exception('Student registration failed: ${e.toString()}');
    }
  }

  // Register admin with email and password
  Future<UserCredential?> registerAdmin({
    required String email,
    required String password,
    required Map<String, dynamic> adminData,
  }) async {
    try {
      // Create user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save admin data to Firestore
      await _firestore
          .collection('admins')
          .doc(userCredential.user!.uid)
          .set(adminData);

      return userCredential;
    } catch (e) {
      throw Exception('Admin registration failed: ${e.toString()}');
    }
  }

  // Get student data from Firestore
  Future<Map<String, dynamic>?> getStudentData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('students').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get student data: ${e.toString()}');
    }
  }

  // Get admin data from Firestore
  Future<Map<String, dynamic>?> getAdminData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('admins').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get admin data: ${e.toString()}');
    }
  }

  // Check if user is student
  Future<bool> isStudent(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('students').doc(uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Check if user is admin
  Future<bool> isAdmin(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('admins').doc(uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }
}