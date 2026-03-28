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
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: StreamBuilder<List<MangaModel>>(
        stream: service.getAllMangas(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final mangas = snapshot.data!;

          if (mangas.isEmpty) {
            return const Center(child: Text('No manga'));
          }

          /// ===== NEWLY UPDATED =====
          final newUpdated = List<MangaModel>.from(mangas)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          /// ===== RANDOM =====
          final recommended = List<MangaModel>.from(mangas)..shuffle();

          /// ===== TOP LIKE =====
          final topLiked = List<MangaModel>.from(mangas)
            ..sort((a, b) => b.likeCount.compareTo(a.likeCount));

          /// ===== TOP VIEWS WEEK =====
          final topViews = List<MangaModel>.from(mangas)
            ..sort((a, b) => b.weeklyViews.compareTo(a.weeklyViews));

          return ListView(
            children: [
              /// ===== RECOMMENDED =====
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  "🎯 Đề xuất ngẫu nhiên",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              SizedBox(
                height: 220,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: recommended.take(5).length,
                  itemBuilder: (context, index) {
                    final manga = recommended[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: SizedBox(
                        width: 140,
                        child: MangaGridItem(
                          manga: manga,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MangaDetailPage(manga: manga),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              /// ===== NEWLY UPDATED =====
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "🆕 Mới cập nhật",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    /// 🔥 NÚT XEM THÊM
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AllMangaPage(mangas: newUpdated),
                          ),
                        );
                      },
                      child: const Text("Xem thêm"),
                    )
                  ],
                ),
              ),

              SizedBox(
                height: 220,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: newUpdated.take(5).length,
                  itemBuilder: (context, index) {
                    final manga = newUpdated[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: SizedBox(
                        width: 140,
                        child: MangaGridItem(
                          manga: manga,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MangaDetailPage(manga: manga),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),

              /// ===== TOP LIKED =====
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  "❤️ Top yêu thích",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: topLiked.take(5).length,
                itemBuilder: (context, index) {
                  final manga = topLiked[index];

                  return ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: index == 0
                                ? Colors.amber
                                : index == 1
                                    ? Colors.grey
                                    : index == 2
                                        ? Colors.brown
                                        : Colors.black26,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "${index + 1}",
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            manga.coverUrl,
                            width: 50,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                    title: Text(manga.title),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite, color: Colors.red),
                        const SizedBox(width: 5),
                        Text(
                          manga.likeCount.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
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
              ),

              const SizedBox(height: 20),

              /// ===== TRENDING THIS WEEK =====
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  "🔥 Trending ",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: topViews.take(5).length,
                itemBuilder: (context, index) {
                  final manga = topViews[index];

                  return ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: index == 0
                                ? Colors.amber
                                : index == 1
                                    ? Colors.grey
                                    : index == 2
                                        ? Colors.brown
                                        : Colors.black26,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "${index + 1}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            manga.coverUrl,
                            width: 50,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                    title: Text(manga.title),

                    /// 👁 weekly views
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.remove_red_eye, color: Colors.blue),
                        const SizedBox(width: 5),
                        Text(
                          manga.weeklyViews.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

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
              ),
            ],
          );
        },
      ),
    );
  }
}
