import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/manga_model.dart';
import '../manga_detail/manga_detail_page.dart';

class FavoritesTab extends StatelessWidget {
  const FavoritesTab({super.key});

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
            Text("Vui lòng đăng nhập để lưu truyện yêu thích.",
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 13)),
          ],
        ),
      );
    }

    final favoritesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: favoritesRef.snapshots(),
      builder: (context, snapshot) {
        /// 2. TRẠNG THÁI: ĐANG TẢI DỮ LIỆU
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.pinkAccent));
        }

        if (snapshot.hasError) {
          return const Center(
              child: Text("Có lỗi xảy ra khi tải dữ liệu.",
                  style: TextStyle(color: Colors.redAccent)));
        }

        /// 3. TRẠNG THÁI: TRỐNG (CHƯA THẢ TIM TRUYỆN NÀO)
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.pinkAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.pinkAccent.withOpacity(0.2),
                          blurRadius: 30)
                    ],
                  ),
                  child: const Icon(Icons.favorite_border_rounded,
                      size: 64, color: Colors.pinkAccent),
                ),
                const SizedBox(height: 20),
                const Text("Chưa có truyện yêu thích",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text("Hãy thả tim cho những bộ truyện bạn thích nhé!",
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 13)),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;

        /// 4. DANH SÁCH TRUYỆN YÊU THÍCH
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 16, bottom: 40),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();

            final String mangaId = doc.id;
            final String title = data['title'] ?? 'Không có tiêu đề';
            final String coverUrl = data['coverUrl'] ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E), // Nền xám đen sang trọng
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    // UX: Hiện Popup Loading mờ để user biết app đang xử lý
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const Center(
                          child: CircularProgressIndicator(
                              color: Colors.pinkAccent)),
                    );

                    try {
                      final mangaDoc = await FirebaseFirestore.instance
                          .collection('mangas')
                          .doc(mangaId)
                          .get();

                      if (context.mounted)
                        Navigator.pop(context); // Tắt Loading

                      if (!mangaDoc.exists) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text(
                                  "Truyện này không còn tồn tại hoặc đã bị xoá.",
                                  style: TextStyle(color: Colors.white)),
                              backgroundColor: Colors.redAccent));
                        }
                        return;
                      }

                      final manga =
                          MangaModel.fromMap(mangaDoc.id, mangaDoc.data()!);

                      if (context.mounted) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => MangaDetailPage(manga: manga)));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context); // Tắt Loading
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Lỗi mạng. Không thể mở truyện.",
                                    style: TextStyle(color: Colors.white)),
                                backgroundColor: Colors.redAccent));
                      }
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Ảnh Bìa
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
                                              color: Colors.pinkAccent)),
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
                                  child: const Icon(Icons.menu_book_rounded,
                                      color: Colors.white54)),
                        ),
                        const SizedBox(width: 16),

                        // Thông tin Truyện
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
                                child: const Text("Đang theo dõi",
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),

                        // Icon Trái tim phát sáng
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Colors.pinkAccent.withOpacity(0.15),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.favorite_rounded,
                              color: Colors.pinkAccent, size: 20),
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
}
