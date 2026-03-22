import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QrPaymentPage extends StatefulWidget {
  final String userId;
  final int points;
  final int price;
  final String method;

  const QrPaymentPage({
    super.key,
    required this.userId,
    required this.points,
    required this.price,
    required this.method,
  });

  @override
  State<QrPaymentPage> createState() => _QrPaymentPageState();
}

class _QrPaymentPageState extends State<QrPaymentPage> {
  bool loading = false;

  String? txId;
  String? message;

  @override
  void initState() {
    super.initState();

    txId = createTransactionId(widget.userId);

    /// nội dung chuyển khoản
    message = "NAP_${widget.userId.substring(0, 5).toUpperCase()}_$txId";
  }

  /// tạo mã giao dịch
  String createTransactionId(String userId) {
    final time = DateTime.now().millisecondsSinceEpoch;
    return "TX${userId.substring(0, 4).toUpperCase()}$time";
  }

  Future<void> pay() async {
    setState(() {
      loading = true;
    });

    /// lưu yêu cầu nạp tiền (chờ admin duyệt)
    await FirebaseFirestore.instance.collection("transactions").doc(txId).set({
      "txId": txId,
      "userId": widget.userId,
      "points": widget.points,
      "price": widget.price,
      "method": widget.method,
      "message": message,
      "status": "pending",
      "time": Timestamp.now(),
    });

    setState(() {
      loading = false;
    });

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Đã gửi yêu cầu nạp tiền"),
          content: const Text(
              "Sau khi admin kiểm tra chuyển khoản, điểm sẽ được cộng."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("OK"),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    /// QR VietQR
    final qrUrl =
        "https://img.vietqr.io/image/MB-0397062876-compact.png?amount=${widget.price}&addInfo=$message";

    return Scaffold(
      appBar: AppBar(
        title: Text("Thanh toán ${widget.method}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            const Text(
              "Quét QR để thanh toán",
              style: TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 20),

            /// QR CODE
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.network(
                qrUrl,
                width: 220,
                height: 220,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              "${widget.price} VNĐ",
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text("Nhận ${widget.points} điểm"),

            const SizedBox(height: 25),

            const Text(
              "Nội dung chuyển khoản",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 5),

            SelectableText(
              message ?? "",
              style: const TextStyle(
                fontSize: 18,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : pay,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Tôi đã thanh toán"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
