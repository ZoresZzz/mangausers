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
  /// 🔥 BẢNG CHỌN THỂ LOẠI (BOTTOM SHEET)
  /// ===============================
  void _showAllGenres(List<String> genres) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 20),
                  const Text("Tất cả thể loại",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      itemCount: genres.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemBuilder: (context, index) {
                        final genre = genres[index];
                        final isSelected = genre == selectedGenre;
                        return GestureDetector(
                          onTap: () {
                            setState(() => selectedGenre = genre);
                            Navigator.pop(context);
                          },
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.orangeAccent
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : Colors.white10),
                            ),
                            child: Text(genre,
                                style: TextStyle(
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// ===============================
        /// 🔍 THANH TÌM KIẾM (MODERN SEARCH)
        /// ===============================
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (value) =>
                  setState(() => _keyword = value.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Tên truyện, tác giả...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Colors.orangeAccent, size: 22),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),

        /// ===============================
        /// 🎯 LỌC THỂ LOẠI (GENRE CHIPS)
        /// ===============================
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('mangas').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox(height: 40);

            Set<String> genreSet = {};
            for (var doc in snapshot.data!.docs) {
              final List list =
                  (doc.data() as Map<String, dynamic>)['genres'] ?? [];
              for (var g in list) genreSet.add(g.toString());
            }
            final genres = ["All", ...genreSet.toList()..sort()];
            final displayGenres = genres.take(6).toList();

            return Container(
              height: 38,
              padding: const EdgeInsets.only(left: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  ...displayGenres.map((genre) {
                    final isSelected = genre == selectedGenre;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => setState(() => selectedGenre = genre),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(colors: [
                                    Color(0xFFFF4D4D),
                                    Color(0xFFF9CB28)
                                  ])
                                : null,
                            color: isSelected
                                ? null
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(genre,
                              style: TextStyle(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ),
                      ),
                    );
                  }),
                  if (genres.length > 6)
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: TextButton.icon(
                        onPressed: () => _showAllGenres(genres),
                        icon: const Icon(Icons.add_circle_outline_rounded,
                            size: 18, color: Colors.orangeAccent),
                        label: const Text("Xem thêm",
                            style: TextStyle(
                                color: Colors.orangeAccent,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 20),

        /// ===============================
        /// 📚 DANH SÁCH TRUYỆN (RESULT LIST)
        /// ===============================
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('mangas')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(
                    child:
                        CircularProgressIndicator(color: Colors.orangeAccent));
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                return const Center(
                    child: Text('Không tìm thấy truyện phù hợp',
                        style: TextStyle(color: Colors.white38)));

              final mangas = snapshot.data!.docs
                  .map((doc) => MangaModel.fromMap(
                      doc.id, doc.data() as Map<String, dynamic>))
                  .where((manga) {
                final matchKeyword = _keyword.isEmpty ||
                    manga.title.toLowerCase().contains(_keyword) ||
                    manga.author.toLowerCase().contains(_keyword);
                final matchGenre = selectedGenre == "All" ||
                    manga.genres.contains(selectedGenre);
                return matchKeyword && matchGenre;
              }).toList();

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                physics: const BouncingScrollPhysics(),
                itemCount: mangas.length,
                itemBuilder: (context, index) {
                  final manga = mangas[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => MangaDetailPage(manga: manga))),
                      borderRadius: BorderRadius.circular(16),
                      child: Row(
                        children: [
                          // Thumbnail
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4))
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(manga.coverUrl,
                                  width: 70, height: 100, fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(manga.title,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        height: 1.2),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 6),
                                Text(manga.author,
                                    style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 8),
                                // Genres Badge nhỏ
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: manga.genres
                                        .take(3)
                                        .map((g) => Container(
                                              margin: const EdgeInsets.only(
                                                  right: 6),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.05),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                      color: Colors.white10)),
                                              child: Text(g,
                                                  style: const TextStyle(
                                                      color: Colors.white38,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ))
                                        .toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              color: Colors.white10, size: 16),
                        ],
                      ),
                    ),
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
