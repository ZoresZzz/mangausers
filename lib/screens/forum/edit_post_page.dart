import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditPostPage extends StatefulWidget {
  final String postId;
  final String oldTitle;
  final String oldContent;
  final String oldImage;

  const EditPostPage({
    super.key,
    required this.postId,
    required this.oldTitle,
    required this.oldContent,
    required this.oldImage,
  });

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  late TextEditingController titleController;
  late TextEditingController contentController;

  Uint8List? newImage; // Ảnh mới nếu người dùng chọn
  bool _isLoading = false; // Trạng thái loading
  bool _removeOldImage = false; // Đánh dấu nếu người dùng muốn xóa ảnh cũ

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.oldTitle);
    contentController = TextEditingController(text: widget.oldContent);
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  /// ===============================
  /// 📸 CHỌN ẢNH TỪ THƯ VIỆN
  /// ===============================
  Future<void> pickImage() async {
    final img = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (img != null) {
      final bytes = await img.readAsBytes();
      setState(() {
        newImage = bytes;
        _removeOldImage = false; // Chọn ảnh mới thì hủy cờ xóa ảnh cũ
      });
    }
  }

  /// ===============================
  /// ☁️ UPLOAD CLOUDINARY
  /// ===============================
  Future<String> uploadToCloudinary(Uint8List imageBytes) async {
    const cloudName = "dj70orbki";
    const uploadPreset = "ml_default";

    final uri =
        Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");
    final request = http.MultipartRequest("POST", uri);

    request.fields['upload_preset'] = uploadPreset;
    request.files.add(http.MultipartFile.fromBytes('file', imageBytes,
        filename: "post_update.jpg"));

    final response = await request.send();
    final resData = await response.stream.bytesToString();
    final jsonData = jsonDecode(resData);

    return jsonData['secure_url'];
  }

  /// ===============================
  /// 🚀 CẬP NHẬT BÀI VIẾT
  /// ===============================
  Future<void> updatePost() async {
    final titleText = titleController.text.trim();
    final contentText = contentController.text.trim();

    if (titleText.isEmpty || contentText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Vui lòng nhập đầy đủ tiêu đề và nội dung")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String imageUrl = widget.oldImage;

      // Nếu người dùng chọn xóa ảnh cũ
      if (_removeOldImage) {
        imageUrl = "";
      }

      // Nếu người dùng chọn ảnh mới
      if (newImage != null) {
        imageUrl = await uploadToCloudinary(newImage!);
      }

      await FirebaseFirestore.instance
          .collection("posts")
          .doc(widget.postId)
          .update({
        "title": titleText,
        "content": contentText,
        "imageUrl": imageUrl,
        "updatedAt":
            FieldValue.serverTimestamp(), // Sử dụng serverTimestamp cho đồng bộ
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Cập nhật bài viết thành công!",
                  style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Logic xác định có hiển thị ảnh hay không
    final bool hasImage =
        newImage != null || (widget.oldImage.isNotEmpty && !_removeOldImage);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F14),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Chỉnh sửa bài viết",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✍️ TIÊU ĐỀ
                _buildLabel("Tiêu đề bài viết"),
                _buildTextField(
                    controller: titleController,
                    hint: "Nhập tiêu đề...",
                    maxLines: 1),

                const SizedBox(height: 20),

                // ✍️ NỘI DUNG
                _buildLabel("Nội dung chi tiết"),
                _buildTextField(
                    controller: contentController,
                    hint: "Nhập nội dung...",
                    maxLines: 8),

                const SizedBox(height: 30),

                // 🖼️ KHU VỰC ẢNH PREVIEW
                _buildLabel("Ảnh đính kèm"),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: hasImage
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: newImage != null
                                    ? Image.memory(newImage!, fit: BoxFit.cover)
                                    : Image.network(widget.oldImage,
                                        fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      newImage = null;
                                      _removeOldImage = true;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.close_rounded,
                                        color: Colors.white, size: 20),
                                  ),
                                ),
                              )
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  color: Colors.white.withOpacity(0.2),
                                  size: 48),
                              const SizedBox(height: 12),
                              const Text("Bấm để chọn ảnh mới",
                                  style: TextStyle(
                                      color: Colors.white24, fontSize: 13)),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 40),

                // 🚀 NÚT CẬP NHẬT
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : updatePost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.white10,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.black, strokeWidth: 3))
                        : const Text("CẬP NHẬT BÀI VIẾT",
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: 1.2)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),

          // LỚP MÀN MỜ KHI ĐANG UPLOAD
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                  child: CircularProgressIndicator(color: Colors.orangeAccent)),
            ),
        ],
      ),
    );
  }

  // =========================================
  // HELPER WIDGETS
  // =========================================

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 14)),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String hint,
      required int maxLines}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: const Color(0xFF1C1C1E),
        contentPadding: const EdgeInsets.all(16),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.white10)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                const BorderSide(color: Colors.orangeAccent, width: 1.5)),
      ),
    );
  }
}
