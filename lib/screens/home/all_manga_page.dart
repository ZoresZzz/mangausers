import 'package:flutter/material.dart';
import '../../models/manga_model.dart';
import '../../widgets/manga_grid_item.dart';
import '../manga_detail/manga_detail_page.dart';

class AllMangaPage extends StatefulWidget {
  final List<MangaModel> mangas;

  const AllMangaPage({super.key, required this.mangas});

  @override
  State<AllMangaPage> createState() => _AllMangaPageState();
}

class _AllMangaPageState extends State<AllMangaPage> {
  int currentPage = 1;
  final int perPage = 12;

  List<MangaModel> get currentList {
    final start = (currentPage - 1) * perPage;
    final end = start + perPage;

    return widget.mangas.sublist(
      start,
      end > widget.mangas.length ? widget.mangas.length : end,
    );
  }

  int get totalPages {
    return (widget.mangas.length / perPage).ceil();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mới cập nhật")),
      body: Column(
        children: [
          /// 🔥 GRID
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.65,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: currentList.length,
              itemBuilder: (context, index) {
                final manga = currentList[index];

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
            ),
          ),

          /// 🔥 PAGINATION
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// PREV
                IconButton(
                  onPressed: currentPage > 1
                      ? () {
                          setState(() {
                            currentPage--;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.arrow_back),
                ),

                Text(
                  "$currentPage / $totalPages",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                /// NEXT
                IconButton(
                  onPressed: currentPage < totalPages
                      ? () {
                          setState(() {
                            currentPage++;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
