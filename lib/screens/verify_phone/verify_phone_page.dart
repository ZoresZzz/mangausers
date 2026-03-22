import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VerifyPhonePage extends StatefulWidget {
  const VerifyPhonePage({super.key});

  @override
  State<VerifyPhonePage> createState() => _VerifyPhonePageState();
}

class _VerifyPhonePageState extends State<VerifyPhonePage> {
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  String verificationId = "";
  bool sent = false;

  /// GỬI OTP
  Future<void> sendOTP() async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneController.text.trim(),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.currentUser!.linkWithCredential(credential);
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
  }

  /// XÁC NHẬN OTP
  Future<void> verifyOTP() async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpController.text.trim(),
      );

      /// 🔥 LINK PHONE VỚI ACCOUNT
      await FirebaseAuth.instance.currentUser!.linkWithCredential(credential);

      /// 🔥 LƯU FIRESTORE
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection("users").doc(uid).update({
        "phone": phoneController.text.trim(),
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Xác thực thành công")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sai OTP")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Xác thực số điện thoại")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// PHONE
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: "Số điện thoại (+84...)",
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: sendOTP,
              child: const Text("Gửi OTP"),
            ),

            if (sent) ...[
              const SizedBox(height: 20),

              /// OTP
              TextField(
                controller: otpController,
                decoration: const InputDecoration(labelText: "Nhập OTP"),
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
