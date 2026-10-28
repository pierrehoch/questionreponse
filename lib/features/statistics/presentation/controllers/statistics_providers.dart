import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:question_reponse/features/statistics/data/firestore_statistics_repository.dart';
import 'package:question_reponse/features/statistics/domain/question_statistics.dart';
import 'package:question_reponse/features/statistics/domain/statistics_filter.dart';
import 'package:question_reponse/features/statistics/domain/statistics_repository.dart';

final statisticsRepositoryProvider = Provider<StatisticsRepository>(
  (ref) => FirestoreStatisticsRepository(
    FirebaseFirestore.instance,
    FirebaseFunctions.instanceFor(region: 'europe-west9'),
  ),
);

final questionStatisticsProvider =
    StreamProvider.family<QuestionStatistics?, String>(
      (ref, questionId) =>
          ref.watch(statisticsRepositoryProvider).watchSummary(questionId),
    );

typedef FilteredStatisticsRequest = ({
  String questionId,
  StatisticsFilter filter,
});

final filteredQuestionStatisticsProvider =
    FutureProvider.family<QuestionStatistics, FilteredStatisticsRequest>(
      (ref, request) => ref
          .watch(statisticsRepositoryProvider)
          .getFiltered(questionId: request.questionId, filter: request.filter),
    );
