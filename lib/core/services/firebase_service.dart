import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload ảnh manga cover
  static Future<String> uploadMangaCover(File image) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();

    final ref = _storage.ref().child('manga_covers').child('$fileName.jpg');

    await ref.putFile(image);

    return await ref.getDownloadURL();
  }
}
