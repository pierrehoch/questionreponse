import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:question_reponse/features/statistics/domain/question_statistics.dart';
import 'package:question_reponse/features/statistics/domain/statistics_failure.dart';
import 'package:question_reponse/features/statistics/domain/statistics_filter.dart';
import 'package:question_reponse/features/statistics/domain/statistics_repository.dart';

class FirestoreStatisticsRepository implements StatisticsRepository {
  FirestoreStatisticsRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Future<QuestionStatistics> getFiltered({
    required String questionId,
    required StatisticsFilter filter,
  }) async {
    if (filter.isEmpty) {
      throw const StatisticsFailure('Sélectionnez au moins un filtre.');
    }

    try {
      final payload = <String, Object?>{'questionId': questionId};
      if (filter.country case final country?) {
        payload['country'] = country;
      }
      if (filter.sex case final sex?) {
        payload['sex'] = sex;
      }
      final result = await _functions
          .httpsCallable('getFilteredStatistics')
          .call<Map<Object?, Object?>>(payload);
      return QuestionStatistics.fromCallable(result.data);
    } on FirebaseFunctionsException catch (error) {
      final message = switch (error.message) {
        'statistics_not_available' =>
          'Les statistiques sont disponibles après participation.',
        'invalid_country' ||
        'invalid_sex' ||
        'filters_required' => 'Les filtres sélectionnés ne sont pas valides.',
        'question_not_found' => 'Cette question est introuvable.',
        _ => 'Impossible de calculer ces statistiques pour le moment.',
      };
      throw StatisticsFailure(message);
    }
  }

  @override
  Stream<QuestionStatistics?> watchSummary(String questionId) {
    return _firestore
        .collection('questions')
        .doc(questionId)
        .collection('stats')
        .doc('summary')
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          return data == null ? null : QuestionStatistics.fromFirestore(data);
        });
  }
}
