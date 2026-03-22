import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class PaymentPage extends StatefulWidget {
  final String userId;
  final int points;
  final int price;

  const PaymentPage({
    super.key,
    required this.userId,
    required this.points,
    required this.price,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String method = "PayOS";

  /// ===============================
  /// 🔥 PAYOS
  /// ===============================
  Future<void> openPayOS() async {
    try {
      final url = Uri.parse("http://192.168.2.23:3000/create-payment");

      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "amount": widget.price,
          "userId": widget.userId,
        }),
      );

      final data = jsonDecode(res.body);
      final checkoutUrl = data["checkoutUrl"];

      if (checkoutUrl != null) {
        await launchUrl(
          Uri.parse(checkoutUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception("Không lấy được link PayOS");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi PayOS: $e")),
      );
    }
  }

  /// ===============================
  /// QR BACKUP
  /// ===============================
  void openQR() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrPaymentPage(
          userId: widget.userId,
          points: widget.points,
          price: widget.price,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thanh toán")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.monetization_on),
                title: Text("${widget.points} Điểm"),
                subtitle: Text("Giá: ${widget.price} VNĐ"),
              ),
            ),
            const SizedBox(height: 25),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Phương thức thanh toán",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            RadioListTile(
              value: "PayOS",
              groupValue: method,
              onChanged: (v) => setState(() => method = v!),
              title: const Text("Thanh toán PayOS"),
            ),
            RadioListTile(
              value: "Bank",
              groupValue: method,
              onChanged: (v) => setState(() => method = v!),
              title: const Text("QR ngân hàng"),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (method == "PayOS") {
                    openPayOS();
                  } else {
                    openQR();
                  }
                },
                child: const Text("Thanh toán"),
              ),
            )
          ],
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////
/// QR PAYMENT PAGE
////////////////////////////////////////////////////////

class QrPaymentPage extends StatefulWidget {
  final String userId;
  final int points;
  final int price;

  const QrPaymentPage({
    super.key,
    required this.userId,
    required this.points,
    required this.price,
  });

  @override
  State<QrPaymentPage> createState() => _QrPaymentPageState();
}

class _QrPaymentPageState extends State<QrPaymentPage> {
  bool loading = false;

  Future<void> confirmPayment() async {
    setState(() => loading = true);

    String txId = DateTime.now().millisecondsSinceEpoch.toString();

    await FirebaseFirestore.instance.collection("transactions").doc(txId).set({
      "txId": txId,
      "userId": widget.userId,
      "points": widget.points,
      "price": widget.price,
      "method": "PayOS",
      "status": "pending",
      "content": widget.userId, // 🔥 thêm dòng này
      "time": Timestamp.now(),
    });

    await FirebaseAnalytics.instance.logEvent(
      name: "purchase",
      parameters: {
        "value": widget.price,
      },
    );

    setState(() => loading = false);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Đã gửi yêu cầu"),
        content: const Text("Chờ admin xác nhận"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qrUrl =
        "https://img.vietqr.io/image/MB-0397062876-compact.png?amount=${widget.price}&addInfo=${widget.userId}";

    return Scaffold(
      appBar: AppBar(title: const Text("QR Thanh toán")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Image.network(qrUrl, width: 220),
            const SizedBox(height: 20),
            Text("${widget.price} VNĐ"),
            const SizedBox(height: 10),
            Text("UID: ${widget.userId}"),
            ElevatedButton(
              onPressed: confirmPayment,
              child: const Text("Tôi đã thanh toán"),
            )
          ],
        ),
      ),
    );
  }
}
