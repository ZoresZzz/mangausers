import 'package:cloud_firestore/cloud_firestore.dart';

class MangaModel {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final String? bannerUrl; // 🔥 THÊM DÒNG NÀY
  final String author;
  final List<String> genres;
  final DateTime createdAt;
  final String status;

  final int likeCount;
  final int viewCount;
  final int weeklyViews;
  final int lastChapter;

  MangaModel({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    this.bannerUrl, // 🔥 THÊM
    required this.author,
    required this.genres,
    required this.createdAt,
    required this.status,
    required this.likeCount,
    required this.viewCount,
    required this.weeklyViews,
    required this.lastChapter,
  });

  factory MangaModel.fromMap(String id, Map<String, dynamic>? data) {
    if (data == null) {
      return MangaModel(
        id: id,
        title: '',
        description: '',
        coverUrl: '',
        bannerUrl: null, // 🔥
        author: '',
        genres: [],
        createdAt: DateTime.now(),
        status: 'ongoing',
        likeCount: 0,
        viewCount: 0,
        weeklyViews: 0,
        lastChapter: 0,
      );
    }

    return MangaModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      coverUrl: data['coverUrl'] ?? '',
      bannerUrl: data['bannerUrl'], // 🔥 THÊM
      author: data['author'] ?? '',
      genres: List<String>.from(data['genres'] ?? []),
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      status: data['status'] ?? 'ongoing',
      likeCount: data['likeCount'] ?? 0,
      viewCount: data['viewCount'] ?? 0,
      weeklyViews: data['weeklyViews'] ?? 0,
      lastChapter: data['lastChapter'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'coverUrl': coverUrl,
      'bannerUrl': bannerUrl, // 🔥 THÊM
      'author': author,
      'genres': genres,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'likeCount': likeCount,
      'viewCount': viewCount,
      'weeklyViews': weeklyViews,
      'lastChapter': lastChapter,
    };
  }
}
