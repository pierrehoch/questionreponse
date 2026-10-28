import 'package:question_reponse/features/statistics/domain/question_statistics.dart';
import 'package:question_reponse/features/statistics/domain/statistics_filter.dart';

abstract interface class StatisticsRepository {
  Stream<QuestionStatistics?> watchSummary(String questionId);

  Future<QuestionStatistics> getFiltered({
    required String questionId,
    required StatisticsFilter filter,
  });
}
