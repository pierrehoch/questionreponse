import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:question_reponse/features/profile/domain/profile_failure.dart';
import 'package:question_reponse/features/profile/domain/profile_repository.dart';
import 'package:question_reponse/features/profile/domain/user_profile.dart';

class FirestoreProfileRepository implements ProfileRepository {
  FirestoreProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<UserProfile?> watchProfile(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((
      snapshot,
    ) {
      final data = snapshot.data();
      return data == null ? null : UserProfile.fromFirestore(snapshot.id, data);
    });
  }

  @override
  Future<void> saveProfile({
    required String userId,
    required String email,
    required ProfileInput input,
  }) async {
    final normalizedUsername = input.normalizedUsername;
    final userReference = _firestore.collection('users').doc(userId);
    final usernameReference = _firestore
        .collection('usernames')
        .doc(normalizedUsername);

    try {
      await _firestore.runTransaction((transaction) async {
        final currentProfile = await transaction.get(userReference);
        final usernameOwner = await transaction.get(usernameReference);
        final ownerId = usernameOwner.data()?['userId'] as String?;

        if (ownerId != null && ownerId != userId) {
          throw const ProfileFailure('Ce pseudo est déjà utilisé.');
        }

        final currentData = currentProfile.data();
        final previousUsername = currentData?['normalizedUsername'] as String?;
        final createdAt =
            currentData?['createdAt'] ?? FieldValue.serverTimestamp();

        if (previousUsername != null &&
            previousUsername != normalizedUsername) {
          transaction.delete(
            _firestore.collection('usernames').doc(previousUsername),
          );
        }

        if (!usernameOwner.exists) {
          transaction.set(usernameReference, {
            'userId': userId,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        transaction.set(userReference, {
          'username': input.username.trim(),
          'normalizedUsername': normalizedUsername,
          'email': email,
          'photoUrl': input.photoUrl,
          'country': input.country.trim().toUpperCase(),
          'sex': input.sex.value,
          'createdAt': createdAt,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on ProfileFailure {
      rethrow;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw const ProfileFailure(
          'Ce profil n’a pas pu être enregistré. Vérifiez les informations.',
        );
      }
      throw const ProfileFailure(
        'Impossible d’enregistrer le profil pour le moment.',
      );
    }
  }
}
