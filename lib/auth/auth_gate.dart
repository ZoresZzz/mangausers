import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../app.dart'; // MainNavigation

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ❌ Chưa đăng nhập
    if (auth.user == null) {
      return const LoginScreen();
    }

    // ✅ Đã đăng nhập
    return const MainNavigation();
  }
}
