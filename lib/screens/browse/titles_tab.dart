import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/manga_model.dart';
import '../manga_detail/manga_detail_page.dart';

class TitlesTab extends StatelessWidget {
  const TitlesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          /// ===== 1. THANH ĐIỀU HƯỚNG TRẠNG THÁI =====
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withOpacity(0.1),
              ),
              labelColor: Colors.orangeAccent,
              unselectedLabelColor: Colors.white38,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              tabs: const [
                Tab(text: 'ĐANG TIẾN HÀNH'),
                Tab(text: 'ĐÃ HOÀN THÀNH'),
              ],
            ),
          ),

          /// ===== 2. NỘI DUNG DANH SÁCH =====
          Expanded(
            child: TabBarView(
              physics: const BouncingScrollPhysics(),
              children: [
                _buildMangaList(status: 'ongoing'),
                _buildMangaList(status: 'completed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ===== LIST MANGA THEO STATUS =====
  Widget _buildMangaList({required String status}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('mangas')
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
              child: Text('Lỗi tải dữ liệu',
                  style: TextStyle(color: Colors.redAccent)));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.orangeAccent));
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_stories_rounded,
                    size: 64, color: Colors.white.withOpacity(0.1)),
                const SizedBox(height: 16),
                const Text('Chưa có truyện ở mục này',
                    style: TextStyle(color: Colors.white38)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          physics: const BouncingScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final manga = MangaModel.fromMap(
              docs[index].id,
              docs[index].data() as Map<String, dynamic>,
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => MangaDetailPage(manga: manga)),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      // Thumbnail với hiệu ứng shadow
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            manga.coverUrl,
                            width: 65,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              manga.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              manga.author,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Badge nhỏ hiển thị view/like hoặc chapter
                            Row(
                              children: [
                                Icon(
                                  status == 'ongoing'
                                      ? Icons.sync_rounded
                                      : Icons.check_circle_rounded,
                                  size: 14,
                                  color: status == 'ongoing'
                                      ? Colors.blueAccent
                                      : Colors.greenAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  status == 'ongoing'
                                      ? "Đang cập nhật"
                                      : "Đã trọn bộ",
                                  style: TextStyle(
                                    color: status == 'ongoing'
                                        ? Colors.blueAccent
                                        : Colors.greenAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white10,
                        size: 16,
                      ),
                    ],
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
