import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/manga_model.dart';
import '../manga_detail/manga_detail_page.dart';

class GenreMangaPage extends StatelessWidget {
  final String genre;

  const GenreMangaPage({super.key, required this.genre});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(genre),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('mangas')
            .where('genres', arrayContains: genre)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No manga in this genre'),
            );
          }

          final mangas = snapshot.data!.docs
              .map((doc) => MangaModel.fromMap(
                    doc.id,
                    doc.data() as Map<String, dynamic>,
                  ))
              .toList();

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.65,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: mangas.length,
            itemBuilder: (context, index) {
              final manga = mangas[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MangaDetailPage(manga: manga),
                    ),
                  );
                },
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          manga.coverUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      manga.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
