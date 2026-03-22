import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_post_page.dart';
import 'post_detail_page.dart';
import '../verify_phone/verify_phone_page.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    _tab = TabController(length: 3, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Diễn đàn"),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: "Gần đây"),
            Tab(text: "Nổi bật"),
            Tab(text: "Của tôi"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          PostList(type: "recent"),
          PostList(type: "hot"),
          PostList(type: "me"),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser!;

              final userDoc = await FirebaseFirestore.instance
                  .collection("users")
                  .doc(user.uid)
                  .get();

              final phone = userDoc.data()?['phone'];

              if (phone == null || phone.isEmpty) {
                /// ❌ chưa xác thực
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Bạn cần xác thực số điện thoại")),
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VerifyPhonePage()),
                );
                return;
              }

              /// ✅ đã xác thực → cho đăng bài
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddPostPage()),
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text("Đăng bài"),
          ),
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////
/// 🔥 LIST COMPONENT (DÙNG CHUNG)
////////////////////////////////////////////////////////

class PostList extends StatelessWidget {
  final String type;
  const PostList({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    Query query = FirebaseFirestore.instance.collection('posts');

    /// 🎯 LOGIC FILTER
    if (type == "recent") {
      query = query.orderBy('createdAt', descending: true);
    } else if (type == "hot") {
      query = query.orderBy('likes', descending: true);
    } else if (type == "me") {
      query = query.where('userId', isEqualTo: user.uid);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data!.docs;

        if (posts.isEmpty) {
          return const Center(child: Text("Không có bài viết"));
        }

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, i) {
            final post = posts[i];
            final data = post.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostDetailPage(postId: post.id),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// 👤 USER + TIME
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundImage: (data['avatar'] != null &&
                                    data['avatar'].toString().isNotEmpty)
                                ? NetworkImage(data['avatar'])
                                : null,
                            child: (data['avatar'] == null ||
                                    data['avatar'].toString().isEmpty)
                                ? Text((data['username'] ?? "U")[0])
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['username'] ?? "Unknown",
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  timeAgo(data['createdAt']),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      /// 🟠 TITLE (NỔI BẬT)
                      Text(
                        data['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// ❤️ + 💬
                      Row(
                        children: [
                          const Icon(Icons.favorite,
                              size: 16, color: Colors.red),
                          const SizedBox(width: 4),
                          Text("${data['likes'] ?? 0}"),
                          const SizedBox(width: 15),
                          const Icon(Icons.comment, size: 16),
                          const SizedBox(width: 4),
                          CommentCount(postId: post.id),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class CommentCount extends StatelessWidget {
  final String postId;
  const CommentCount({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("comments")
          .where("postId", isEqualTo: postId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Text("💬 0");
        }

        final count = snapshot.data!.docs.length;

        return Text("💬 $count");
      },
    );
  }
}

String timeAgo(Timestamp? timestamp) {
  if (timestamp == null) return "Vừa xong";

  final date = timestamp.toDate();
  final now = DateTime.now();
  final diff = now.difference(date);

  String time;

  if (diff.inSeconds < 60) {
    time = "Vừa xong";
  } else if (diff.inMinutes < 60) {
    time = "${diff.inMinutes} phút trước";
  } else if (diff.inHours < 24) {
    time = "${diff.inHours} giờ trước";
  } else if (diff.inDays < 7) {
    time = "${diff.inDays} ngày trước";
  } else {
    time = "";
  }

  /// 🔥 FORMAT NGÀY GIỜ
  final fullDate =
      "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} "
      "${date.day}/${date.month}/${date.year}";

  return time.isNotEmpty ? "$time • $fullDate" : fullDate;
}
