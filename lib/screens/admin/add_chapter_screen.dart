import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddChapterScreen extends StatefulWidget {
  final String mangaId;

  const AddChapterScreen({super.key, required this.mangaId});

  @override
  State<AddChapterScreen> createState() => _AddChapterScreenState();
}

class _AddChapterScreenState extends State<AddChapterScreen> {
  final _chapterNumberController = TextEditingController();
  final _titleController = TextEditingController();

  List<File> _images = [];
  bool _isLoading = false;

  /// chọn nhiều ảnh
  Future<void> pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();

    if (picked.isNotEmpty) {
      setState(() {
        _images = picked.map((e) => File(e.path)).toList();
      });
    }
  }

  Future<void> uploadChapter() async {
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Chưa chọn ảnh')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final chapterNumber = _chapterNumberController.text.trim();
      final chapterTitle = _titleController.text.trim();

      List<String> pageUrls = [];

      /// upload từng ảnh
      for (int i = 0; i < _images.length; i++) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('manga_chapters')
            .child(widget.mangaId)
            .child('chapter_$chapterNumber')
            .child('page_${i + 1}.jpg');

        await ref.putFile(_images[i]);
        final url = await ref.getDownloadURL();
        pageUrls.add(url);
      }

      /// lưu Firestore
      await FirebaseFirestore.instance
          .collection('mangas')
          .doc(widget.mangaId)
          .collection('chapters')
          .add({
        'number': int.parse(chapterNumber),
        'title': chapterTitle,
        'pages': pageUrls,
        'createdAt': Timestamp.now(),
      });

      setState(() => _isLoading = false);
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Upload lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Chapter')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _chapterNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Chapter number'),
            ),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: pickImages,
              child: const Text('Pick Images'),
            ),
            const SizedBox(height: 8),
            Text('Đã chọn: ${_images.length} ảnh'),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: uploadChapter,
                    child: const Text('Upload Chapter'),
                  ),
          ],
        ),
      ),
    );
  }
}
