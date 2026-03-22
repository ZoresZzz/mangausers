import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostDetailPage extends StatefulWidget {
  final String postId;
  const PostDetailPage({super.key, required this.postId});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final comment = TextEditingController();
  void showReplyDialog(String parentId) {
    final replyController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Trả lời"),
          content: TextField(
            controller: replyController,
            decoration: const InputDecoration(hintText: "Nhập reply..."),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser!;

                await FirebaseFirestore.instance.collection("comments").add({
                  "postId": widget.postId,
                  "content": replyController.text,
                  "userId": user.uid,
                  "username": user.displayName ?? "User",
                  "parentId": parentId,
                  "likes": 0,
                  "likedBy": [],
                  "createdAt": FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);
              },
              child: const Text("Gửi"),
            )
          ],
        );
      },
    );
  }

  /// ===============================
  /// COMMENT
  /// ===============================
  Future<void> addComment({String? parentId}) async {
    if (comment.text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser!;

    await FirebaseFirestore.instance.collection("comments").add({
      "postId": widget.postId,
      "content": comment.text,
      "userId": user.uid,
      "username": user.displayName ?? "User",
      "parentId": parentId, // 🔥 QUAN TRỌNG
      "likes": 0,
      "likedBy": [],
      "createdAt": FieldValue.serverTimestamp(),
    });

    comment.clear();
  }

//like comment
  Future<void> likeComment(String commentId) async {
    final user = FirebaseAuth.instance.currentUser!;
    final ref =
        FirebaseFirestore.instance.collection("comments").doc(commentId);

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

      tx.update(ref, {
        "likedBy": likedBy,
        "likes": likes,
      });
    });
  }

  /// ===============================
  /// LIKE (FIX CHUẨN)
  /// ===============================
  Future<void> likePost() async {
    final user = FirebaseAuth.instance.currentUser!;
    final ref =
        FirebaseFirestore.instance.collection("posts").doc(widget.postId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);

      if (!snap.exists) return;

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

      tx.update(ref, {
        "likedBy": likedBy,
        "likes": likes,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(title: const Text("Chi tiết")),
      body: Column(
        children: [
          /// ===============================
          /// POST (REALTIME FIX)
          /// ===============================
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection("posts")
                .doc(widget.postId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Container();

              final data = snapshot.data!.data() as Map<String, dynamic>;

              /// 🔥 FIX: kiểm tra đã like chưa
              final likedBy = List.from(data['likedBy'] ?? []);
              final isLiked = likedBy.contains(user.uid);

              return Card(
                margin: const EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundImage: (data['avatar'] != null &&
                                        data['avatar'].toString().isNotEmpty)
                                    ? NetworkImage(data['avatar'])
                                    : null,
                                child: (data['avatar'] == null ||
                                        data['avatar'].toString().isEmpty)
                                    ? Text((data['username'] ?? "U")[0])
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                data['username'] ?? "Unknown",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            data['title'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['content']),

                          /// 🔥 HIỂN THỊ ẢNH
                          if (data['imageUrl'] != null &&
                              data['imageUrl'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => FullScreenImagePage(
                                            imageUrl: data['imageUrl'],
                                          ),
                                        ),
                                      );
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        data['imageUrl'],
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )),
                            ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      /// ❤️ LIKE BUTTON
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.grey,
                            ),
                            onPressed: likePost,
                          ),
                          Text("${data['likes'] ?? 0}")
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          ),

          /// ===============================
          /// COMMENTS (FULL REPLY + LIKE)
          /// ===============================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("comments")
                  .where("postId", isEqualTo: widget.postId)
                  .where("parentId", isEqualTo: null)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data.containsKey('parentId') &&
                      data['parentId'] == null;
                }).toList();

                return ListView(
                  children: comments.map((doc) {
                    return CommentItem(
                      commentDoc: doc,
                      postId: widget.postId,
                      onReply: (id) {
                        showReplyDialog(id);
                      },
                      likeComment: likeComment, // 🔥 truyền xuống
                    );
                  }).toList(),
                );
              },
            ),
          ),

          /// ===============================
          /// INPUT COMMENT
          /// ===============================
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: comment,
                    decoration: const InputDecoration(
                      hintText: "Viết bình luận...",
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: addComment,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class CommentItem extends StatelessWidget {
  final DocumentSnapshot commentDoc;
  final String postId;
  final Function(String) onReply;
  final Function(String) likeComment;

  const CommentItem({
    super.key,
    required this.commentDoc,
    required this.postId,
    required this.onReply,
    required this.likeComment,
  });

  @override
  Widget build(BuildContext context) {
    final data = commentDoc.data() as Map<String, dynamic>;
    final user = FirebaseAuth.instance.currentUser!;

    final likedBy = List.from(data['likedBy'] ?? []);
    final isLiked = likedBy.contains(user.uid);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// COMMENT CHÍNH
        ListTile(
          leading: CircleAvatar(
            child: Text((data['username'] ?? "U")[0]),
          ),
          title: Text(data['username'] ?? ""),
          subtitle: Text(data['content']),
        ),

        /// ACTIONS
        Padding(
          padding: const EdgeInsets.only(left: 70),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => likeComment(commentDoc.id),
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 16,
                      color: isLiked ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text("${data['likes'] ?? 0}"),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              GestureDetector(
                onTap: () => onReply(commentDoc.id),
                child: const Text("Reply"),
              ),
            ],
          ),
        ),

        /// 🔥 REPLY
        Padding(
          padding: const EdgeInsets.only(left: 50),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("comments")
                .where("parentId", isEqualTo: commentDoc.id)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Container();

              final replies = snapshot.data!.docs;

              return Column(
                children: replies.map((r) {
                  final d = r.data() as Map<String, dynamic>;

                  return ListTile(
                    leading: CircleAvatar(
                      radius: 12,
                      child: Text((d['username'] ?? "U")[0]),
                    ),
                    title: Text(d['username'] ?? ""),
                    subtitle: Text(d['content']),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImagePage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}
