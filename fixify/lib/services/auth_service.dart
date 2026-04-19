import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String> getRole() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 'client';
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['role'] as String? ?? 'client';
  }

  Future<Map<String, dynamic>> getUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return {};
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data() ?? {};
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
