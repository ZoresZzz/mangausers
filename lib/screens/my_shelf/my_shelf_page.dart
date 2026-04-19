import 'package:flutter/material.dart';
import 'library_tab.dart';
import 'favorites_tab.dart';
import 'history_page.dart';

class MyShelfPage extends StatelessWidget {
  const MyShelfPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F14), // Nền Dark Mode sâu đồng bộ
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F0F14),
          elevation: 0,
          title: const Text(
            'Kệ Sách Của Tôi',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 24,
              letterSpacing: 0.5,
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: IconButton(
                icon: const Icon(Icons.settings_rounded,
                    color: Colors.white, size: 20),
                onPressed: () {
                  // TODO: Thêm tính năng Cài đặt cá nhân
                },
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: Container(
              height: 50,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E)
                    .withOpacity(0.8), // Viền xám bao quanh TabBar
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: TabBar(
                dividerColor: Colors
                    .transparent, // Ẩn đường gạch chân xấu xí của Material 3
                indicatorSize: TabBarIndicatorSize.tab,
                // Tạo viên thuốc màu Gradient khi được chọn
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF4D4D),
                      Color(0xFFF9CB28)
                    ], // Tông màu Hoàng hôn (Sunset)
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF4D4D).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.5),
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                unselectedLabelStyle:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                splashBorderRadius: BorderRadius.circular(20),
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_library_rounded, size: 16),
                        SizedBox(width: 4),
                        Text('Thư viện', overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_rounded, size: 16),
                        SizedBox(width: 4),
                        Text('Yêu thích', overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded, size: 16),
                        SizedBox(width: 4),
                        Text('Lịch sử', overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          physics: BouncingScrollPhysics(), // Hiệu ứng vuốt nảy giữa 3 tab
          children: [
            LibraryTab(),
            FavoritesTab(),
            HistoryPage(),
          ],
        ),
      ),
    );
  }
}
