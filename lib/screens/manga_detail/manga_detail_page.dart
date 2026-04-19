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

  // Lấy UID an toàn, trả về null nếu chưa đăng nhập
  String? get currentUid => FirebaseAuth.instance.currentUser?.uid;

  // Hàm thông báo yêu cầu đăng nhập
  void _showLoginRequiredMsg() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Bạn cần đăng nhập để sử dụng tính năng này!",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // =========================================
  // LOGIC XỬ LÝ DỮ LIỆU
  // =========================================

  Future<void> unlockChapter(ChapterModel chapter) async {
    if (currentUid == null) return _showLoginRequiredMsg();

    final userRef = _firestore.collection('users').doc(currentUid);
    final userDoc = await userRef.get();
    int points = userDoc.data()?['points'] ?? 0;

    if (points < chapter.price) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Không đủ điểm để mở khóa chương",
                style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    await userRef.update({'points': FieldValue.increment(-chapter.price)});
    await _firestore
        .collection('users')
        .doc(currentUid)
        .collection('unlockedChapters')
        .doc('${widget.manga.id}_${chapter.id}')
        .set({
      'mangaId': widget.manga.id,
      'chapterId': chapter.id,
      'unlockedAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Mở khóa thành công (-${chapter.price} điểm)",
              style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
    setState(() {});
  }

  Stream<bool> isChapterUnlockedStream(ChapterModel chapter) {
    if (!chapter.isLocked) return Stream.value(true);
    if (currentUid == null)
      return Stream.value(false); // Chưa đăng nhập thì chắc chắn chưa mở khoá

    return _firestore
        .collection('users')
        .doc(currentUid)
        .collection('unlockedChapters')
        .doc('${widget.manga.id}_${chapter.id}')
        .snapshots()
        .map((doc) => doc.exists);
  }

  Future<void> toggleLibrary() async {
    if (currentUid == null) return _showLoginRequiredMsg();

    final ref = _firestore
        .collection('users')
        .doc(currentUid)
        .collection('library')
        .doc(widget.manga.id);
    final doc = await ref.get();

    if (doc.exists) {
      await ref.delete();
      await FirebaseMessaging.instance
          .unsubscribeFromTopic("manga_${widget.manga.id}");
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Đã xóa khỏi thư viện")));
    } else {
      await ref.set({
        'title': widget.manga.title,
        'coverUrl': widget.manga.coverUrl,
        'author': widget.manga.author,
        'savedAt': FieldValue.serverTimestamp(),
      });
      await FirebaseMessaging.instance
          .subscribeToTopic("manga_${widget.manga.id}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Đã thêm vào thư viện",
                  style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> toggleFavorite() async {
    if (currentUid == null) return _showLoginRequiredMsg();

    final favRef = _firestore
        .collection('users')
        .doc(currentUid)
        .collection('favorites')
        .doc(widget.manga.id);
    final mangaRef = _firestore.collection('mangas').doc(widget.manga.id);
    final doc = await favRef.get();

    if (doc.exists) {
      await favRef.delete();
      await mangaRef.update({'likeCount': FieldValue.increment(-1)});
    } else {
      await favRef.set({
        'title': widget.manga.title,
        'coverUrl': widget.manga.coverUrl,
        'author': widget.manga.author
      });
      await mangaRef.update({'likeCount': FieldValue.increment(1)});
    }
  }

  Future<void> increaseView() async {
    await _firestore.collection('mangas').doc(widget.manga.id).update({
      'viewCount': FieldValue.increment(1),
      'weeklyViews': FieldValue.increment(1)
    });
  }

  Future<void> increaseChapterView(String chapterId) async {
    await _firestore
        .collection('mangas')
        .doc(widget.manga.id)
        .collection('chapters')
        .doc(chapterId)
        .update({'viewCount': FieldValue.increment(1)});
  }

  // =========================================
  // GIAO DIỆN (UI)
  // =========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14), // Dark Mode chuẩn
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          /// ===== 1. HEADER CUỘN ĐỘNG (SLIVER APP BAR) =====
          SliverAppBar(
            backgroundColor: const Color(0xFF0F0F14),
            expandedHeight: 320,
            pinned: true,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              _buildLibraryButton(),
              _buildFavoriteButton(),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.manga.bannerUrl ?? widget.manga.coverUrl,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF0F0F14),
                          const Color(0xFF0F0F14).withOpacity(0.8),
                          Colors.transparent
                        ],
                        stops: const [0.0, 0.4, 1.0],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.8),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10))
                            ],
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2), width: 1),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(widget.manga.coverUrl,
                                height: 160, width: 110, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _buildStatusBadge(widget.manga.status),
                              const SizedBox(height: 8),
                              Text(
                                widget.manga.title,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1.2),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.manga.author,
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.orangeAccent,
                                    fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// ===== 2. THỐNG KÊ =====
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: _buildStatsRow(),
            ),
          ),

          /// ===== 3. THỂ LOẠI & MÔ TẢ =====
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: widget.manga.genres.map((genre) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          GenreMangaPage(genre: genre)));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.1)),
                              ),
                              child: Text(genre,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("Nội Dung",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  Text(widget.manga.description,
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                          height: 1.5)),
                  const SizedBox(height: 20),
                  const Text("Danh Sách Chương",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),

          /// ===== 4. DANH SÁCH CHƯƠNG =====
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('mangas')
                .doc(widget.manga.id)
                .collection('chapters')
                .orderBy('number', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: Colors.orangeAccent)),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Center(
                      child: Text(
                        'Chưa có chương nào được cập nhật.',
                        style: TextStyle(color: Colors.white.withOpacity(0.5)),
                      ),
                    ),
                  ),
                );
              }

              final chapters = snapshot.data!.docs
                  .map((doc) => ChapterModel.fromMap(
                      doc.id, doc.data() as Map<String, dynamic>))
                  .toList();

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final chapter = chapters[index];
                      final readerIndex = chapters.length - 1 - index;

                      return StreamBuilder<bool>(
                        stream: isChapterUnlockedStream(chapter),
                        builder: (context, unlockSnapshot) {
                          final isUnlocked = unlockSnapshot.data ?? false;
                          final isLockedAndNeedsPay =
                              chapter.isLocked && !isUnlocked;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C1C1E),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _handleChapterTap(
                                    chapter, chapters, readerIndex, isUnlocked),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Text(
                                        chapter.number
                                            .toString()
                                            .padLeft(2, '0'),
                                        style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.15),
                                            fontSize: 28,
                                            fontWeight: FontWeight.w900),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              chapter.title.isNotEmpty
                                                  ? chapter.title
                                                  : "Chương ${chapter.number}",
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(
                                                    Icons
                                                        .remove_red_eye_rounded,
                                                    size: 14,
                                                    color: Colors.blueAccent),
                                                const SizedBox(width: 4),
                                                Text(
                                                  chapter.viewCount.toString(),
                                                  style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.6),
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal:
                                                isLockedAndNeedsPay ? 10 : 0,
                                            vertical:
                                                isLockedAndNeedsPay ? 6 : 0),
                                        decoration: BoxDecoration(
                                          color: isLockedAndNeedsPay
                                              ? Colors.orangeAccent
                                                  .withOpacity(0.15)
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: isLockedAndNeedsPay
                                            ? Row(
                                                children: [
                                                  Text('${chapter.price}',
                                                      style: const TextStyle(
                                                          color: Colors
                                                              .orangeAccent,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          fontSize: 14)),
                                                  const SizedBox(width: 4),
                                                  const Icon(Icons.lock_rounded,
                                                      color:
                                                          Colors.orangeAccent,
                                                      size: 16),
                                                ],
                                              )
                                            : Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                    color: Colors.greenAccent
                                                        .withOpacity(0.1),
                                                    shape: BoxShape.circle),
                                                child: const Icon(
                                                    Icons.play_arrow_rounded,
                                                    color: Colors.greenAccent,
                                                    size: 20),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    childCount: chapters.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // =========================================
  // SUB-WIDGETS & HELPERS
  // =========================================

  Widget _buildStatusBadge(String status) {
    final isCompleted = status == 'completed';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.greenAccent.withOpacity(0.2)
            : Colors.blueAccent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: isCompleted ? Colors.greenAccent : Colors.blueAccent,
            width: 0.5),
      ),
      child: Text(
        isCompleted ? 'HOÀN THÀNH' : 'ĐANG TIẾN HÀNH',
        style: TextStyle(
            color: isCompleted ? Colors.greenAccent : Colors.blueAccent,
            fontSize: 10,
            fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _buildStatsRow() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('mangas').doc(widget.manga.id).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final likeCount = data?['likeCount'] ?? 0;
        final viewCount = data?['viewCount'] ?? 0;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(16)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem(Icons.favorite_rounded, Colors.pinkAccent,
                  likeCount.toString(), "Lượt thích"),
              Container(
                  width: 1, height: 30, color: Colors.white.withOpacity(0.1)),
              _statItem(Icons.visibility_rounded, Colors.blueAccent,
                  viewCount.toString(), "Lượt xem"),
            ],
          ),
        );
      },
    );
  }

  Widget _statItem(IconData icon, Color iconColor, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900)),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildLibraryButton() {
    if (currentUid == null) {
      return IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
          child: const Icon(Icons.bookmark_border_rounded,
              color: Colors.white, size: 20),
        ),
        onPressed: _showLoginRequiredMsg,
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore
          .collection('users')
          .doc(currentUid)
          .collection('library')
          .doc(widget.manga.id)
          .snapshots(),
      builder: (context, snapshot) {
        final isSaved = snapshot.data?.exists ?? false;
        return IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
            child: Icon(
                isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: isSaved ? Colors.amber : Colors.white,
                size: 20),
          ),
          onPressed: toggleLibrary,
        );
      },
    );
  }

  Widget _buildFavoriteButton() {
    if (currentUid == null) {
      return IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
          child: const Icon(Icons.favorite_border_rounded,
              color: Colors.white, size: 20),
        ),
        onPressed: _showLoginRequiredMsg,
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore
          .collection('users')
          .doc(currentUid)
          .collection('favorites')
          .doc(widget.manga.id)
          .snapshots(),
      builder: (context, snapshot) {
        final isLiked = snapshot.data?.exists ?? false;
        return IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
            child: Icon(
                isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: isLiked ? Colors.pinkAccent : Colors.white,
                size: 20),
          ),
          onPressed: toggleFavorite,
        );
      },
    );
  }

  Future<void> _handleChapterTap(
      ChapterModel chapter,
      List<ChapterModel> allChapters,
      int indexForReader,
      bool isUnlocked) async {
    if (!chapter.isLocked || isUnlocked) {
      await increaseView();
      await increaseChapterView(chapter.id);

      final ascChapters = List<ChapterModel>.from(allChapters)
        ..sort((a, b) => a.number.compareTo(b.number));

      if (mounted) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ReaderPage(
                    mangaId: widget.manga.id,
                    chapters: ascChapters,
                    currentIndex: indexForReader)));
      }
      return;
    }

    // Nếu chưa đăng nhập thì không hiện form mua, bắt đăng nhập trước
    if (currentUid == null) return _showLoginRequiredMsg();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Chương có phí",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
            "Sử dụng ${chapter.price} điểm để mở khóa vĩnh viễn chương này?",
            style: TextStyle(color: Colors.white.withOpacity(0.8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(context);
              await unlockChapter(chapter);
            },
            child: const Text("Mở khóa",
                style: TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
