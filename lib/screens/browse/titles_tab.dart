import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/manga_model.dart';
import '../manga_detail/manga_detail_page.dart';

class TitlesTab extends StatelessWidget {
  const TitlesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const Material(
            color: Colors.black,
            child: TabBar(
              indicatorColor: Colors.deepPurple,
              tabs: [
                Tab(text: 'Đang tiến hành'),
                Tab(text: 'Đã hoàn thành'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildMangaList(status: 'ongoing'),
                _buildMangaList(status: 'completed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ===== LIST MANGA THEO STATUS =====
  Widget _buildMangaList({required String status}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('mangas')
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Lỗi tải dữ liệu'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text('Không có manga'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final manga = MangaModel.fromMap(
              docs[index].id,
              docs[index].data() as Map<String, dynamic>,
            );

            return ListTile(
              leading: Image.network(
                manga.coverUrl,
                width: 50,
                fit: BoxFit.cover,
              ),
              title: Text(manga.title),
              subtitle: Text(manga.author),
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
    );
  }
}
