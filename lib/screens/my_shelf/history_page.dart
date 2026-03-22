import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/chapter_model.dart'; // chỉnh lại path nếu cần
import '../reader/reader_page.dart'; // chỉnh lại path nếu cần

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // ✅ Không crash nếu chưa đăng nhập
    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "Bạn chưa đăng nhập",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Lịch sử đọc"),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('history')
            .orderBy('updatedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Chưa có lịch sử đọc",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final histories = snapshot.data!.docs;

          return ListView.builder(
            itemCount: histories.length,
            itemBuilder: (context, index) {
              final data = histories[index].data();

              final String title = data['mangaTitle'] ?? 'Unknown';

              final int chapterNumber = data['lastChapterNumber'] ?? 0;

              final String chapterTitle = data['lastChapterTitle'] ?? '';

              final String coverUrl = data['coverUrl'] ?? '';
              final String mangaId = data['mangaId'] ?? '';
              final String lastChapterId = data['lastChapterId'] ?? '';

              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: coverUrl.isNotEmpty
                        ? Image.network(
                            coverUrl,
                            width: 50,
                            height: 70,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 50,
                            height: 70,
                            color: Colors.grey,
                            child: const Icon(Icons.book, color: Colors.white),
                          ),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Chap $chapterNumber - $chapterTitle",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        "Đang đọc",
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onTap: () async {
                    if (mangaId.isEmpty || lastChapterId.isEmpty) return;

                    // 🔥 Loading
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );

                    try {
                      final chapterSnapshot = await FirebaseFirestore.instance
                          .collection('mangas')
                          .doc(mangaId)
                          .collection('chapters')
                          .orderBy('number')
                          .get();

                      // ✅ Convert sang List<ChapterModel>
                      final List<ChapterModel> chapters = chapterSnapshot.docs
                          .map((doc) => ChapterModel.fromMap(
                                doc.id,
                                doc.data(),
                              ))
                          .toList();

                      // 🔍 Tìm index chương đã đọc
                      int chapterIndex =
                          chapters.indexWhere((c) => c.id == lastChapterId);

                      if (chapterIndex == -1) {
                        chapterIndex = 0;
                      }

                      Navigator.pop(context); // đóng loading

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReaderPage(
                            mangaId: mangaId,
                            chapters: chapters,
                            currentIndex: chapterIndex,
                          ),
                        ),
                      );
                    } catch (e) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Lỗi khi mở chương"),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
