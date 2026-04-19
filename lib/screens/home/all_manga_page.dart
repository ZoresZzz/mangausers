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

  int get totalPages => (widget.mangas.length / perPage).ceil();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14), // Nền Dark Mode sâu
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F14),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Tất Cả Truyện",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          /// 🏷️ THÔNG TIN TỔNG SỐ LƯỢNG
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Text(
                  "Tổng cộng: ${widget.mangas.length} bộ",
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Icon(Icons.sort_rounded,
                    color: Colors.orangeAccent.withOpacity(0.8), size: 18),
                const SizedBox(width: 4),
                const Text("Mới cập nhật",
                    style: TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          /// 📱 LƯỚI TRUYỆN (GRID)
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.62, // Tỉ lệ vàng cho bìa truyện dọc
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
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
                          builder: (_) => MangaDetailPage(manga: manga)),
                    );
                  },
                );
              },
            ),
          ),

          /// 🔢 THANH PHÂN TRANG (PAGINATION)
          _buildPaginationControls(),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 10, 20, MediaQuery.of(context).padding.bottom + 15),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, -5))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Nút Trang trước
          _buildPageButton(
            icon: Icons.arrow_back_ios_new_rounded,
            isEnabled: currentPage > 1,
            onTap: () {
              setState(() => currentPage--);
            },
          ),

          // Hiển thị số trang hiện tại
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "$currentPage ",
                    style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.w900),
                  ),
                  TextSpan(
                    text: "/ $totalPages",
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // Nút Trang sau
          _buildPageButton(
            icon: Icons.arrow_forward_ios_rounded,
            isEnabled: currentPage < totalPages,
            onTap: () {
              setState(() => currentPage++);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton(
      {required IconData icon,
      required bool isEnabled,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isEnabled
              ? Colors.orangeAccent.withOpacity(0.1)
              : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isEnabled
                  ? Colors.orangeAccent.withOpacity(0.3)
                  : Colors.transparent),
        ),
        child: Icon(
          icon,
          color: isEnabled ? Colors.orangeAccent : Colors.white24,
          size: 20,
        ),
      ),
    );
  }
}
