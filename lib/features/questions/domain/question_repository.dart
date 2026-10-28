import 'package:question_reponse/features/questions/domain/question.dart';
import 'package:question_reponse/features/questions/domain/question_choice.dart';

abstract interface class QuestionRepository {
  Stream<List<Question>> watchPublishedQuestions();

  /// Most recently published question, without loading the whole history.
  Stream<Question?> watchLatestPublishedQuestion();

  Stream<Question?> watchQuestion(String questionId);

  Stream<List<QuestionChoice>> watchChoices(String questionId);
}
