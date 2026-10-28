import 'package:question_reponse/features/responses/domain/user_response.dart';

abstract interface class ResponseRepository {
  Stream<List<UserResponse>> watchResponses(String userId);

  Stream<UserResponse?> watchResponse({
    required String userId,
    required String questionId,
  });

  Future<SubmitResult> submit({
    required String questionId,
    required ResponseSubmission submission,
  });
}
