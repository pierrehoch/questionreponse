import 'package:question_reponse/features/statistics/domain/question_statistics.dart';

enum DemographicDimension {
  country('country', 'Pays'),
  sex('sex', 'Sexes'),
  age('age', 'Âges');

  const DemographicDimension(this.key, this.label);
  final String key;
  final String label;
}

class DemographicStatistics {
  const DemographicStatistics(this.groups);

  final Map<DemographicDimension, Map<String, QuestionStatistics>> groups;

  factory DemographicStatistics.fromCallable(Map<Object?, Object?> data) {
    final groups = data['groups']! as Map<Object?, Object?>;
    return DemographicStatistics({
      for (final dimension in DemographicDimension.values)
        dimension: {
          for (final entry
              in (groups[dimension.key]! as Map<Object?, Object?>).entries)
            entry.key! as String: QuestionStatistics.fromCallable({
              ...entry.value! as Map<Object?, Object?>,
              'updatedAt': data['updatedAt'],
            }),
        },
    });
  }
}
