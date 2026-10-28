import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:question_reponse/features/questions/data/firestore_question_repository.dart';
import 'package:question_reponse/features/questions/domain/question.dart';
import 'package:question_reponse/features/questions/domain/question_choice.dart';
import 'package:question_reponse/features/questions/domain/question_repository.dart';

final questionRepositoryProvider = Provider<QuestionRepository>(
  (ref) => FirestoreQuestionRepository(FirebaseFirestore.instance),
);

final publishedQuestionsProvider = StreamProvider<List<Question>>(
  (ref) => ref.watch(questionRepositoryProvider).watchPublishedQuestions(),
);

final latestPublishedQuestionProvider = StreamProvider<Question?>(
  (ref) => ref.watch(questionRepositoryProvider).watchLatestPublishedQuestion(),
);

final questionProvider = StreamProvider.family<Question?, String>(
  (ref, questionId) =>
      ref.watch(questionRepositoryProvider).watchQuestion(questionId),
);

final questionChoicesProvider =
    StreamProvider.family<List<QuestionChoice>, String>(
      (ref, questionId) =>
          ref.watch(questionRepositoryProvider).watchChoices(questionId),
    );
