import 'package:cloud_firestore/cloud_firestore.dart';

class ChapterModel {
  final String id;
  final int number;
  final String title;
  final List<String> pages;

  ///  Hệ thống khóa
  final bool isLocked;
  final int price;

  ///  lượt xem
  final int viewCount;
  final DateTime? createdAt;

  ChapterModel({
    required this.id,
    required this.number,
    required this.title,
    required this.pages,
    required this.isLocked,
    required this.price,
    required this.viewCount,
    this.createdAt,
  });

  factory ChapterModel.fromMap(String id, Map<String, dynamic>? data) {
    if (data == null) {
      return ChapterModel(
        id: id,
        number: 0,
        title: '',
        pages: [],
        isLocked: false,
        price: 0,
        viewCount: 0,
        createdAt: null,
      );
    }

    return ChapterModel(
      id: id,
      number: data['number'] ?? 0,
      title: data['title'] ?? '',
      pages: List<String>.from(data['pages'] ?? []),

      ///  Nếu không có field thì mặc định là free
      isLocked: data['isLocked'] ?? false,
      price: data['price'] ?? 0,

      ///  view
      viewCount: data['viewCount'] ?? 0,

      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Dùng cho admin hoặc upload chapter
  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'title': title,
      'pages': pages,
      'isLocked': isLocked,
      'price': price,
      'viewCount': viewCount,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
