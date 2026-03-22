import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool loading = false;

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() {
      loading = true;
    });

    try {
      await context.read<AuthProvider>().login(
            emailCtrl.text.trim(),
            passCtrl.text.trim(),
          );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }

    setState(() {
      loading = false;
    });
  }

  Future<void> resetPassword() async {
    if (emailCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Nhập email để đặt lại mật khẩu"),
        ),
      );
      return;
    }

    try {
      await context
          .read<AuthProvider>()
          .sendPasswordReset(emailCtrl.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đã gửi email đặt lại mật khẩu"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Đăng nhập"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                labelText: "Email",
              ),
            ),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(
                labelText: "Mật khẩu",
              ),
              obscureText: true,
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: loading ? null : login,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Đăng nhập"),
            ),

            const SizedBox(height: 10),

            /// QUÊN MẬT KHẨU
            TextButton(
              onPressed: resetPassword,
              child: const Text("Quên mật khẩu"),
            ),

            const SizedBox(height: 10),

            /// ĐĂNG KÝ
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegisterScreen(),
                  ),
                );
              },
              child: const Text("Chưa có tài khoản? Đăng ký"),
            ),
          ],
        ),
      ),
    );
  }
}
