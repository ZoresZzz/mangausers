import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? user;
  bool isAdmin = false;
  bool isLoading = true;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? firebaseUser) async {
    user = firebaseUser;
    isAdmin = false;

    if (user != null) {
      final doc = await _db.collection('admins').doc(user!.uid).get();
      isAdmin = doc.exists;
    }

    isLoading = false;
    notifyListeners();
  }

  // 🔐 LOGIN
  Future<void> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? user = credential.user;

    await user!.reload();
    user = _auth.currentUser;

    /// chưa xác thực email
    if (!user!.emailVerified) {
      await _auth.signOut();

      throw FirebaseAuthException(
        code: "email-not-verified",
        message:
            "Bạn cần xác thực email trước khi đăng nhập.\nVui lòng kiểm tra Gmail.",
      );
    }

    notifyListeners();
  }

  // 🆕 REGISTER
  Future<void> register(
    String email,
    String password,
    String username,
  ) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await result.user!.updateDisplayName(username);

    // gửi mail xác thực
    await result.user!.sendEmailVerification();

    // lưu firestore
    await _db.collection('users').doc(result.user!.uid).set({
      'uid': result.user!.uid,
      'email': email,
      'username': username,
      'points': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'role': 'user',
    });

    // 🔥 QUAN TRỌNG: logout để không tự đăng nhập
    await _auth.signOut();

    notifyListeners();
  }

  Future<void> sendPasswordReset(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  // 🔁 GỬI LẠI EMAIL XÁC THỰC
  Future<void> resendVerifyEmail() async {
    if (_auth.currentUser != null) {
      await _auth.currentUser!.sendEmailVerification();
    }
  }

  // 🚪 LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
    user = null;
    notifyListeners();
  }
}
