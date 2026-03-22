import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/cloudinary_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddPostPage extends StatefulWidget {
  const AddPostPage({super.key});

  @override
  State<AddPostPage> createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  final title = TextEditingController();
  final content = TextEditingController();

  File? imageFile;
  bool loading = false;

  /// ===============================
  /// 📸 CHỌN ẢNH
  /// ===============================
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
      });
    }
  }

  /// ===============================
  /// 🚀 SUBMIT
  /// ===============================
  Future<void> submit() async {
    if (title.text.isEmpty || content.text.isEmpty) return;

    setState(() => loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;

      /// 🔥 LẤY INFO USER TỪ FIRESTORE
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      final userData = userDoc.data();

      final username = userData?['name'] ?? "User";
      final avatar = userData?['avatar'];

      /// 🔥 upload ảnh nếu có
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await CloudinaryService.uploadImage(imageFile!);
      }

      /// 🔥 SAVE POST
      await FirebaseFirestore.instance.collection("posts").add({
        "title": title.text,
        "content": content.text,
        "imageUrl": imageUrl,
        "userId": user.uid,
        "username": username,
        "avatar": avatar, // ✅ QUAN TRỌNG
        "likes": 0,
        "likedBy": [],
        "createdAt": FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng bài")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// TITLE
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: "Tiêu đề"),
            ),

            const SizedBox(height: 10),

            /// CONTENT
            TextField(
              controller: content,
              decoration: const InputDecoration(labelText: "Nội dung"),
              maxLines: 5,
            ),

            const SizedBox(height: 15),

            /// 📸 BUTTON CHỌN ẢNH
            ElevatedButton.icon(
              onPressed: pickImage,
              icon: const Icon(Icons.image),
              label: const Text("Chọn ảnh"),
            ),

            /// 🖼️ PREVIEW
            if (imageFile != null)
              Padding(
                padding: const EdgeInsets.all(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    imageFile!,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            /// 🚀 BUTTON ĐĂNG
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : submit,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Đăng"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
