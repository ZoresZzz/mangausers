import 'package:flutter/material.dart';
import '../../services/manga_service.dart';
import '../../models/manga_model.dart';
import '../../widgets/manga_grid_item.dart';
import '../manga_detail/manga_detail_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdatesPage extends StatefulWidget {
  const UpdatesPage({super.key});

  @override
  State<UpdatesPage> createState() => _UpdatesPageState();
}

class _UpdatesPageState extends State<UpdatesPage> {
  DateTime selectedDate = DateTime.now();
  final service = MangaService();
  Set<DateTime> datesWithManga = {};

  int totalManga = 0;
  int totalChapters = 0;

  @override
  void initState() {
    super.initState();
    loadStats();
  }

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

    if (mounted) {
      setState(() {
        totalManga = mangaSnap.docs.length;
        totalChapters = chapterCount;
      });
    }
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark Mode chuẩn
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            /// ===== BANNER & THỐNG KÊ =====
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildHeroBanner(),
                  _buildGlassStats(),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            /// ===== THANH LỊCH (Ghim trên đầu khi cuộn) =====
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyDateBarDelegate(
                child: _buildDateBar(),
              ),
            ),

            /// ===== DANH SÁCH TRUYỆN =====
            StreamBuilder<List<MangaModel>>(
              stream: service.getAllMangas(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SliverFillRemaining(
                    child: Center(
                        child: CircularProgressIndicator(color: Colors.orange)),
                  );
                }

                final allMangas = snapshot.data!;

                // Cập nhật Set các ngày có truyện để DateBar vẽ chấm xanh
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final newDates = allMangas
                      .map((m) => DateTime(
                          m.createdAt.year, m.createdAt.month, m.createdAt.day))
                      .toSet();
                  if (datesWithManga.length != newDates.length) {
                    setState(() => datesWithManga = newDates);
                  }
                });

                final mangas = allMangas
                    .where((m) => isSameDay(m.createdAt, selectedDate))
                    .toList();

                if (mangas.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 60, color: Colors.white.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          Text(
                            'Không có truyện mới cập nhật\nvào ngày này.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 16,
                                height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, top: 16, bottom: 40),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final manga = mangas[i];
                        return MangaGridItem(
                          manga: manga,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      MangaDetailPage(manga: manga)),
                            );
                          },
                        );
                      },
                      childCount: mangas.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================
  // WIDGET UI COMPONENTS
  // ==============================================

  /// BANNER CHÍNH
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE65C00),
            Color(0xFFF9D423)
          ], // Gradient rực rỡ mang phong cách Manga
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFE65C00).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20)),
            child: const Text("MANGABOXVN",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2)),
          ),
          const SizedBox(height: 16),
          const Text("Khám phá vũ trụ\ntruyện tranh.",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  height: 1.2)),
          const SizedBox(height: 8),
          Text("Cập nhật hàng giờ, đọc không giới hạn.",
              style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  /// THẺ THỐNG KÊ (HIỆU ỨNG KÍNH MỜ)
  Widget _buildGlassStats() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Xám tối
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem(Icons.auto_awesome_mosaic_rounded, const Color(0xFFFF9800),
              totalManga.toString(), "Đầu Truyện"),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
          _statItem(Icons.menu_book_rounded, const Color(0xFF03A9F4),
              totalChapters.toString(), "Chương Truyện"),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, Color color, String value, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
          ],
        ),
      ],
    );
  }

  /// THANH CHỌN NGÀY CẬP NHẬT
  Widget _buildDateBar() {
    final today = DateTime.now();
    return Container(
      height: 80,
      color:
          const Color(0xFF121212), // Trùng màu nền Scaffold để che lại khi ghim
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: 7,
        itemBuilder: (context, i) {
          // Tính toán ngày từ Thứ 2 đến Chủ Nhật của tuần hiện tại
          final date = today.subtract(Duration(days: today.weekday - 1 - i));
          final isSelected = isSameDay(date, selectedDate);
          final hasManga = datesWithManga.any((d) => isSameDay(d, date));

          final List<String> dayNames = [
            'T2',
            'T3',
            'T4',
            'T5',
            'T6',
            'T7',
            'CN'
          ];

          return GestureDetector(
            onTap: () => setState(() => selectedDate = date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: 55,
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFFE65C00), Color(0xFFF9D423)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter)
                    : null,
                color: isSelected ? null : const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: const Color(0xFFE65C00).withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4))
                      ]
                    : [],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayNames[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white.withOpacity(0.9)
                              : Colors.white.withOpacity(0.4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.white : Colors.white,
                        ),
                      ),
                    ],
                  ),

                  // Dấu chấm nhỏ (Dot) báo hiệu có truyện mới hôm đó
                  if (hasManga && !isSelected)
                    Positioned(
                      bottom: 6,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                            color: Color(0xFF03A9F4), shape: BoxShape.circle),
                      ),
                    )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==============================================
// KẾ THỪA ĐỂ TẠO HIỆU ỨNG GHIM (PINNED) CHO THANH LỊCH
// ==============================================
class _StickyDateBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyDateBarDelegate({required this.child});

  @override
  double get minExtent => 80.0; // Chiều cao của _buildDateBar

  @override
  double get maxExtent => 80.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_StickyDateBarDelegate oldDelegate) {
    return true; // Luôn rebuild để cập nhật ngày được chọn
  }
}
