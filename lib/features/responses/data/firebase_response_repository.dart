import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:question_reponse/features/responses/domain/response_failure.dart';
import 'package:question_reponse/features/responses/domain/response_repository.dart';
import 'package:question_reponse/features/responses/domain/user_response.dart';
import 'package:question_reponse/features/statistics/domain/question_statistics.dart';

class FirebaseResponseRepository implements ResponseRepository {
  FirebaseResponseRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Stream<List<UserResponse>> watchResponses(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('responses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => [
            for (final document in snapshot.docs)
              UserResponse.fromFirestore(document.data()),
          ],
        );
  }

  @override
  Stream<UserResponse?> watchResponse({
    required String userId,
    required String questionId,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('responses')
        .doc(questionId)
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          return data == null ? null : UserResponse.fromFirestore(data);
        });
  }

  @override
  Future<SubmitResult> submit({
    required String questionId,
    required ResponseSubmission submission,
  }) async {
    try {
      final payload = <String, Object?>{
        'questionId': questionId,
        'type': submission.type.name,
      };
      if (submission.choiceId case final choiceId?) {
        payload['choiceId'] = choiceId;
      }
      final result = await _functions
          .httpsCallable('submitResponse')
          .call<Map<Object?, Object?>>(payload);
      return SubmitResult(
        response: UserResponse.fromCallable(
          result.data['response']! as Map<Object?, Object?>,
        ),
        statistics: QuestionStatistics.fromCallable(
          result.data['statistics']! as Map<Object?, Object?>,
        ),
      );
    } on FirebaseFunctionsException catch (error) {
      throw ResponseFailure(_messageFor(error.message));
    }
  }

  String _messageFor(String? code) {
    return switch (code) {
      'question_not_found' => 'Cette question est introuvable.',
      'question_not_published' => 'Cette question n’est pas encore publiée.',
      'response_type_not_allowed' =>
        'Cette question n’accepte pas ce type de réponse.',
      'already_answered' => 'Vous avez déjà participé à cette question.',
      'invalid_choice' ||
      'invalid_response_type' => 'Cette réponse n’est pas valide.',
      'profile_required' => 'Complétez votre profil avant de répondre.',
      'not_authorized' => 'Votre session a expiré. Reconnectez-vous.',
      _ => 'Impossible d’enregistrer votre réponse pour le moment.',
    };
  }
}
