import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:question_reponse/features/auth/presentation/controllers/auth_controller.dart';
import 'package:question_reponse/features/profile/data/firebase_profile_photo_repository.dart';
import 'package:question_reponse/features/profile/data/firestore_profile_repository.dart';
import 'package:question_reponse/features/profile/domain/profile_failure.dart';
import 'package:question_reponse/features/profile/domain/profile_repository.dart';
import 'package:question_reponse/features/profile/domain/user_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => FirestoreProfileRepository(FirebaseFirestore.instance),
);

final profilePhotoRepositoryProvider = Provider<FirebaseProfilePhotoRepository>(
  (ref) => FirebaseProfilePhotoRepository(FirebaseStorage.instance),
);

final profileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value(null);
  }

  return ref.watch(profileRepositoryProvider).watchProfile(user.id);
});

final profileControllerProvider =
    NotifierProvider<ProfileController, AsyncValue<void>>(
      ProfileController.new,
    );

class ProfileController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> save(ProfileInput input) async {
    final user = ref.read(authStateProvider).value;
    if (user == null || user.email == null) {
      state = AsyncError(
        const ProfileFailure('Votre session a expiré. Reconnectez-vous.'),
        StackTrace.current,
      );
      return false;
    }

    state = const AsyncLoading();
    try {
      await ref
          .read(profileRepositoryProvider)
          .saveProfile(userId: user.id, email: user.email!, input: input);
      state = const AsyncData(null);
      return true;
    } on Object catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<String?> uploadPhoto({
    required Uint8List bytes,
    required String contentType,
  }) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      state = AsyncError(
        const ProfileFailure('Votre session a expiré. Reconnectez-vous.'),
        StackTrace.current,
      );
      return null;
    }

    state = const AsyncLoading();
    try {
      final url = await ref
          .read(profilePhotoRepositoryProvider)
          .upload(userId: user.id, bytes: bytes, contentType: contentType);
      state = const AsyncData(null);
      return url;
    } on Object catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  void clearError() {
    if (state.hasError) {
      state = const AsyncData(null);
    }
  }
}
