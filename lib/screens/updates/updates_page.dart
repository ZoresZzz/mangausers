import 'package:flutter/material.dart';
import '../../services/manga_service.dart';
import '../../models/manga_model.dart';
import '../../widgets/manga_grid_item.dart';
import '../manga_detail/manga_detail_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdatesPage extends StatefulWidget {
  UpdatesPage({super.key});

  @override
  State<UpdatesPage> createState() => _UpdatesPageState();
}

class _UpdatesPageState extends State<UpdatesPage> {
  DateTime selectedDate = DateTime.now();
  final service = MangaService();
  final ScrollController _scrollController = ScrollController();
  Set<DateTime> datesWithManga = {};
  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D0D0D), Color(0xFF1A1A1A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "MANGABOXVN",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            "Chào mừng bạn đến với MangaBoxVN",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            "Cập nhật những chapter mới nhất mỗi ngày",
            style: TextStyle(
              color: Colors.white70,
            ),
          ),

          const SizedBox(height: 20),

          /// 🔥 BUTTON
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              side: const BorderSide(color: Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              /// 🔥 SCROLL XUỐNG
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent *
                    0.2, // chỉnh số này nếu chưa đúng vị trí
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            },
            child: const Text("Truyện cập nhật"),
          )
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  int totalManga = 0;
  int totalChapters = 0;

  Future<void> loadStats() async {
    final mangaSnap =
        await FirebaseFirestore.instance.collection("mangas").get();

    int chapterCount = 0;

    for (var doc in mangaSnap.docs) {
      final chapSnap = await FirebaseFirestore.instance
          .collection("mangas")
          .doc(doc.id)
          .collection("chapters")
          .get();

      chapterCount += chapSnap.docs.length;
    }

    setState(() {
      totalManga = mangaSnap.docs.length;
      totalChapters = chapterCount;
    });
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            _buildBanner(),
            _buildStats(),
            _buildDateBar(),
            StreamBuilder<List<MangaModel>>(
              stream: service.getAllMangas(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allMangas = snapshot.data!;

                /// 🔥 LƯU NGÀY CÓ TRUYỆN
                datesWithManga = allMangas
                    .map((m) => DateTime(
                        m.createdAt.year, m.createdAt.month, m.createdAt.day))
                    .toSet();

                final mangas = allMangas
                    .where((m) => isSameDay(m.createdAt, selectedDate))
                    .toList();

                if (mangas.isEmpty) {
                  return const Center(child: Text('Không có cập nhật nào'));
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: mangas.length,
                  itemBuilder: (context, i) {
                    final manga = mangas[i];
                    return MangaGridItem(
                      manga: manga,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MangaDetailPage(manga: manga),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "TỔNG QUAN",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.menu_book, color: Colors.orange),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("$totalManga",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        const Text("TRUYỆN",
                            style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.auto_stories, color: Colors.blue),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("$totalChapters",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        const Text("CHƯƠNG",
                            style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDateBar() {
    final today = DateTime.now();
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, i) {
          final date = today.subtract(Duration(days: today.weekday - 1 - i));
          final selected = isSameDay(date, selectedDate);
          final hasManga = datesWithManga.any((d) => isSameDay(d, date));
          return GestureDetector(
            onTap: () => setState(() => selectedDate = date),
            child: Container(
              width: 60,
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.orange
                    : hasManga
                        ? Colors.blue.withOpacity(0.2)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: hasManga ? Border.all(color: Colors.blue) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    [
                      'thứ Hai',
                      'thứ Ba',
                      'thứ Tư',
                      'thứ Năm',
                      'thứ Sáu',
                      'thứ Bảy',
                      'chủ Nhật'
                    ][i],
                    style: TextStyle(
                      color: selected
                          ? const Color.fromARGB(255, 236, 235, 235)
                          : hasManga
                              ? Colors.blue
                              : Colors.white70,
                    ),
                  ),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.black : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
