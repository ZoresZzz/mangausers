import 'package:flutter/material.dart';
import 'discover_tab.dart';
import 'titles_tab.dart';

class BrowsePage extends StatelessWidget {
  const BrowsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Duyệt'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Khám phá'),
              Tab(text: 'Danh sách'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            DiscoverTab(),
            TitlesTab(),
          ],
        ),
      ),
    );
  }
}
