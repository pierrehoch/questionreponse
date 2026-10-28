import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:question_reponse/features/questions/domain/question.dart';
import 'package:question_reponse/features/questions/domain/question_choice.dart';
import 'package:question_reponse/features/questions/domain/question_repository.dart';

class FirestoreQuestionRepository implements QuestionRepository {
  FirestoreQuestionRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<Question>> watchPublishedQuestions() {
    return _publishedQuery().snapshots().map(
      (snapshot) => [
        for (final document in snapshot.docs)
          Question.fromFirestore(document.id, document.data()),
      ],
    );
  }

  @override
  Stream<Question?> watchLatestPublishedQuestion() {
    return _publishedQuery().limit(1).snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }
      final document = snapshot.docs.first;
      return Question.fromFirestore(document.id, document.data());
    });
  }

  Query<Map<String, dynamic>> _publishedQuery() {
    return _firestore
        .collection('questions')
        .where('status', isEqualTo: QuestionStatus.published.name)
        .orderBy('publishedAt', descending: true);
  }

  @override
  Stream<Question?> watchQuestion(String questionId) {
    return _firestore.collection('questions').doc(questionId).snapshots().map((
      snapshot,
    ) {
      final data = snapshot.data();
      return data == null ? null : Question.fromFirestore(snapshot.id, data);
    });
  }

  @override
  Stream<List<QuestionChoice>> watchChoices(String questionId) {
    return _firestore
        .collection('questions')
        .doc(questionId)
        .collection('choices')
        .orderBy('position')
        .snapshots()
        .map(
          (snapshot) => [
            for (final document in snapshot.docs)
              QuestionChoice.fromFirestore(document.id, document.data()),
          ],
        );
  }
}
