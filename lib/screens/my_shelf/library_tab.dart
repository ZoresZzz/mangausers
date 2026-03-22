import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/manga_model.dart';
import '../../models/chapter_model.dart';
import '../reader/reader_page.dart';
import '../manga_detail/manga_detail_page.dart';

class LibraryTab extends StatelessWidget {
  const LibraryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text(
          "Bạn chưa đăng nhập",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('library')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "Chưa có truyện trong thư viện",
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();

            // 🔥 DÙNG LUÔN doc.id làm mangaId
            final String mangaId = doc.id;
            final String title = data['title'] ?? '';
            final String coverUrl = data['coverUrl'] ?? '';
            final String lastChapterId = data['lastChapterId'] ?? '';

            return Card(
              color: Colors.grey[900],
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: coverUrl.isNotEmpty
                    ? Image.network(
                        coverUrl,
                        width: 50,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.book, color: Colors.white),
                title: Text(
                  title,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  "Nhấn để xem chi tiết",
                  style: TextStyle(color: Colors.white70),
                ),

                /// 🔥 NÚT ĐỌC TIẾP
                trailing: IconButton(
                  icon: const Icon(Icons.play_arrow, color: Colors.green),
                  onPressed: () async {
                    await _openReader(
                      context,
                      mangaId,
                      lastChapterId,
                    );
                  },
                ),

                /// 🔥 TAP VÀO CARD → DETAIL PAGE
                onTap: () async {
                  await _openDetail(context, mangaId);
                },
              ),
            );
          },
        );
      },
    );
  }

  /// =============================
  /// MỞ DETAIL PAGE
  /// =============================
  Future<void> _openDetail(BuildContext context, String mangaId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final doc = await FirebaseFirestore.instance
          .collection('mangas')
          .doc(mangaId)
          .get();

      Navigator.pop(context);

      if (!doc.exists) return;

      final manga = MangaModel.fromMap(
        doc.id,
        doc.data() as Map<String, dynamic>,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MangaDetailPage(manga: manga),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
    }
  }

  /// =============================
  /// MỞ READER (ĐỌC TIẾP)
  /// =============================
  Future<void> _openReader(
    BuildContext context,
    String mangaId,
    String lastChapterId,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final chapterSnapshot = await FirebaseFirestore.instance
          .collection('mangas')
          .doc(mangaId)
          .collection('chapters')
          .orderBy('number')
          .get();

      final chapters = chapterSnapshot.docs
          .map((doc) => ChapterModel.fromMap(doc.id, doc.data()))
          .toList();

      int chapterIndex = 0;

      if (lastChapterId.isNotEmpty) {
        final index = chapters.indexWhere((c) => c.id == lastChapterId);
        if (index != -1) {
          chapterIndex = index;
        }
      }

      Navigator.pop(context);

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
    }
  }
}
