import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final usernameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool isLoading = false;
  bool emailSent = false;

  @override
  void dispose() {
    usernameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> register() async {
    setState(() {
      isLoading = true;
    });

    try {
      await context.read<AuthProvider>().register(
            emailCtrl.text.trim(),
            passCtrl.text.trim(),
            usernameCtrl.text.trim(),
          );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đã gửi email xác thực. Vui lòng kiểm tra Gmail."),
        ),
      );

      /// quay lại màn hình đăng nhập
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: emailSent
            ? verifyEmailUI()
            : Column(
                children: [
                  TextField(
                    controller: usernameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên người dùng',
                    ),
                  ),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                    ),
                  ),
                  TextField(
                    controller: passCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isLoading ? null : register,
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Đăng ký'),
                  ),
                ],
              ),
      ),
    );
  }

  ////////////////////////////////////////////////////////
  /// UI CHỜ XÁC THỰC EMAIL
  ////////////////////////////////////////////////////////

  Widget verifyEmailUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.mark_email_read,
          size: 80,
          color: Colors.orange,
        ),
        const SizedBox(height: 20),
        const Text(
          "Chúng tôi đã gửi email xác thực.",
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text(
          "Vui lòng kiểm tra Gmail và bấm link xác thực tài khoản.",
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () async {
            await context.read<AuthProvider>().resendVerifyEmail();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Đã gửi lại email xác thực"),
              ),
            );
          },
          child: const Text("Gửi lại email"),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("Quay lại đăng nhập"),
        ),
      ],
    );
  }
}
