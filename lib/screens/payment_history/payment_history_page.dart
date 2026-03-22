import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentHistoryPage extends StatelessWidget {
  const PaymentHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final stream = FirebaseFirestore.instance
        .collection("transactions")
        .where("userId", isEqualTo: user!.uid)
        .orderBy("time", descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text("Lịch sử nạp điểm")),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("Bạn chưa có giao dịch nào"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              final points = data["points"] ?? 0;
              final price = data["price"] ?? 0;
              final status = data["status"] ?? "pending";

              Color statusColor;
              String statusText;

              if (status == "approved") {
                statusColor = Colors.green;
                statusText = "Đã nạp";
              } else if (status == "rejected") {
                statusColor = Colors.grey;
                statusText = "Bị từ chối";
              } else {
                statusColor = Colors.red;
                statusText = "Đang chờ";
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.monetization_on),
                  title: Text("+$points điểm"),
                  subtitle: Text("$price VNĐ"),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
