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
      // Thiết lập Theme chung cho toàn bộ App
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F14),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F0F14),
          elevation: 0,
        ),
      ),
      home: const AuthGate(),
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
    const UpdatesPage(),
    const HomePage(),
    const BrowsePage(),
    const MyShelfPage(),
    const ForumPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack giúp lưu giữ trạng thái cuộn của các trang khi chuyển Tab
      body: IndexedStack(
        index: _index,
        children: pages,
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.05), width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF0F0F14),
          selectedItemColor: Colors.orangeAccent,
          unselectedItemColor: Colors.white30,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          iconSize: 22,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_rounded),
              activeIcon:
                  Icon(Icons.auto_awesome_rounded, color: Colors.orangeAccent),
              label: 'Mới',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              activeIcon: Icon(Icons.home_filled, color: Colors.orangeAccent),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon:
                  Icon(Icons.explore_rounded, color: Colors.orangeAccent),
              label: 'Duyệt',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.collections_bookmark_outlined),
              activeIcon: Icon(Icons.collections_bookmark_rounded,
                  color: Colors.orangeAccent),
              label: 'Kệ sách',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.forum_outlined),
              activeIcon: Icon(Icons.forum_rounded, color: Colors.orangeAccent),
              label: 'Forum',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon:
                  Icon(Icons.person_rounded, color: Colors.orangeAccent),
              label: 'Hồ sơ',
            ),
          ],
        ),
      ),
    );
  }
}
