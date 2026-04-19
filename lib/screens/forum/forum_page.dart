import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_post_page.dart';
import 'post_detail_page.dart';
import '../verify_phone/verify_phone_page.dart';
import 'package:intl/intl.dart';
import 'notification_page.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String selectedTag = "all";

  final List<String> tags = [
    "all",
    "thảo luận",
    "tìm truyện",
    "tâm sự",
    "chia sẻ"
  ];

  @override
  void initState() {
    _tab = TabController(length: 3, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      endDrawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F14),
        elevation: 0,
        title: const Text(
          "Diễn Đàn",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
        ),

        actions: [
          /// 🔔 NOTIFICATION
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("notifications")
                .where("userId",
                    isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                .where("isRead", isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              int count = snapshot.hasData ? snapshot.data!.docs.length : 0;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationPage(),
                        ),
                      );
                    },
                  ),

                  /// 🔴 BADGE
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "$count",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                ],
              );
            },
          ),

          /// ⚙️ FILTER BUTTON
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.tune_rounded, color: Colors.white),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],

        /// 🔥 TABBAR PHẢI NẰM Ở ĐÂY
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.orangeAccent,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Mới nhất"),
            Tab(text: "Xu hướng"),
            Tab(text: "Của tôi"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          PostList(type: "recent", selectedTag: selectedTag),
          PostList(type: "hot", selectedTag: selectedTag),
          PostList(type: "me", selectedTag: selectedTag),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleCreatePost,
        backgroundColor: Colors.orangeAccent,
        icon:
            const Icon(Icons.edit_note_rounded, color: Colors.black, size: 28),
        label: const Text("Đăng bài",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: const Color(0xFF1A1A1A),
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text("Khám phá chủ đề",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900)),
              ),
              Expanded(
                child: ListView(
                  children: tags.map((tag) {
                    final isSelected = selectedTag == tag;
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 24),
                      leading: Icon(
                          tag == "all"
                              ? Icons.grid_view_rounded
                              : Icons.tag_rounded,
                          color: isSelected
                              ? Colors.orangeAccent
                              : Colors.white54),
                      title: Text(
                          tag == "all" ? "Tất cả bài viết" : tag.toUpperCase(),
                          style: TextStyle(
                              color: isSelected
                                  ? Colors.orangeAccent
                                  : Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                      onTap: () {
                        setState(() => selectedTag = tag);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleCreatePost() async {
    final user = FirebaseAuth.instance.currentUser!;
    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();
    final phone = userDoc.data()?['phone'];

    if (phone == null || phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vui lòng xác thực SĐT để đăng bài")));
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const VerifyPhonePage()));
      return;
    }

    if (!mounted) return;
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const AddPostPage()));
  }
}

class PostList extends StatelessWidget {
  final String type;
  final String selectedTag;

  const PostList({super.key, required this.type, required this.selectedTag});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    Query query = FirebaseFirestore.instance.collection('posts');

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
        if (!snapshot.hasData)
          return const Center(
              child: CircularProgressIndicator(color: Colors.orangeAccent));

        final posts = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return selectedTag == "all" ? true : data["tag"] == selectedTag;
        }).toList();

        if (posts.isEmpty) {
          return const Center(
              child: Text("Chưa có bài viết nào ở đây",
                  style: TextStyle(color: Colors.white54)));
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
          itemCount: posts.length,
          itemBuilder: (context, i) {
            final data = posts[i].data() as Map<String, dynamic>;
            final postId = posts[i].id;

            return Card(
              color: const Color(0xFF1C1C1E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PostDetailPage(postId: postId))),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                Colors.orangeAccent.withOpacity(0.1),
                            backgroundImage:
                                (data['avatar']?.isNotEmpty ?? false)
                                    ? NetworkImage(data['avatar'])
                                    : null,
                            child: (data['avatar']?.isEmpty ?? true)
                                ? Text(data['username']?[0] ?? "U",
                                    style: const TextStyle(
                                        color: Colors.orangeAccent))
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['username'] ?? "User",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                Text(timeAgo(data['createdAt']),
                                    style: const TextStyle(
                                        color: Colors.white38, fontSize: 11)),
                              ],
                            ),
                          ),
                          if (data['tag'] != null) _buildTagBadge(data['tag']),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(data['title'] ?? '',
                          style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              height: 1.3)),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _buildStatItem(Icons.favorite_rounded,
                              Colors.redAccent, "${data['likes'] ?? 0}"),
                          const SizedBox(width: 20),
                          _buildStatItem(
                              Icons.chat_bubble_rounded, Colors.blueAccent, "",
                              isComment: true, postId: postId),
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

  Widget _buildTagBadge(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Text("#$tag",
          style: const TextStyle(
              color: Colors.blueAccent,
              fontSize: 11,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatItem(IconData icon, Color color, String count,
      {bool isComment = false, String? postId}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color.withOpacity(0.8)),
        const SizedBox(width: 6),
        isComment
            ? CommentCount(postId: postId!)
            : Text(count,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
      ],
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
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Text("$count",
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.bold));
      },
    );
  }
}

String timeAgo(Timestamp? timestamp) {
  if (timestamp == null) return "Vừa xong";
  final diff = DateTime.now().difference(timestamp.toDate());
  if (diff.inMinutes < 1) return "Vừa xong";
  if (diff.inMinutes < 60) return "${diff.inMinutes} phút trước";
  if (diff.inHours < 24) return "${diff.inHours} giờ trước";
  if (diff.inDays < 7) return "${diff.inDays} ngày trước";
  return DateFormat("HH:mm dd/MM/yyyy").format(timestamp.toDate());
}
