import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:question_reponse/features/statistics/domain/question_statistics.dart';

enum ResponseType {
  choice,
  blank,
  abstention;

  static ResponseType fromValue(String value) {
    return values.firstWhere((type) => type.name == value);
  }
}

class UserResponse {
  const UserResponse({
    required this.questionId,
    required this.type,
    required this.country,
    required this.sex,
    required this.createdAt,
    this.choiceId,
  });

  final String questionId;
  final ResponseType type;
  final String? choiceId;
  final String country;
  final String sex;
  final DateTime createdAt;

  factory UserResponse.fromFirestore(Map<String, Object?> data) {
    return UserResponse(
      questionId: data['questionId']! as String,
      type: ResponseType.fromValue(data['type']! as String),
      choiceId: data['choiceId'] as String?,
      country: data['country']! as String,
      sex: data['sex']! as String,
      createdAt: (data['createdAt']! as Timestamp).toDate(),
    );
  }

  factory UserResponse.fromCallable(Map<Object?, Object?> data) {
    return UserResponse(
      questionId: data['questionId']! as String,
      type: ResponseType.fromValue(data['type']! as String),
      choiceId: data['choiceId'] as String?,
      country: data['country']! as String,
      sex: data['sex']! as String,
      createdAt:
          DateTime.tryParse(data['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

/// Outcome of a successful submission, returned by the backend so the
/// results can be displayed without waiting for Firestore listeners.
class SubmitResult {
  const SubmitResult({required this.response, required this.statistics});

  final UserResponse response;
  final QuestionStatistics statistics;
}

class ResponseSubmission {
  const ResponseSubmission._({required this.type, this.choiceId});

  factory ResponseSubmission.choice(String choiceId) {
    if (choiceId.trim().isEmpty) {
      throw ArgumentError.value(choiceId, 'choiceId');
    }
    return ResponseSubmission._(type: ResponseType.choice, choiceId: choiceId);
  }

  const ResponseSubmission.blank() : this._(type: ResponseType.blank);

  const ResponseSubmission.abstention() : this._(type: ResponseType.abstention);

  final ResponseType type;
  final String? choiceId;
}
