import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/payment/payment_page.dart';
import '/screens/payment_history/payment_history_page.dart';
import '../change_phone/change_phone_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Chưa đăng nhập")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final points = data?['points'] ?? 0;
          final username = data?['username'] ?? "User";
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                /// USER INFO
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      child: Text(
                        username[0].toUpperCase(),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// USERNAME
                          Text(
                            username,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            data?['phone'] ?? "Chưa xác thực",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 4),

                          /// USER UID
                          Text(
                            "UID: ${user.uid}",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// SETTINGS BUTTON
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {
                        showProfileMenu(context, user.uid);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                /// CARD ĐIỂM
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      /// POINT
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Số điểm của bạn",
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "$points Point",
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ],
                      ),

                      /// NẠP ĐIỂM
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          size: 36,
                          color: Colors.deepOrange,
                        ),
                        onPressed: () {
                          showRechargeSheet(context, user.uid);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// NÚT XEM LỊCH SỬ FULL
                ElevatedButton.icon(
                  icon: const Icon(Icons.history),
                  label: const Text("Xem lịch sử nạp chi tiết"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PaymentHistoryPage(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                /// LỊCH SỬ NẠP
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Lịch sử nạp điểm",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("transactions")
                        .where("userId", isEqualTo: user.uid)
                        .orderBy("time", descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text("Lỗi: ${snapshot.error}"),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;

                      if (docs.isEmpty) {
                        return const Center(
                          child: Text("Chưa có giao dịch"),
                        );
                      }

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;

                          final points = data['points'] ?? 0;
                          final price = data['price'] ?? 0;
                          final status = data['status'] ?? "pending";

                          Color statusColor;
                          String statusText;

                          if (status == "approved") {
                            statusColor = Colors.green;
                            statusText = "Đã nạp";
                          } else if (status == "rejected") {
                            statusColor = Colors.grey;
                            statusText = "Từ chối";
                          } else {
                            statusColor = Colors.red;
                            statusText = "Đang chờ";
                          }

                          return Card(
                            child: ListTile(
                              leading: const Icon(
                                Icons.monetization_on,
                                color: Colors.orange,
                              ),
                              title: Text(
                                "+$points điểm",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text("$price VNĐ"),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
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
                ),

                /// LOGOUT
                ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Đăng xuất'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

////////////////////////////////////////////////////
//// BOTTOM SHEET NẠP ĐIỂM
////////////////////////////////////////////////////

void showRechargeSheet(BuildContext context, String userId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Nạp điểm",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            rechargeItem(context, userId, "Gói 1", 15000, 100),
            rechargeItem(context, userId, "Gói 2", 50000, 333),
            rechargeItem(context, userId, "Gói 3", 100000, 666),
            rechargeItem(context, userId, "Gói 4", 200000, 1333),
            rechargeItem(context, userId, "Gói 5", 500000, 3333),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  );
}

////////////////////////////////////////////////////
//// ITEM GÓI NẠP
////////////////////////////////////////////////////

Widget rechargeItem(
  BuildContext context,
  String userId,
  String title,
  int price,
  int points,
) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 6),
    child: ListTile(
      title: Text(title),
      subtitle: Text("Giá: $price VNĐ\nNhận: $points điểm"),
      trailing: ElevatedButton(
        child: const Text("Mua"),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentPage(
                userId: userId,
                price: price,
                points: points,
              ),
            ),
          );
        },
      ),
    ),
  );
}

void showProfileMenu(BuildContext context, String uid) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Cài đặt tài khoản",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("Đổi tên"),
              onTap: () {
                Navigator.pop(context);
                showChangeNameDialog(context, uid);
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text("Đổi mật khẩu"),
              onTap: () {
                Navigator.pop(context);
                showChangePasswordDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text("Đổi số điện thoại"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChangePhonePage()),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

void showChangeNameDialog(BuildContext context, String uid) {
  TextEditingController controller = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Đổi tên"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Nhập tên mới",
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Hủy"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
              child: const Text("Lưu"),
              onPressed: () async {
                String newName = controller.text.trim();

                if (newName.isEmpty) return;

                /// UPDATE FIRESTORE
                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(uid)
                    .update({
                  "username": newName,
                });

                /// UPDATE FIREBASE AUTH
                await FirebaseAuth.instance.currentUser!
                    .updateDisplayName(newName);

                Navigator.pop(context);
              }),
        ],
      );
    },
  );
}

void showChangePasswordDialog(BuildContext context) {
  TextEditingController currentPass = TextEditingController();
  TextEditingController newPass = TextEditingController();
  TextEditingController confirmPass = TextEditingController();

  final user = FirebaseAuth.instance.currentUser;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Đổi mật khẩu"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              /// MẬT KHẨU HIỆN TẠI
              TextField(
                controller: currentPass,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Mật khẩu hiện tại",
                ),
              ),

              const SizedBox(height: 10),

              /// MẬT KHẨU MỚI
              TextField(
                controller: newPass,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Mật khẩu mới",
                ),
              ),

              const SizedBox(height: 10),

              /// XÁC NHẬN
              TextField(
                controller: confirmPass,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Xác nhận mật khẩu",
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Hủy"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Đổi mật khẩu"),
            onPressed: () async {
              try {
                /// CHECK CONFIRM
                if (newPass.text != confirmPass.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Mật khẩu xác nhận không đúng"),
                    ),
                  );
                  return;
                }

                /// REAUTH
                AuthCredential credential = EmailAuthProvider.credential(
                  email: user!.email!,
                  password: currentPass.text,
                );

                await user.reauthenticateWithCredential(credential);

                /// UPDATE PASSWORD
                await user.updatePassword(newPass.text);

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Đổi mật khẩu thành công"),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Lỗi: $e"),
                  ),
                );
              }
            },
          ),
        ],
      );
    },
  );
}
