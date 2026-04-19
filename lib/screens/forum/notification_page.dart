import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post_detail_page.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(title: const Text("Thông báo")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("notifications")
            .where("userId", isEqualTo: user.uid)
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("Không có thông báo"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;

              final type = data['type'];
              final isRead = data['isRead'] ?? false;

              String text = "";

              if (type == "comment") {
                text = "${data['fromUser']} đã bình luận bài viết của bạn";
              } else {
                text = "${data['fromUser']} đã trả lời bình luận của bạn";
              }

              return ListTile(
                tileColor: isRead ? null : Colors.orange.withOpacity(0.1),
                leading: const Icon(Icons.notifications),
                title: Text(text),
                subtitle: Text(data['content'] ?? ""),
                onTap: () async {
                  /// 🔥 MARK AS READ
                  await FirebaseFirestore.instance
                      .collection("notifications")
                      .doc(docs[i].id)
                      .update({"isRead": true});

                  /// 🔥 MỞ POST
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostDetailPage(postId: data['postId']),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
