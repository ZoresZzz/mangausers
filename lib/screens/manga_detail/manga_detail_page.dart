import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../models/manga_model.dart';
import '../../models/chapter_model.dart';
import '../reader/reader_page.dart';
import '../genre/genre_manga_page.dart';

class MangaDetailPage extends StatefulWidget {
  final MangaModel manga;

  const MangaDetailPage({super.key, required this.manga});

  @override
  State<MangaDetailPage> createState() => _MangaDetailPageState();
}

class _MangaDetailPageState extends State<MangaDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> unlockChapter(ChapterModel chapter) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final userRef = _firestore.collection('users').doc(uid);

    final userDoc = await userRef.get();
    final data = userDoc.data();

    int points = data?['points'] ?? 0;

    /// ❌ Không đủ điểm
    if (points < chapter.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không đủ điểm để mở khóa chương")),
      );
      return;
    }

    /// ✅ Trừ điểm
    await userRef.update({
      'points': FieldValue.increment(-chapter.price),
    });

    /// ✅ Mở khóa chương
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('unlockedChapters')
        .doc('${widget.manga.id}_${chapter.id}')
        .set({
      'mangaId': widget.manga.id,
      'chapterId': chapter.id,
      'unlockedAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Mở khóa thành công (-${chapter.price} điểm)")),
    );

    setState(() {});
  }

  Stream<bool> isChapterUnlockedStream(ChapterModel chapter) {
    if (!chapter.isLocked) {
      return Stream.value(true);
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('unlockedChapters')
        .doc('${widget.manga.id}_${chapter.id}')
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// =========================
  /// TOGGLE LƯU TRUYỆN
  /// =========================
  Future<void> toggleLibrary() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final ref = _firestore
        .collection('users')
        .doc(uid)
        .collection('library')
        .doc(widget.manga.id);

    final doc = await ref.get();

    /// ❌ Nếu đã lưu → xóa khỏi thư viện
    if (doc.exists) {
      await ref.delete();

      /// Hủy nhận thông báo
      await FirebaseMessaging.instance
          .unsubscribeFromTopic("manga_${widget.manga.id}");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã xóa khỏi thư viện")),
      );
    }

    /// ✅ Nếu chưa lưu → thêm vào thư viện
    else {
      await ref.set({
        'title': widget.manga.title,
        'coverUrl': widget.manga.coverUrl,
        'author': widget.manga.author,
        'savedAt': FieldValue.serverTimestamp(),
      });

      /// Đăng ký nhận thông báo
      await FirebaseMessaging.instance
          .subscribeToTopic("manga_${widget.manga.id}");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã thêm vào thư viện")),
      );
    }
  }

  /// =========================
  /// TOGGLE YÊU THÍCH
  /// =========================
  Future<void> toggleFavorite() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final favRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(widget.manga.id);

    final mangaRef = _firestore.collection('mangas').doc(widget.manga.id);

    final doc = await favRef.get();

    if (doc.exists) {
      await favRef.delete();
      await mangaRef.update({
        'likeCount': FieldValue.increment(-1),
      });
    } else {
      await favRef.set({
        'title': widget.manga.title,
        'coverUrl': widget.manga.coverUrl,
        'author': widget.manga.author,
      });

      await mangaRef.update({
        'likeCount': FieldValue.increment(1),
      });
    }
  }

  Future<void> increaseView() async {
    await _firestore.collection('mangas').doc(widget.manga.id).update({
      'viewCount': FieldValue.increment(1),
      'weeklyViews': FieldValue.increment(1),
    });
  }

  Future<void> increaseChapterView(String chapterId) async {
    await _firestore
        .collection('mangas')
        .doc(widget.manga.id)
        .collection('chapters')
        .doc(chapterId)
        .update({
      'viewCount': FieldValue.increment(1),
    });
  }

  Widget _buildStatusChip(String status) {
    final isCompleted = status == 'completed';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isCompleted ? 'Đã hoàn thành' : 'Đang tiến hành',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.manga.title),
        actions: [
          /// ===== BOOKMARK =====
          StreamBuilder<DocumentSnapshot>(
            stream: _firestore
                .collection('users')
                .doc(uid)
                .collection('library')
                .doc(widget.manga.id)
                .snapshots(),
            builder: (context, snapshot) {
              final isSaved = snapshot.data?.exists ?? false;

              return IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: isSaved ? Colors.amber : Colors.white,
                ),
                onPressed: toggleLibrary,
              );
            },
          ),

          /// ===== FAVORITE =====
          StreamBuilder<DocumentSnapshot>(
            stream: _firestore
                .collection('users')
                .doc(uid)
                .collection('favorites')
                .doc(widget.manga.id)
                .snapshots(),
            builder: (context, snapshot) {
              final isLiked = snapshot.data?.exists ?? false;

              return TweenAnimationBuilder(
                tween: Tween(begin: 1.0, end: isLiked ? 1.2 : 1.0),
                duration: const Duration(milliseconds: 200),
                builder: (context, double scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.white,
                  ),
                  onPressed: () async {
                    await toggleFavorite();
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ===== COVER =====
          Stack(
            clipBehavior: Clip.none,
            children: [
              /// ===============================
              /// 🖼️ BANNER (ẢNH NGANG)
              /// ===============================
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                child: Image.network(
                  widget.manga.bannerUrl ?? widget.manga.coverUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              /// GRADIENT (CHO DỄ ĐỌC CHỮ)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.9),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              /// ===============================
              /// 📘 COVER FLOAT
              /// ===============================
              Positioned(
                bottom: -60,
                left: 20,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.manga.coverUrl,
                      height: 120,
                      width: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),

          /// 🔥 CHỪA CHỖ CHO COVER FLOAT
          const SizedBox(height: 70),

          /// ===== INFO =====
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.manga.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    _buildStatusChip(widget.manga.status),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  'Author: ${widget.manga.author}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 6),

                /// ===== LIKE COUNT =====
                StreamBuilder<DocumentSnapshot>(
                  stream: _firestore
                      .collection('mangas')
                      .doc(widget.manga.id)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();

                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    final likeCount = data?['likeCount'] ?? 0;

                    return Row(
                      children: [
                        const Icon(Icons.favorite, color: Colors.red, size: 16),
                        const SizedBox(width: 5),
                        Text(
                          likeCount.toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(width: 15),
                        const Icon(Icons.remove_red_eye,
                            color: Colors.white70, size: 16),
                        const SizedBox(width: 5),
                        Text(
                          (data?['viewCount'] ?? 0).toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 12),

                /// ===== GENRES =====
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.manga.genres.map((genre) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GenreMangaPage(genre: genre),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          genre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),

                Text(
                  widget.manga.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white24),

          /// ===== CHAPTER LIST =====
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('mangas')
                  .doc(widget.manga.id)
                  .collection('chapters')
                  .orderBy('number')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No chapters yet',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final chapters = snapshot.data!.docs
                    .map((doc) => ChapterModel.fromMap(
                          doc.id,
                          doc.data() as Map<String, dynamic>,
                        ))
                    .toList();

                return ListView.separated(
                  itemCount: chapters.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Colors.white12),
                  itemBuilder: (context, index) {
                    final chapter = chapters[index];

                    return StreamBuilder<bool>(
                      stream: isChapterUnlockedStream(chapter),
                      builder: (context, unlockSnapshot) {
                        final isUnlocked = unlockSnapshot.data ?? false;

                        return ListTile(
                          title: Text(
                            'Chapter ${chapter.number}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                chapter.title,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.remove_red_eye,
                                      size: 14, color: Colors.white54),
                                  const SizedBox(width: 4),
                                  Text(
                                    chapter.viewCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: chapter.isLocked && !isUnlocked
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${chapter.price} 💎',
                                      style:
                                          const TextStyle(color: Colors.orange),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.lock, color: Colors.red),
                                  ],
                                )
                              : const Icon(Icons.chevron_right,
                                  color: Colors.white),
                          onTap: () async {
                            if (!chapter.isLocked) {
                              await increaseView(); // tăng view
                              await increaseChapterView(
                                  chapter.id); // tăng view chapter
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReaderPage(
                                    mangaId: widget.manga.id,
                                    chapters: chapters,
                                    currentIndex: index,
                                  ),
                                ),
                              );
                              return;
                            }

                            if (isUnlocked) {
                              await increaseView();
                              await increaseChapterView(chapter.id);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReaderPage(
                                    mangaId: widget.manga.id,
                                    chapters: chapters,
                                    currentIndex: index,
                                  ),
                                ),
                              );
                            } else {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Chương bị khóa"),
                                  content: Text(
                                      "Mở khóa chương này với ${chapter.price} điểm?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Hủy"),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await unlockChapter(chapter);
                                      },
                                      child: const Text("Mở khóa"),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
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
}
