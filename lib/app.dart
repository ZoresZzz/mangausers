import 'package:flutter/material.dart';
import 'auth/auth_gate.dart';
import 'screens/home/home_page.dart';
import 'screens/updates/updates_page.dart';
import 'screens/browse/browse_page.dart';
import 'screens/profile/profile_page.dart';
import 'screens/my_shelf/my_shelf_page.dart';
import 'screens/forum/forum_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const AuthGate(), // ✅ QUAN TRỌNG NHẤT
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  final pages = [
    UpdatesPage(),
    const HomePage(),
    const BrowsePage(), // ✅ QUAN TRỌNG NHẤT
    const MyShelfPage(),
    const ForumPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Câp nhật',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_fire_department),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Duyệt',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Kệ của tôi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Diễn đàn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}
