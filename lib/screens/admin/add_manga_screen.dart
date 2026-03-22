import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddMangaScreen extends StatefulWidget {
  const AddMangaScreen({super.key});

  @override
  State<AddMangaScreen> createState() => _AddMangaScreenState();
}

class _AddMangaScreenState extends State<AddMangaScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  File? _image;
  bool _isLoading = false;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  Future<void> uploadManga() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa chọn ảnh')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      /// 1. Upload ảnh
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance
          .ref()
          .child('manga_covers')
          .child('$fileName.jpg');

      await ref.putFile(_image!);

      /// 2. LẤY DOWNLOAD URL (QUAN TRỌNG)
      final coverUrl = await ref.getDownloadURL();

      /// 3. Lưu Firestore
      await FirebaseFirestore.instance.collection('mangas').add({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'coverUrl': coverUrl,
        'createdAt': Timestamp.now(),
      });

      /// 4. Tắt loading + quay về
      setState(() => _isLoading = false);

      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload lỗi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Manga')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                color: Colors.grey[300],
                child: _image == null
                    ? const Center(child: Text('Pick Cover'))
                    : Image.file(_image!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: uploadManga,
                    child: const Text('Upload Manga'),
                  ),
          ],
        ),
      ),
    );
  }
}
