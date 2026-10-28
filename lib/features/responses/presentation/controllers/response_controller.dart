import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:question_reponse/features/auth/presentation/controllers/auth_controller.dart';
import 'package:question_reponse/features/responses/data/firebase_response_repository.dart';
import 'package:question_reponse/features/responses/domain/response_repository.dart';
import 'package:question_reponse/features/responses/domain/user_response.dart';

final responseRepositoryProvider = Provider<ResponseRepository>(
  (ref) => FirebaseResponseRepository(
    FirebaseFirestore.instance,
    FirebaseFunctions.instanceFor(region: 'europe-west9'),
  ),
);

final userResponseProvider = StreamProvider.family<UserResponse?, String>((
  ref,
  questionId,
) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value(null);
  }
  return ref
      .watch(responseRepositoryProvider)
      .watchResponse(userId: user.id, questionId: questionId);
});

final userResponsesProvider = StreamProvider<List<UserResponse>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value(const []);
  }
  return ref.watch(responseRepositoryProvider).watchResponses(user.id);
});

final responseControllerProvider =
    NotifierProvider<ResponseController, AsyncValue<void>>(
      ResponseController.new,
    );

class ResponseController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Returns the committed response and statistics, or null on failure.
  Future<SubmitResult?> submit({
    required String questionId,
    required ResponseSubmission submission,
  }) async {
    state = const AsyncLoading();
    try {
      final result = await ref
          .read(responseRepositoryProvider)
          .submit(questionId: questionId, submission: submission);
      state = const AsyncData(null);
      return result;
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
