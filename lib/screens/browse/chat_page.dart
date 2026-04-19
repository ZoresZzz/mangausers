import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:flutter_markdown/flutter_markdown.dart'; // Nạp thư viện Markdown vào đây

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, String>> messages = [
    {
      "role": "bot",
      "text":
          "Kon'nichiwa Senpai! ✨ Hôm nay anh muốn AI-chan tìm truyện gì nào? (◕‿◕✿)\n\n*Gợi ý: Anh có thể bảo em **tìm truyện hành động** hoặc **thống kê** một bộ truyện nha!*"
    }
  ];

  bool isTyping = false;

  Future<void> sendMessage() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add({"role": "user", "text": text});
      isTyping = true;
    });

    controller.clear();
    _scrollToBottom();

    try {
      final res = await http.post(
        Uri.parse("http://10.0.2.2:3000/chat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": text}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          messages.add({"role": "bot", "text": data["reply"]});
        });
      } else {
        setState(() {
          messages.add({
            "role": "bot",
            "text":
                "Gomen'nasai! Server của AI-chan đang bị lỗi mạng rồi... (╥﹏╥)"
          });
        });
      }
    } catch (e) {
      setState(() {
        messages.add({"role": "bot", "text": "Lỗi kết nối rồi Senpai ơi! 🥺"});
      });
    } finally {
      setState(() {
        isTyping = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: const Color(0xFF0F0F13).withOpacity(0.5)),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.pinkAccent, Colors.purpleAccent],
                ),
              ),
              child: const CircleAvatar(
                radius: 18,
                backgroundImage: AssetImage("assets/images/ai.jpg"),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "AI-chan 🤖",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  isTyping ? "đang gõ..." : "Online",
                  style: TextStyle(
                    fontSize: 12,
                    color: isTyping ? Colors.pinkAccent : Colors.greenAccent,
                  ),
                )
              ],
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/bg_chat.gif",
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.7),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 90),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    final isUser = msg["role"] == "user";

                    return _buildChatBubble(msg["text"]!, isUser);
                  },
                ),
              ),
              if (isTyping)
                Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "AI-chan đang suy nghĩ... (´･ω･`)",
                      style: TextStyle(
                          color: Colors.pinkAccent.withOpacity(0.8),
                          fontSize: 12),
                    ),
                  ),
                ),
              _buildInputArea(),
            ],
          ),
        ],
      ),
    );
  }

  /// BONG BÓNG CHAT CÓ HỖ TRỢ MARKDOWN
  /// BONG BÓNG CHAT CÓ HỖ TRỢ MARKDOWN (Đã fix lỗi lẹm góc chữ)
  Widget _buildChatBubble(String text, bool isUser) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 14,
              backgroundImage: AssetImage("assets/images/ai.jpg"),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              // BƯỚC 1: Đã xóa padding ở lớp ngoài cùng này
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [Colors.blueAccent, Colors.cyan],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isUser ? null : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUser
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: Colors.pinkAccent.withOpacity(0.3), width: 1),
                boxShadow: [
                  if (isUser)
                    BoxShadow(
                      color: Colors.cyan.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                ],
              ),
              child: isUser
                  ? Padding(
                      // BƯỚC 2: Thêm padding bảo vệ cho text của User
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Text(
                        text,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    )
                  : ClipRRect(
                      // Sửa lại bo góc của ClipRRect cho khớp với viền bên ngoài
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(20),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Padding(
                          // BƯỚC 3: Thêm padding bảo vệ nằm BÊN TRONG hiệu ứng kính mờ
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: MarkdownBody(
                            data: text,
                            selectable: true,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  height: 1.4),
                              strong: const TextStyle(
                                  color: Colors.pinkAccent,
                                  fontWeight: FontWeight.bold),
                              em: const TextStyle(
                                  color: Colors.white70,
                                  fontStyle: FontStyle.italic),
                              listBullet: const TextStyle(
                                  color: Colors.pinkAccent, fontSize: 15),
                              a: const TextStyle(
                                  color: Colors.cyanAccent,
                                  decoration: TextDecoration.underline),
                            ),
                            onTapLink: (text, href, title) {
                              print("Đã bấm vào link: $href");
                            },
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            border: const Border(top: BorderSide(color: Colors.white12)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(25),
                      border:
                          Border.all(color: Colors.pinkAccent.withOpacity(0.3)),
                    ),
                    child: TextField(
                      controller: controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Nói gì đó với AI-chan đi...",
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: isTyping ? null : sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isTyping
                            ? [Colors.grey, Colors.grey.shade700]
                            : [Colors.pinkAccent, Colors.purpleAccent],
                      ),
                      boxShadow: isTyping
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.pinkAccent.withOpacity(0.5),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ],
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
