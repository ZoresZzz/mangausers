import 'package:flutter/material.dart';
import '../../services/manga_service.dart';
import '../../models/manga_model.dart';
import '../../widgets/manga_grid_item.dart';
import '../manga_detail/manga_detail_page.dart';
import 'all_manga_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = MangaService();

    return Scaffold(
      backgroundColor:
          const Color(0xFF0F0F14), // Nền Dark Mode sâu hơn một chút
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F14),
        elevation: 0,
        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                  text: 'MangaBox',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      fontSize: 24)),
              TextSpan(
                  text: 'VN',
                  style: TextStyle(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      fontSize: 24)),
            ],
          ),
        ),
      ),
      body: StreamBuilder<List<MangaModel>>(
        stream: service.getAllMangas(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(
                child: CircularProgressIndicator(color: Colors.orange));

          final mangas = snapshot.data!;
          if (mangas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome_mosaic_rounded,
                      size: 60, color: Colors.white.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text('Vũ trụ truyện đang trống',
                      style: TextStyle(color: Colors.white.withOpacity(0.5))),
                ],
              ),
            );
          }

          /// ===== XỬ LÝ DỮ LIỆU =====
          final newUpdated = List<MangaModel>.from(mangas)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final recommended = List<MangaModel>.from(mangas)..shuffle();
          final topLiked = List<MangaModel>.from(mangas)
            ..sort((a, b) => b.likeCount.compareTo(a.likeCount));
          final topViews = List<MangaModel>.from(mangas)
            ..sort((a, b) => b.weeklyViews.compareTo(a.weeklyViews));
          final ranking = List<MangaModel>.from(mangas)
            ..sort((a, b) => (b.weeklyViews + b.likeCount)
                .compareTo(a.weeklyViews + a.likeCount));

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                /// ===== 1. HERO CAROUSEL (ĐỀ XUẤT) =====
                _buildHeroCarousel(context, recommended.take(5).toList()),

                const SizedBox(height: 35),

                /// ===== 2. MỚI CẬP NHẬT =====
                _buildSectionHeader(
                  title: "Mới Cập Nhật",
                  icon: Icons.bolt_rounded,
                  iconColor: Colors.greenAccent,
                  onSeeAll: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AllMangaPage(mangas: newUpdated))),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 210,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: newUpdated.take(8).length,
                    itemBuilder: (context, index) {
                      final manga = newUpdated[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: SizedBox(
                          width: 130,
                          child: MangaGridItem(
                            manga: manga,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        MangaDetailPage(manga: manga))),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 35),

                /// ===== 3. BẢNG XẾP HẠNG (3 CỘT CUỘN NGANG) =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cột 1: BXH Tổng
                        SizedBox(
                          width: 290,
                          child: _buildLeaderboardColumn(
                            context: context,
                            title: "BXH Tổng Hợp",
                            headerIcon: Icons.emoji_events_rounded,
                            headerIconColor: Colors.amber,
                            items: ranking.take(5).toList(),
                            showScore: true,
                          ),
                        ),
                        const SizedBox(width: 24),

                        // Cột 2: Top Yêu Thích
                        SizedBox(
                          width: 290,
                          child: _buildLeaderboardColumn(
                            context: context,
                            title: "Top Yêu Thích",
                            headerIcon: Icons.favorite_rounded,
                            headerIconColor: Colors.pinkAccent,
                            items: topLiked.take(5).toList(),
                            showLikes: true,
                          ),
                        ),
                        const SizedBox(width: 24),

                        // Cột 3: Trending Tuần
                        SizedBox(
                          width: 290,
                          child: _buildLeaderboardColumn(
                            context: context,
                            title: "Trending Tuần",
                            headerIcon: Icons.local_fire_department_rounded,
                            headerIconColor: Colors.orangeAccent,
                            items: topViews.take(5).toList(),
                            showViews: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // WIDGET UI COMPONENTS
  // ==========================================

  Widget _buildSectionHeader(
      {required String title,
      required IconData icon,
      required Color iconColor,
      required VoidCallback onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900)),
          const Spacer(),
          InkWell(
            onTap: onSeeAll,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20)),
              child: const Row(
                children: [
                  Text("Xem tất cả",
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.white70, size: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCarousel(BuildContext context, List<MangaModel> items) {
    return SizedBox(
      height: 220,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.9),
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final manga = items[index];
          final imageUrl =
              (manga.bannerUrl != null && manga.bannerUrl!.isNotEmpty)
                  ? manga.bannerUrl!
                  : manga.coverUrl;

          return GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => MangaDetailPage(manga: manga))),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                    image: NetworkImage(imageUrl), fit: BoxFit.cover),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.6),
                      blurRadius: 15,
                      offset: const Offset(0, 8))
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(colors: [
                    Colors.black.withOpacity(0.95),
                    Colors.transparent
                  ], begin: Alignment.bottomCenter, end: Alignment.topCenter),
                ),
                padding: const EdgeInsets.all(16),
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.orangeAccent,
                              borderRadius: BorderRadius.circular(6)),
                          child: const Row(
                            children: [
                              Icon(Icons.star_rounded,
                                  color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text("ĐỀ XUẤT",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(manga.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1.2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                            child: Text(manga.genres.join(" • "),
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.play_arrow_rounded,
                              color: Colors.white, size: 20),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeaderboardColumn({
    required BuildContext context,
    required String title,
    required IconData headerIcon,
    required Color headerIconColor,
    required List<MangaModel> items,
    bool showScore = false,
    bool showLikes = false,
    bool showViews = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: headerIconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(headerIcon, color: headerIconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 20),
        ...List.generate(items.length, (index) {
          final manga = items[index];

          // Gradient cho Top 1, 2, 3
          Gradient rankGradient;
          Color rankTextColor = Colors.white;
          if (index == 0) {
            rankGradient = const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFDB931)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight);
            rankTextColor = Colors.black87;
          } else if (index == 1) {
            rankGradient = const LinearGradient(
                colors: [Color(0xFFE0E0E0), Color(0xFFBDBDBD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight);
            rankTextColor = Colors.black87;
          } else if (index == 2) {
            rankGradient = const LinearGradient(
                colors: [Color(0xFFCD7F32), Color(0xFFA0522D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight);
          } else {
            rankGradient = LinearGradient(colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05)
            ]);
          }

          // Icon thống kê dưới tên truyện
          Widget statWidget;
          if (showScore) {
            statWidget = Text("🔥 Điểm: ${manga.weeklyViews + manga.likeCount}",
                style: TextStyle(
                    color: Colors.amber.shade400,
                    fontSize: 11,
                    fontWeight: FontWeight.bold));
          } else if (showLikes) {
            statWidget = Row(
              children: [
                const Icon(Icons.favorite_rounded,
                    color: Colors.pinkAccent, size: 14),
                const SizedBox(width: 4),
                Text(manga.likeCount.toString(),
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ],
            );
          } else if (showViews) {
            statWidget = Row(
              children: [
                const Icon(Icons.visibility_rounded,
                    color: Colors.lightBlueAccent, size: 14),
                const SizedBox(width: 4),
                Text(manga.weeklyViews.toString(),
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ],
            );
          } else {
            statWidget = const SizedBox();
          }

          return GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => MangaDetailPage(manga: manga))),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              color: Colors.transparent,
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        gradient: rankGradient,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: index < 3
                            ? [
                                BoxShadow(
                                    color: Colors.black45,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2))
                              ]
                            : []),
                    child: Text("${index + 1}",
                        style: TextStyle(
                            color: rankTextColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 13)),
                  ),
                  const SizedBox(width: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(manga.coverUrl,
                        width: 48, height: 68, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(manga.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                height: 1.3),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        statWidget,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
