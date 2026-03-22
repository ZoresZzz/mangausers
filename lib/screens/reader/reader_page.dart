import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/chapter_model.dart';

class ReaderPage extends StatefulWidget {
  final String mangaId;
  final List<ChapterModel> chapters;
  final int currentIndex;

  const ReaderPage({
    super.key,
    required this.mangaId,
    required this.chapters,
    required this.currentIndex,
  });

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  bool isVertical = true;

  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();

  // ================= CHAPTER ACCESS =================

  Future<bool> _isPurchased(String chapterId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('purchasedChapters')
        .doc(chapterId)
        .get();

    return doc.exists;
  }

  Future<void> _buyChapter(ChapterModel chapter) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);

      int points = userDoc['points'];

      if (points < chapter.price) {
        throw Exception("not_enough_points");
      }

      transaction.update(userRef, {
        'points': points - chapter.price,
      });

      transaction.set(
        userRef
            .collection('unlockedChapters')
            .doc('${widget.mangaId}_${chapter.id}'),
        {
          'chapterId': chapter.id,
          'mangaId': widget.mangaId,
          'chapterNumber': chapter.number,
          'purchasedAt': FieldValue.serverTimestamp(),
        },
      );
    });
  }

  Future<bool> _checkChapterAccess(int index) async {
    final chapter = widget.chapters[index];

    if (!chapter.isLocked) return true;

    final purchased = await _isPurchased(chapter.id);

    if (purchased) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Chương bị khóa"),
          content:
              Text("Chương ${chapter.number} cần ${chapter.price} điểm để mở."),
          actions: [
            TextButton(
              child: const Text("Hủy"),
              onPressed: () => Navigator.pop(context, false),
            ),
            ElevatedButton(
              child: const Text("Mua"),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    );

    if (result == true) {
      try {
        await _buyChapter(chapter);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Mở khóa chương thành công")),
        );

        return true;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bạn không đủ điểm để mở chương")),
        );
        return false;
      }
    }

    return false;
  }

  // ================= SAVE HISTORY =================

  Future<void> _saveReadingHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final chapter = widget.chapters[widget.currentIndex];

    try {
      final mangaDoc = await FirebaseFirestore.instance
          .collection('mangas')
          .doc(widget.mangaId)
          .get();

      final mangaData = mangaDoc.data();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .doc(widget.mangaId)
          .set({
        'mangaId': widget.mangaId,

        /// 🔥 QUAN TRỌNG
        'mangaTitle': mangaData?['title'] ?? '',
        'coverUrl': mangaData?['coverUrl'] ?? '',

        'lastChapterId': chapter.id,
        'lastChapterNumber': chapter.number,
        'lastChapterTitle': chapter.title,

        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Save history error: $e");
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveReadingHistory();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ================= COMMENT =================

  void _openComments(ChapterModel chapter) {
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              const SizedBox(height: 10),

              const Text(
                "Bình luận",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),

              const Divider(color: Colors.white24),

              /// DANH SÁCH COMMENT
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('mangas')
                      .doc(widget.mangaId)
                      .collection('chapters')
                      .doc(chapter.id)
                      .collection('comments')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "Chưa có bình luận",
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    return ListView(
                      children: snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;

                        return ListTile(
                          title: Text(
                            data['content'] ?? '',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            data['userName'] ?? 'Ẩn danh',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),

              /// Ô NHẬP COMMENT
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 12,
                  right: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Nhập bình luận...",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.green),
                      onPressed: () async {
                        if (commentController.text.trim().isEmpty) return;

                        final user = FirebaseAuth.instance.currentUser;

                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Bạn cần đăng nhập để bình luận"),
                            ),
                          );
                          return;
                        }

                        final content = commentController.text.trim();
                        final username =
                            user.displayName ?? user.email ?? 'Ẩn danh';

                        /// tạo commentId chung
                        final commentRef = FirebaseFirestore.instance
                            .collection('mangas')
                            .doc(widget.mangaId)
                            .collection('chapters')
                            .doc(chapter.id)
                            .collection('comments')
                            .doc();

                        /// lưu comment cho chapter (user thấy)
                        await commentRef.set({
                          'content': content,
                          'userName': username,
                          'userId': user.uid,
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        /// lấy title truyện
                        final mangaDoc = await FirebaseFirestore.instance
                            .collection('mangas')
                            .doc(widget.mangaId)
                            .get();

                        final mangaTitle = mangaDoc.data()?['title'] ?? '';

                        /// lưu comment cho admin (dùng cùng ID)
                        await FirebaseFirestore.instance
                            .collection('comments')
                            .doc(commentRef.id)
                            .set({
                          'content': content,
                          'userName': username,
                          'userId': user.uid,
                          'mangaId': widget.mangaId,
                          'mangaTitle': mangaTitle,
                          'chapterId': chapter.id,
                          'chapterNumber': chapter.number,
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        commentController.clear();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= SETTINGS =================

  void _showReaderSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.swap_vert, color: Colors.white),
              title: const Text("Đọc chiều dọc",
                  style: TextStyle(color: Colors.white)),
              trailing: isVertical
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                setState(() => isVertical = true);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: Colors.white),
              title: const Text("Đọc chiều ngang",
                  style: TextStyle(color: Colors.white)),
              trailing: !isVertical
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                setState(() => isVertical = false);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }

  // ================= BOTTOM BAR =================

  Widget _buildBottomBar() {
    final chapter = widget.chapters[widget.currentIndex];

    return BottomAppBar(
      color: Colors.black87,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.comment, color: Colors.white),
              onPressed: () => _openComments(chapter),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: widget.currentIndex > 0
                  ? () async {
                      final prev = widget.currentIndex - 1;

                      if (!await _checkChapterAccess(prev)) return;

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReaderPage(
                            mangaId: widget.mangaId,
                            chapters: widget.chapters,
                            currentIndex: prev,
                          ),
                        ),
                      );
                    }
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.vertical_align_top, color: Colors.white),
              onPressed: () {
                if (isVertical) {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                  );
                } else {
                  _pageController.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
              onPressed: widget.currentIndex < widget.chapters.length - 1
                  ? () async {
                      final next = widget.currentIndex + 1;

                      if (!await _checkChapterAccess(next)) return;

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReaderPage(
                            mangaId: widget.mangaId,
                            chapters: widget.chapters,
                            currentIndex: next,
                          ),
                        ),
                      );
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final chapter = widget.chapters[widget.currentIndex];
    final pages = chapter.pages;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Chapter ${chapter.number} (${widget.currentIndex + 1}/${widget.chapters.length})',
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showReaderSettings,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
      body: isVertical
          ? ListView.builder(
              controller: _scrollController,
              itemCount: pages.length,
              itemBuilder: (context, index) {
                return Image.network(
                  pages[index],
                  fit: BoxFit.fitWidth,
                );
              },
            )
          : PageView.builder(
              controller: _pageController,
              itemCount: pages.length,
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  child: Image.network(
                    pages[index],
                    fit: BoxFit.contain,
                  ),
                );
              },
            ),
    );
  }
}
