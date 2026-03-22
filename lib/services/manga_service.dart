import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/manga_model.dart';

class MangaService {
  final _db = FirebaseFirestore.instance;

  /// DÙNG CHO UPDATES PAGE
  Stream<List<MangaModel>> getAllMangas() {
    return _db
        .collection('mangas')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MangaModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// DÙNG CHO DETAIL PAGE
  Stream<QuerySnapshot> getChapters(String mangaId) {
    return _db
        .collection('mangas')
        .doc(mangaId)
        .collection('chapters')
        .orderBy('number')
        .snapshots();
  }
}
