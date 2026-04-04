import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Login and return role
  Future<String> login(String email, String password) async {
    UserCredential cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    final doc = await _firestore
        .collection('users')
        .doc(cred.user!.uid)
        .get();
    return doc['role'] ?? 'client';
  }

  // Register and save user data
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    await _firestore.collection('users').doc(cred.user!.uid).set({
      'fullName': fullName.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'role': role.toLowerCase(),
      'createdAt': Timestamp.now(),
    });
  }

  // Get role of current user
  Future<String> getRole() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 'client';
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc['role'] ?? 'client';
  }

  // Get full user data
  Future<Map<String, dynamic>> getUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return {};
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data() ?? {};
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Password reset
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}