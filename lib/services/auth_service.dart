import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<String?> get user {
    return _auth.authStateChanges().map((User? user) => user?.uid);
  }

  Future<String?> signIn(String email, String password) async {
    try {
      if (!email.endsWith('@diu.edu.bd')) {
        return 'Only students from Daffodil International University are permitted to enter this platform.';
      }
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return 'Please verify your email address. A verification email has been sent.';
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signUp(String email, String password, String name,
      String department, String batch) async {
    try {
      if (!email.endsWith('@diu.edu.bd')) {
        return 'Only students from Daffodil International University are permitted to enter this platform.';
      }
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'department': department,
          'batch': batch,
        });
        await user.sendEmailVerification();
        return 'Account created successfully. Please check your email for verification.';
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<bool> isEmailVerified() async {
    User? user = _auth.currentUser;
    await user?.reload();
    return user?.emailVerified ?? false;
  }

  // Method to get current user details
  Future<Map<String, String>> getCurrentUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        return {
          'name': userDoc.data()?['name'] ?? '',
          'email': userDoc.data()?['email'] ?? '',
          'department': userDoc.data()?['department'] ?? '',
          'batch': userDoc.data()?['batch'] ?? '',
        };
      } else {
        throw Exception('User document does not exist');
      }
    } else {
      throw Exception('No user is signed in');
    }
  }
}
