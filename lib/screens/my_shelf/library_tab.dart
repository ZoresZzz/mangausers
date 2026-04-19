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

    /// 1. TRẠNG THÁI: CHƯA ĐĂNG NHẬP
    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle),
              child: const Icon(Icons.lock_person_rounded,
                  size: 64, color: Colors.white54),
            ),
            const SizedBox(height: 20),
            const Text("Bạn chưa đăng nhập",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Đăng nhập để lưu lại các bộ truyện đang theo dõi.",
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 13)),
          ],
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
        /// 2. TRẠNG THÁI: ĐANG TẢI DỮ LIỆU
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent));
        }

        /// 3. TRẠNG THÁI: TRỐNG
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Đã sửa lỗi const và thay icon ở đây
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.2),
                          blurRadius: 30)
                    ],
                  ),
                  child: const Icon(Icons.local_library_rounded,
                      size: 64, color: Colors.greenAccent),
                ),
                const SizedBox(height: 20),
                const Text("Thư viện trống",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text("Hãy thêm các bộ truyện bạn đang theo dõi vào đây.",
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 13)),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;

        /// 4. DANH SÁCH THƯ VIỆN
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 16, bottom: 40),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();

            final String mangaId = doc.id;
            final String title = data['title'] ?? 'Không rõ tên truyện';
            final String coverUrl = data['coverUrl'] ?? '';
            final String lastChapterId = data['lastChapterId'] ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E), // Nền xám đen sang trọng
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async => await _openDetail(context, mangaId),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // 🖼️ Ảnh Bìa
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: coverUrl.isNotEmpty
                              ? Image.network(
                                  coverUrl,
                                  width: 60,
                                  height: 85,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return Container(
                                      width: 60,
                                      height: 85,
                                      color: Colors.white.withOpacity(0.05),
                                      child: const Center(
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.greenAccent)),
                                    );
                                  },
                                  errorBuilder: (_, __, ___) => Container(
                                      width: 60,
                                      height: 85,
                                      color: Colors.white.withOpacity(0.05),
                                      child: const Icon(Icons.broken_image,
                                          color: Colors.white54)),
                                )
                              : Container(
                                  width: 60,
                                  height: 85,
                                  color: Colors.white.withOpacity(0.05),
                                  child: const Icon(Icons.book_rounded,
                                      color: Colors.white54)),
                        ),
                        const SizedBox(width: 16),

                        // 📄 Thông tin Truyện
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      height: 1.3),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6)),
                                child: const Text("Nhấn để xem chi tiết",
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),

                        // ▶️ Nút Đọc Tiếp
                        GestureDetector(
                          onTap: () async => await _openReader(
                              context, mangaId, lastChapterId),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: Colors.greenAccent.withOpacity(0.15),
                                shape: BoxShape.circle),
                            child: const Icon(Icons.play_arrow_rounded,
                                color: Colors.greenAccent, size: 24),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // HÀM XỬ LÝ (UX CẢI TIẾN)
  // ==========================================

  Future<void> _openDetail(BuildContext context, String mangaId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
          child: CircularProgressIndicator(color: Colors.greenAccent)),
    );

    try {
      final doc = await FirebaseFirestore.instance
          .collection('mangas')
          .doc(mangaId)
          .get();
      if (context.mounted) Navigator.pop(context); // Tắt loading

      if (!doc.exists) {
        if (context.mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Truyện này không còn tồn tại.",
                  style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.redAccent));
        return;
      }

      final manga =
          MangaModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      if (context.mounted) {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => MangaDetailPage(manga: manga)));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Lỗi mạng. Vui lòng thử lại.",
                style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _openReader(
      BuildContext context, String mangaId, String lastChapterId) async {
    if (mangaId.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
          child: CircularProgressIndicator(color: Colors.greenAccent)),
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

      if (context.mounted) {
        Navigator.pop(context); // Tắt loading
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
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Lỗi khi mở chương truyện.",
                style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent));
      }
    }
  }
}
