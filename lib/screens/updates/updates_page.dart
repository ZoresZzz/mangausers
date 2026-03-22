import 'package:flutter/material.dart';
import '../../services/manga_service.dart';
import '../../models/manga_model.dart';
import '../../widgets/manga_grid_item.dart';
import '../manga_detail/manga_detail_page.dart';

class UpdatesPage extends StatefulWidget {
  UpdatesPage({super.key});

  @override
  State<UpdatesPage> createState() => _UpdatesPageState();
}

class _UpdatesPageState extends State<UpdatesPage> {
  DateTime selectedDate = DateTime.now();
  final service = MangaService();

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildDateBar(),
          Expanded(
            child: StreamBuilder<List<MangaModel>>(
              stream: service.getAllMangas(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final mangas = snapshot.data!
                    .where((m) => isSameDay(m.createdAt, selectedDate))
                    .toList();

                if (mangas.isEmpty) {
                  return const Center(child: Text('Không có cập nhật nào'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: mangas.length,
                  itemBuilder: (context, i) {
                    final manga = mangas[i];
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBar() {
    final today = DateTime.now();
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, i) {
          final date = today.subtract(Duration(days: today.weekday - 1 - i));
          final selected = isSameDay(date, selectedDate);

          return GestureDetector(
            onTap: () => setState(() => selectedDate = date),
            child: Container(
              width: 60,
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][i],
                    style: TextStyle(
                      color: selected ? Colors.black : Colors.white70,
                    ),
                  ),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.black : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
