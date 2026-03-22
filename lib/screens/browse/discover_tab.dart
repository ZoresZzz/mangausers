import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/manga_model.dart';
import '../manga_detail/manga_detail_page.dart';

class DiscoverTab extends StatefulWidget {
  const DiscoverTab({super.key});

  @override
  State<DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<DiscoverTab> {
  String _keyword = '';
  String selectedGenre = "All";

  /// ===============================
  /// 🔥 SHOW ALL GENRES (BOTTOM SHEET)
  /// ===============================
  void _showAllGenres(List<String> genres) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                "Chọn thể loại",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: GridView.builder(
                  itemCount: genres.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.5,
                  ),
                  itemBuilder: (context, index) {
                    final genre = genres[index];
                    final isSelected = genre == selectedGenre;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedGenre = genre;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? Colors.deepPurple : Colors.white12,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          genre,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// ===============================
        /// 🔍 SEARCH
        /// ===============================
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Tìm theo tên truyện hoặc tác giả',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              filled: true,
              fillColor: Colors.white12,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _keyword = value.trim().toLowerCase();
              });
            },
          ),
        ),

        /// ===============================
        /// 🎯 GENRE FILTER + XEM THÊM
        /// ===============================
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('mangas').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 45,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return SizedBox(
                height: 45,
                child: Center(
                  child: Text(
                    "Lỗi: ${snapshot.error}",
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            }

            /// 🔥 LẤY GENRE
            Set<String> genreSet = {};

            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final List list = data['genres'] ?? [];

              for (var g in list) {
                genreSet.add(g.toString());
              }
            }

            final genres = ["All", ...genreSet.toList()..sort()];

            const int maxShow = 6;
            final displayGenres = genres.take(maxShow).toList();
            final hasMore = genres.length > maxShow;

            return SizedBox(
              height: 45,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  /// GENRE NHỎ
                  ...displayGenres.map((genre) {
                    final isSelected = genre == selectedGenre;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: ChoiceChip(
                        label: Text(
                          genre,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: Colors.white,
                        backgroundColor: Colors.white12,
                        onSelected: (_) {
                          setState(() {
                            selectedGenre = genre;
                          });
                        },
                      ),
                    );
                  }),

                  /// 🔥 XEM THÊM
                  if (hasMore)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: ActionChip(
                        label: const Text("Xem thêm"),
                        onPressed: () {
                          _showAllGenres(genres);
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 10),

        /// ===============================
        /// 📚 LIST MANGA
        /// ===============================
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('mangas')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Lỗi: ${snapshot.error}",
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              final mangas = snapshot.data!.docs
                  .map((doc) => MangaModel.fromMap(
                        doc.id,
                        doc.data() as Map<String, dynamic>,
                      ))
                  .where((manga) {
                final matchKeyword = _keyword.isEmpty ||
                    manga.title.toLowerCase().contains(_keyword) ||
                    manga.author.toLowerCase().contains(_keyword);

                final matchGenre = selectedGenre == "All" ||
                    manga.genres.contains(selectedGenre);

                return matchKeyword && matchGenre;
              }).toList();

              if (mangas.isEmpty) {
                return const Center(
                  child: Text(
                    'Không có kết quả',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              return ListView.builder(
                itemCount: mangas.length,
                itemBuilder: (context, index) {
                  final manga = mangas[index];

                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        manga.coverUrl,
                        width: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      manga.title,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      manga.author,
                      style: const TextStyle(color: Colors.white70),
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
              );
            },
          ),
        ),
      ],
    );
  }
}
