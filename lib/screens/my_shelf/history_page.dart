import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/chapter_model.dart';
import '../reader/reader_page.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      color: const Color(0xFF0F0F14), // NỀN ĐỒNG BỘ DARK MODE
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: user == null
                  ? _buildUnauthView() // Trạng thái: Chưa đăng nhập
                  : _buildHistoryStream(user), // Trạng thái: Đã đăng nhập
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET UI COMPONENTS
  // ==========================================

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
    );
  }

  Widget _buildUnauthView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_person_rounded,
                size: 64, color: Colors.white54),
          ),
          const SizedBox(height: 20),
          const Text(
            "Bạn chưa đăng nhập",
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Đăng nhập để đồng bộ lịch sử đọc truyện.",
            style:
                TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryStream(User user) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .orderBy('updatedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        /// TRẠNG THÁI: ĐANG TẢI DỮ LIỆU
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.orangeAccent));
        }

        /// TRẠNG THÁI: TRỐNG
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.orangeAccent.withOpacity(0.2),
                          blurRadius: 30)
                    ],
                  ),
                  child: const Icon(Icons.history_toggle_off_rounded,
                      size: 64, color: Colors.orangeAccent),
                ),
                const SizedBox(height: 20),
                const Text("Chưa có lịch sử đọc",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text("Những truyện bạn đọc sẽ xuất hiện ở đây.",
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 13)),
              ],
            ),
          );
        }

        final histories = snapshot.data!.docs;

        /// DANH SÁCH LỊCH SỬ ĐỌC
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 10, bottom: 40),
          itemCount: histories.length,
          itemBuilder: (context, index) {
            final data = histories[index].data();

            final String title = data['mangaTitle'] ?? 'Không rõ tên truyện';
            final int chapterNumber = data['lastChapterNumber'] ?? 0;
            final String chapterTitle = data['lastChapterTitle'] ?? '';
            final String coverUrl = data['coverUrl'] ?? '';
            final String mangaId = data['mangaId'] ?? '';
            final String lastChapterId = data['lastChapterId'] ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E), // Nền xám đen Card
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
                  onTap: () => _openReader(context, mangaId, lastChapterId),
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
                                              color: Colors.orangeAccent)),
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
                              const SizedBox(height: 6),
                              Text(
                                chapterTitle.isNotEmpty
                                    ? "Chương $chapterNumber - $chapterTitle"
                                    : "Chương $chapterNumber",
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color:
                                        Colors.orangeAccent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6)),
                                child: const Text("Đang đọc",
                                    style: TextStyle(
                                        color: Colors.orangeAccent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900)),
                              ),
                            ],
                          ),
                        ),

                        // ▶️ Nút Đọc Tiếp
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.play_arrow_rounded,
                              color: Colors.orangeAccent, size: 24),
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
  // HÀM XỬ LÝ
  // ==========================================

  Future<void> _openReader(
      BuildContext context, String mangaId, String lastChapterId) async {
    if (mangaId.isEmpty || lastChapterId.isEmpty) return;

    // 🔥 Hiện Loading Spinner mờ
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
          child: CircularProgressIndicator(color: Colors.orangeAccent)),
    );

    try {
      final chapterSnapshot = await FirebaseFirestore.instance
          .collection('mangas')
          .doc(mangaId)
          .collection('chapters')
          .orderBy('number')
          .get();

      final List<ChapterModel> chapters = chapterSnapshot.docs
          .map((doc) => ChapterModel.fromMap(doc.id, doc.data()))
          .toList();

      int chapterIndex = chapters.indexWhere((c) => c.id == lastChapterId);
      if (chapterIndex == -1) chapterIndex = 0;

      if (context.mounted) {
        Navigator.pop(context); // Đóng loading
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
        Navigator.pop(context); // Đóng loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lỗi mạng. Không thể mở chương truyện.",
                style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
