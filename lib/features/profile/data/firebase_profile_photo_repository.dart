import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:question_reponse/features/profile/domain/profile_failure.dart';

class FirebaseProfilePhotoRepository {
  FirebaseProfilePhotoRepository(this._storage);

  final FirebaseStorage _storage;

  Future<String> upload({
    required String userId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    if (bytes.length > 5 * 1024 * 1024) {
      throw const ProfileFailure('La photo ne doit pas dépasser 5 Mo.');
    }
    if (!const {'image/jpeg', 'image/png'}.contains(contentType)) {
      throw const ProfileFailure('Choisissez une image JPEG ou PNG.');
    }

    try {
      final reference = _storage.ref('users/$userId/profile.jpg');
      await reference.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );
      return await reference.getDownloadURL();
    } on FirebaseException {
      throw const ProfileFailure(
        'Impossible d’envoyer la photo pour le moment.',
      );
    }
  }
}
