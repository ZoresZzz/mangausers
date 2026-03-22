import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/manga_model.dart';
import '../manga_detail/manga_detail_page.dart';

class FavoritesTab extends StatelessWidget {
  const FavoritesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text("Bạn chưa đăng nhập"),
      );
    }

    final favoritesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      // 🔥 Không orderBy để tránh lỗi thiếu createdAt
      stream: favoritesRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text("Có lỗi xảy ra"),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("Chưa có truyện yêu thích"),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();

            final String mangaId = doc.id;
            final String title = data['title'] ?? '';
            final String coverUrl = data['coverUrl'] ?? '';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(10),
                leading: coverUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          coverUrl,
                          width: 50,
                          height: 70,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const SizedBox(
                              width: 50,
                              height: 70,
                              child: Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image),
                        ),
                      )
                    : const Icon(Icons.book, size: 40),
                title: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(
                  Icons.favorite,
                  color: Colors.red,
                ),
                onTap: () async {
                  try {
                    final mangaDoc = await FirebaseFirestore.instance
                        .collection('mangas')
                        .doc(mangaId)
                        .get();

                    if (!mangaDoc.exists) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Truyện không tồn tại"),
                        ),
                      );
                      return;
                    }

                    final manga = MangaModel.fromMap(
                      mangaDoc.id,
                      mangaDoc.data(),
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MangaDetailPage(manga: manga),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Lỗi khi mở truyện"),
                      ),
                    );
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}
