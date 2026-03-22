import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChangePhonePage extends StatefulWidget {
  const ChangePhonePage({super.key});

  @override
  State<ChangePhonePage> createState() => _ChangePhonePageState();
}

class _ChangePhonePageState extends State<ChangePhonePage> {
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  String verificationId = "";
  bool sent = false;
  bool loading = false;

  /// GỬI OTP
  Future<void> sendOTP() async {
    setState(() => loading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneController.text.trim(),
      verificationCompleted: (credential) async {
        await updatePhone(credential);
      },
      verificationFailed: (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message ?? "")));
      },
      codeSent: (id, _) {
        setState(() {
          verificationId = id;
          sent = true;
        });
      },
      codeAutoRetrievalTimeout: (id) {
        verificationId = id;
      },
    );

    setState(() => loading = false);
  }

  /// XÁC NHẬN OTP
  Future<void> verifyOTP() async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpController.text.trim(),
      );

      await updatePhone(credential);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sai OTP")),
      );
    }
  }

  /// 🔥 UPDATE PHONE
  Future<void> updatePhone(PhoneAuthCredential credential) async {
    final user = FirebaseAuth.instance.currentUser!;

    /// 🔥 UPDATE AUTH
    await user.updatePhoneNumber(credential);

    /// 🔥 UPDATE FIRESTORE
    await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
      "phone": phoneController.text.trim(),
    });

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Cập nhật số điện thoại thành công")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đổi số điện thoại")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// INPUT PHONE
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: "Số điện thoại mới (+84...)",
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: loading ? null : sendOTP,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Gửi OTP"),
            ),

            if (sent) ...[
              const SizedBox(height: 20),

              /// OTP
              TextField(
                controller: otpController,
                decoration: const InputDecoration(
                  labelText: "Nhập OTP",
                ),
              ),

              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: verifyOTP,
                child: const Text("Xác nhận"),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
