import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'edit_post_page.dart';

class PostDetailPage extends StatefulWidget {
  final String postId;
  const PostDetailPage({super.key, required this.postId});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final commentController = TextEditingController();

  // =========================================
  // LOGIC XỬ LÝ (DELETE, LIKE, COMMENT)
  // =========================================

  Future<void> _handleDeletePost() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title:
            const Text("Xóa bài viết", style: TextStyle(color: Colors.white)),
        content: const Text(
            "Bạn có chắc muốn xóa không? Hành động này không thể hoàn tác.",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  const Text("Hủy", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Xóa",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection("posts")
          .doc(widget.postId)
          .delete();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Đã xóa bài viết")));
      }
    }
  }

  Future<void> addComment({String? parentId, String? replyText}) async {
    final text = replyText ?? commentController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser!;
    final postDoc = await FirebaseFirestore.instance
        .collection("posts")
        .doc(widget.postId)
        .get();
    final postOwnerId = postDoc.data()?['userId'];

    await FirebaseFirestore.instance.collection("comments").add({
      "postId": widget.postId,
      "content": text,
      "userId": user.uid,
      "username": user.displayName ?? "User",
      "parentId": parentId,
      "likes": 0,
      "likedBy": [],
      "createdAt": FieldValue.serverTimestamp(),
    });

    // Thông báo cho chủ bài viết hoặc người được reply
    if (parentId == null && postOwnerId != user.uid) {
      _sendNotification(postOwnerId, "comment", text);
    } else if (parentId != null) {
      final parentSnap = await FirebaseFirestore.instance
          .collection("comments")
          .doc(parentId)
          .get();
      if (parentSnap['userId'] != user.uid) {
        _sendNotification(parentSnap['userId'], "reply", text,
            commentId: parentId);
      }
    }

    commentController.clear();
    FocusScope.of(context).unfocus();
  }

  Future<void> _sendNotification(String targetUid, String type, String msg,
      {String? commentId}) async {
    final user = FirebaseAuth.instance.currentUser!;
    await FirebaseFirestore.instance.collection("notifications").add({
      "userId": targetUid,
      "fromUser": user.displayName ?? "User",
      "type": type,
      "postId": widget.postId,
      if (commentId != null) "commentId": commentId,
      "content": msg,
      "isRead": false,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  void showReplyDialog(String parentId) {
    final replyController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text("Trả lời", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: replyController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Nhập phản hồi...",
            hintStyle: TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.orangeAccent)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.orangeAccent)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text("Hủy", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            onPressed: () {
              addComment(parentId: parentId, replyText: replyController.text);
              Navigator.pop(context);
            },
            child: const Text("Gửi",
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Future<void> _likeAction(String collection, String id) async {
    final user = FirebaseAuth.instance.currentUser!;
    final ref = FirebaseFirestore.instance.collection(collection).doc(id);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() as Map<String, dynamic>;
      List likedBy = List.from(data['likedBy'] ?? []);
      int likes = data['likes'] ?? 0;
      if (likedBy.contains(user.uid)) {
        likedBy.remove(user.uid);
        likes--;
      } else {
        likedBy.add(user.uid);
        likes++;
      }
      tx.update(ref, {"likedBy": likedBy, "likes": likes});
    });
  }

  // =========================================
  // GIAO DIỆN CHÍNH
  // =========================================

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F14),
        elevation: 0,
        title: const Text("Chi tiết bài viết",
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [_buildMenuButton(user.uid)],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildPostHeader(user.uid),
                  _buildCommentSection(),
                ],
              ),
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMenuButton(String currentUid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("posts")
          .doc(widget.postId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data?.data() == null) return const SizedBox();
        final data = snap.data!.data() as Map<String, dynamic>;
        if (data['userId'] != currentUid) return const SizedBox();

        return PopupMenuButton<String>(
          color: const Color(0xFF1C1C1E),
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          onSelected: (val) {
            if (val == 'edit') {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => EditPostPage(
                          postId: widget.postId,
                          oldTitle: data['title'],
                          oldContent: data['content'],
                          oldImage: data['imageUrl'] ?? "")));
            } else {
              _handleDeletePost();
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
                value: 'edit',
                child: Text("Sửa bài viết",
                    style: TextStyle(color: Colors.white))),
            const PopupMenuItem(
                value: 'delete',
                child:
                    Text("Xóa bài", style: TextStyle(color: Colors.redAccent))),
          ],
        );
      },
    );
  }

  Widget _buildPostHeader(String currentUid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("posts")
          .doc(widget.postId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const LinearProgressIndicator(color: Colors.orangeAccent);
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) return const SizedBox(); // Post đã bị xóa

        final isLiked = (data['likedBy'] as List? ?? []).contains(currentUid);

        return Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF1C1C1E),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white10,
                    backgroundImage: data['avatar'] != null
                        ? NetworkImage(data['avatar'])
                        : null,
                    child: data['avatar'] == null
                        ? Text(data['username'][0],
                            style: const TextStyle(color: Colors.white))
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['username'] ?? "User",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      Text(_formatDate(data['createdAt']),
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(data['title'],
                  style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Text(data['content'],
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 15, height: 1.4)),
              if (data['imageUrl'] != null &&
                  data['imageUrl'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => FullScreenImagePage(
                                  imageUrl: data['imageUrl']))),
                      child: Image.network(data['imageUrl'],
                          width: double.infinity, fit: BoxFit.cover),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _buildLikeButton(isLiked, data['likes'] ?? 0),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLikeButton(bool isLiked, int count) {
    return InkWell(
      onTap: () => _likeAction("posts", widget.postId),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: isLiked
                ? Colors.redAccent.withOpacity(0.1)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? Colors.redAccent : Colors.white54, size: 18),
          const SizedBox(width: 6),
          Text("$count",
              style: TextStyle(
                  color: isLiked ? Colors.redAccent : Colors.white54,
                  fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  // =========================================
  // BÌNH LUẬN (GIẢI PHÁP LỌC Ở DART - KHÔNG CẦN INDEX)
  // =========================================
  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text("Bình luận",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ),

        // Gọi Stream 1 lần duy nhất lấy TẤT CẢ bình luận của bài viết này
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("comments")
              .where("postId", isEqualTo: widget.postId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return const Center(
                  child: CircularProgressIndicator(color: Colors.orangeAccent));
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
              return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                      child: Text("Chưa có bình luận nào.",
                          style: TextStyle(color: Colors.white38))));

            final allDocs = snapshot.data!.docs.toList();

            // 1. Lọc ra các bình luận chính (không có parentId)
            final mainComments = allDocs
                .where((d) =>
                    (d.data() as Map<String, dynamic>)['parentId'] == null)
                .toList();

            // 2. Tự sắp xếp giảm dần (Mới nhất lên đầu) bằng Dart
            mainComments.sort((a, b) {
              final tA =
                  (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
              final tB =
                  (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
              if (tA == null && tB == null) return 0;
              if (tA == null) return 1;
              if (tB == null) return -1;
              return tB.compareTo(tA);
            });

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mainComments.length,
              itemBuilder: (context, i) =>
                  _buildCommentItem(mainComments[i], allDocs),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCommentItem(
      DocumentSnapshot doc, List<DocumentSnapshot> allDocs) {
    final data = doc.data() as Map<String, dynamic>;
    final user = FirebaseAuth.instance.currentUser!;
    final isLiked = (data['likedBy'] as List? ?? []).contains(user.uid);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white10,
                  child: Text((data['username'] ?? "U")[0],
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['username'] ?? "User",
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(data['content'] ?? "",
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(_formatDate(data['createdAt']),
                            style: const TextStyle(
                                color: Colors.white24, fontSize: 11)),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => _likeAction("comments", doc.id),
                          child: Text("Thích (${data['likes'] ?? 0})",
                              style: TextStyle(
                                  color: isLiked
                                      ? Colors.redAccent
                                      : Colors.white38,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => showReplyDialog(doc.id),
                          child: const Text("Trả lời",
                              style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Lọc Replies từ mảng allDocs (Không cần gọi Firebase thêm nữa)
        _buildReplies(doc.id, allDocs),
      ],
    );
  }

  Widget _buildReplies(String parentId, List<DocumentSnapshot> allDocs) {
    final replies = allDocs
        .where(
            (d) => (d.data() as Map<String, dynamic>)['parentId'] == parentId)
        .toList();
    if (replies.isEmpty) return const SizedBox();

    // Sắp xếp Reply tăng dần (Cũ nhất xếp trên)
    replies.sort((a, b) {
      final tA = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
      final tB = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
      if (tA == null && tB == null) return 0;
      if (tA == null) return -1;
      if (tB == null) return 1;
      return tA.compareTo(tB);
    });

    return Padding(
      padding: const EdgeInsets.only(left: 48),
      child: Column(
        children: replies.map((r) {
          final rData = r.data() as Map<String, dynamic>;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.subdirectory_arrow_right,
                    size: 16, color: Colors.white12),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rData['username'] ?? "User",
                            style: const TextStyle(
                                color: Colors.white60,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(rData['content'] ?? "",
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16)
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          border:
              Border(top: BorderSide(color: Colors.white.withOpacity(0.05)))),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: commentController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Viết bình luận...",
              hintStyle: const TextStyle(color: Colors.white30),
              filled: true,
              fillColor: Colors.black.withOpacity(0.2),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
            onPressed: () => addComment(),
            icon: const Icon(Icons.send_rounded, color: Colors.orangeAccent)),
      ]),
    );
  }

  String _formatDate(Timestamp? t) =>
      t == null ? "..." : DateFormat("HH:mm dd/MM/yyyy").format(t.toDate());
}

class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;
  const FullScreenImagePage({super.key, required this.imageUrl});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: InkWell(
        onTap: () => Navigator.pop(context),
        child: Center(child: InteractiveViewer(child: Image.network(imageUrl))),
      ),
    );
  }
}
