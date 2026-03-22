import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShelfService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser!.uid;

  /// =========================
  /// TOGGLE LƯU TRUYỆN
  /// =========================
  Future<void> toggleLibrary(String mangaId, Map<String, dynamic> data) async {
    final ref = _firestore
        .collection('users')
        .doc(uid)
        .collection('library')
        .doc(mangaId);

    final doc = await ref.get();

    if (doc.exists) {
      await ref.delete();
    } else {
      await ref.set(data);
    }
  }

  /// =========================
  /// TOGGLE YÊU THÍCH + LIKE COUNT
  /// =========================
  Future<void> toggleFavorite(String mangaId, Map<String, dynamic> data) async {
    final favRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(mangaId);

    final mangaRef = _firestore.collection('mangas').doc(mangaId);

    final doc = await favRef.get();

    if (doc.exists) {
      await favRef.delete();

      await mangaRef.update({
        'likeCount': FieldValue.increment(-1),
      });
    } else {
      await favRef.set(data);

      await mangaRef.update({
        'likeCount': FieldValue.increment(1),
      });
    }
  }

  /// =========================
  /// STREAM CHECK TRẠNG THÁI
  /// =========================
  Stream<bool> isInLibrary(String mangaId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('library')
        .doc(mangaId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<bool> isFavorite(String mangaId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(mangaId)
        .snapshots()
        .map((doc) => doc.exists);
  }
}
