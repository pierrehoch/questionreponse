import 'package:question_reponse/features/profile/domain/user_profile.dart';

abstract interface class ProfileRepository {
  Stream<UserProfile?> watchProfile(String userId);

  Future<void> saveProfile({
    required String userId,
    required String email,
    required ProfileInput input,
  });
}
