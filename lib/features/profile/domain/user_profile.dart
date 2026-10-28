import 'package:cloud_firestore/cloud_firestore.dart';

enum UserSex {
  male('male', 'Homme'),
  female('female', 'Femme'),
  other('other', 'Autre');

  const UserSex(this.value, this.label);

  final String value;
  final String label;

  static UserSex fromValue(String value) {
    return values.firstWhere((sex) => sex.value == value);
  }
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.normalizedUsername,
    required this.email,
    required this.country,
    required this.sex,
    required this.createdAt,
    required this.updatedAt,
    this.photoUrl,
  });

  final String id;
  final String username;
  final String normalizedUsername;
  final String email;
  final String? photoUrl;
  final String country;
  final UserSex sex;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory UserProfile.fromFirestore(String id, Map<String, Object?> data) {
    return UserProfile(
      id: id,
      username: data['username']! as String,
      normalizedUsername: data['normalizedUsername']! as String,
      email: data['email']! as String,
      photoUrl: data['photoUrl'] as String?,
      country: data['country']! as String,
      sex: UserSex.fromValue(data['sex']! as String),
      createdAt: (data['createdAt']! as Timestamp).toDate(),
      updatedAt: (data['updatedAt']! as Timestamp).toDate(),
    );
  }
}

class ProfileInput {
  const ProfileInput({
    required this.username,
    required this.country,
    required this.sex,
    this.photoUrl,
  });

  final String username;
  final String country;
  final UserSex sex;
  final String? photoUrl;

  String get normalizedUsername => normalizeUsername(username);
}

String normalizeUsername(String username) => username.trim().toLowerCase();
