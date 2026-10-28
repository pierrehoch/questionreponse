import 'package:flutter_test/flutter_test.dart';
import 'package:question_reponse/features/statistics/domain/question_statistics.dart';
import 'package:question_reponse/features/statistics/domain/statistics_filter.dart';

void main() {
  test('calculates percentages from total participation', () {
    final statistics = QuestionStatistics(
      totalResponses: 20,
      choiceCounts: const {'choice-a': 10},
      blankCount: 4,
      abstentionCount: 6,
      updatedAt: DateTime(2026),
    );

    expect(statistics.percentage(statistics.countForChoice('choice-a')), 50);
    expect(statistics.percentage(statistics.blankCount), 20);
    expect(statistics.percentage(statistics.abstentionCount), 30);
  });

  test('returns zero percent when no participation exists', () {
    final statistics = QuestionStatistics(
      totalResponses: 0,
      choiceCounts: const {},
      blankCount: 0,
      abstentionCount: 0,
      updatedAt: DateTime(2026),
    );

    expect(statistics.percentage(0), 0);
  });

  test('normalizes and labels combined filters', () {
    final filter = StatisticsFilter(country: ' fr ', sex: 'female');

    expect(filter.country, 'FR');
    expect(filter.label, 'Pays : France · Sexe : Femme');
    expect(filter.copyWith(country: () => null).label, 'Sexe : Femme');
    expect(filter.isEmpty, isFalse);
  });
}
