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
        appBar: AppBar(
          title: const Text('Kệ Sách Của Tôi'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Thư viện'),
              Tab(text: 'Yêu thích'),
              Tab(text: 'Lịch sử'),
            ],
          ),
        ),
        body: const TabBarView(
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
