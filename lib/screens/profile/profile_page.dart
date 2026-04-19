import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '/payment/payment_page.dart';
import '/screens/payment_history/payment_history_page.dart';
import '../change_phone/change_phone_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F14),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_circle_outlined,
                  size: 80, color: Colors.white.withOpacity(0.1)),
              const SizedBox(height: 16),
              const Text("Bạn chưa đăng nhập",
                  style: TextStyle(color: Colors.white70, fontSize: 18)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F14),
        elevation: 0,
        title: const Text('Tài Khoản',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () => showProfileMenu(context, user.uid),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(
                child: CircularProgressIndicator(color: Colors.orangeAccent));

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final points = data?['points'] ?? 0;
          final username = data?['username'] ?? "Người dùng";
          final phone = data?['phone'] ?? "Chưa xác thực SĐT";

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),

                /// 👤 USER HEADER
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                            colors: [Colors.orangeAccent, Colors.redAccent]),
                      ),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: const Color(0xFF1C1C1E),
                        child: Text(username[0].toUpperCase(),
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(username,
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(phone,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 14)),
                          Text("UID: ${user.uid.substring(0, 8)}...",
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.3),
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 35),

                /// 💳 POINT CARD (VIP STYLE)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF4D4D), Color(0xFFF9CB28)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFFFF4D4D).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10))
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("SỐ DƯ ĐIỂM",
                                  style: TextStyle(
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      letterSpacing: 1.2)),
                              const SizedBox(height: 8),
                              Text("$points",
                                  style: const TextStyle(
                                      fontSize: 42,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black87)),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => showRechargeSheet(context, user.uid),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16)),
                              child: const Icon(Icons.add_rounded,
                                  size: 32, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                /// 🛠 CHỨC NĂNG CHÍNH
                _buildMenuTitle("Giao dịch"),
                _buildMenuItem(
                  icon: Icons.history_rounded,
                  color: Colors.blueAccent,
                  title: "Lịch sử nạp chi tiết",
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PaymentHistoryPage())),
                ),

                const SizedBox(height: 25),
                _buildMenuTitle("Hoạt động gần đây"),

                SizedBox(
                  height: 300,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("transactions")
                        .where("userId", isEqualTo: user.uid)
                        .orderBy("time", descending: true)
                        .limit(5)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                            child: Text("Chưa có giao dịch nào.",
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.2))));
                      }
                      final docs = snapshot.data!.docs;
                      return ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final trans =
                              docs[index].data() as Map<String, dynamic>;
                          if (trans['method'] == "PayOS" &&
                              trans['status'] != "success")
                            return const SizedBox();

                          return _buildTransactionItem(trans);
                        },
                      );
                    },
                  ),
                ),

                /// LOGOUT
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  icon:
                      const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  label: const Text("Đăng xuất tài khoản",
                      style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // WIDGET UI COMPONENTS
  // ==========================================

  Widget _buildMenuTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 4),
        child: Text(title,
            style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1)),
      ),
    );
  }

  Widget _buildMenuItem(
      {required IconData icon,
      required Color color,
      required String title,
      required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            color: Colors.white10, size: 14),
        onTap: onTap,
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> data) {
    final bool isSuccess = data['status'] == "success";
    final bool isRejected = data['status'] == "rejected";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E).withOpacity(0.5),
          borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isSuccess
                ? Colors.green.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
            child: Icon(Icons.monetization_on_rounded,
                color: isSuccess ? Colors.greenAccent : Colors.orangeAccent,
                size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("+${data['points']} Điểm",
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text("${data['price']} VNĐ",
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSuccess
                  ? Colors.greenAccent.withOpacity(0.1)
                  : (isRejected
                      ? Colors.white10
                      : Colors.orangeAccent.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isSuccess ? "ĐÃ NẠP" : (isRejected ? "BỊ TỪ CHỐI" : "CHỜ DUYỆT"),
              style: TextStyle(
                color: isSuccess
                    ? Colors.greenAccent
                    : (isRejected ? Colors.white38 : Colors.orangeAccent),
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// ĐIỀU KHIỂN NẠP ĐIỂM
// ==========================================

void showRechargeSheet(BuildContext context, String userId) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1C1C1E),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Text("Nạp Thêm Điểm",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
            const SizedBox(height: 20),
            rechargeItem(context, userId, "Gói Khởi Đầu", 15000, 15),
            rechargeItem(context, userId, "Gói Phổ Thông", 50000, 50),
            rechargeItem(context, userId, "Gói Fan Cứng", 100000, 100),
            rechargeItem(context, userId, "Gói Đại Gia", 200000, 200),
            rechargeItem(context, userId, "Gói Vô Cực", 500000, 500),
            const SizedBox(height: 30),
          ],
        ),
      );
    },
  );
}

Widget rechargeItem(
    BuildContext context, String userId, String title, int price, int points) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10)),
    child: ListTile(
      title: Text(title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text("${NumberFormat.decimalPattern().format(price)} VNĐ",
          style: const TextStyle(
              color: Colors.orangeAccent, fontWeight: FontWeight.w600)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
            color: Colors.orangeAccent,
            borderRadius: BorderRadius.circular(12)),
        child: Text("$points P",
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.w900)),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    PaymentPage(userId: userId, price: price, points: points)));
      },
    ),
  );
}

// ==========================================
// CÀI ĐẶT TÀI KHOẢN
// ==========================================

void showProfileMenu(BuildContext context, String uid) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1C1C1E),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Cài đặt tài khoản",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
            const SizedBox(height: 20),
            _buildActionItem(Icons.edit_note_rounded, "Đổi tên hiển thị", () {
              Navigator.pop(context);
              showChangeNameDialog(context, uid);
            }),
            _buildActionItem(Icons.lock_reset_rounded, "Thay đổi mật khẩu", () {
              Navigator.pop(context);
              showChangePasswordDialog(context);
            }),
            _buildActionItem(
                Icons.phone_android_rounded, "Cập nhật số điện thoại", () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ChangePhonePage()));
            }),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  );
}

Widget _buildActionItem(IconData icon, String title, VoidCallback onTap) {
  return ListTile(
    leading: Icon(icon, color: Colors.white70),
    title: Text(title,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
    trailing: const Icon(Icons.arrow_forward_ios_rounded,
        color: Colors.white10, size: 14),
    onTap: onTap,
  );
}

// Các hàm showChangeNameDialog và showChangePasswordDialog giữ nguyên logic nhưng có thể chỉnh màu Alert cho đồng bộ.
// (Gợi ý: Dùng backgroundColor: const Color(0xFF1C1C1E) cho AlertDialog)

void showChangeNameDialog(BuildContext context, String uid) {
  TextEditingController controller = TextEditingController();
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Đổi tên mới",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Nhập tên bạn muốn hiển thị",
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
            enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white10)),
          ),
        ),
        actions: [
          TextButton(
              child: const Text("Hủy", style: TextStyle(color: Colors.white38)),
              onPressed: () => Navigator.pop(context)),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent),
              child: const Text("Lưu thay đổi",
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
              onPressed: () async {
                String newName = controller.text.trim();
                if (newName.isEmpty) return;
                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(uid)
                    .update({"username": newName});
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
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Đổi mật khẩu",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField(currentPass, "Mật khẩu hiện tại"),
              const SizedBox(height: 12),
              _buildDialogField(newPass, "Mật khẩu mới"),
              const SizedBox(height: 12),
              _buildDialogField(confirmPass, "Xác nhận mật khẩu mới"),
            ],
          ),
        ),
        actions: [
          TextButton(
              child: const Text("Hủy", style: TextStyle(color: Colors.white38)),
              onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            child: const Text("Cập nhật",
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
            onPressed: () async {
              try {
                if (newPass.text != confirmPass.text) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Mật khẩu xác nhận không khớp")));
                  return;
                }
                AuthCredential credential = EmailAuthProvider.credential(
                    email: user!.email!, password: currentPass.text);
                await user.reauthenticateWithCredential(credential);
                await user.updatePassword(newPass.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Đã đổi mật khẩu thành công"),
                    backgroundColor: Colors.green));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Lỗi: $e"),
                    backgroundColor: Colors.redAccent));
              }
            },
          ),
        ],
      );
    },
  );
}

Widget _buildDialogField(TextEditingController controller, String label) {
  return TextField(
    controller: controller,
    obscureText: true,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white38),
      enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white10)),
      focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.orangeAccent)),
    ),
  );
}
