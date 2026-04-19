import 'package:flutter/material.dart';
import 'discover_tab.dart';
import 'titles_tab.dart';
import 'chat_page.dart';

class BrowsePage extends StatelessWidget {
  const BrowsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212), // Nền Dark Mode chuẩn
        appBar: AppBar(
          backgroundColor: const Color(0xFF121212),
          elevation: 0,
          title: const Text(
            'Duyệt Truyện',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 24,
              letterSpacing: 0.5,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.smart_toy, color: Colors.orangeAccent),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChatPage(),
                  ),
                );
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white
                    .withOpacity(0.05), // Khung nền bao quanh mờ nhạt
                borderRadius: BorderRadius.circular(30),
              ),
              child: TabBar(
                // Loại bỏ đường gạch chân mặc định của TabBar
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                // Tạo hình viên thuốc màu Cam cho Tab đang được chọn
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE65C00), Color(0xFFF9D423)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE65C00).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                unselectedLabelStyle:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                splashBorderRadius: BorderRadius.circular(25),
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.explore_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Khám phá'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.library_books_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Tất cả'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          physics: BouncingScrollPhysics(), // Vuốt nảy mượt mà giữa các Tab
          children: [
            DiscoverTab(),
            TitlesTab(),
          ],
        ),
      ),
    );
  }
}
