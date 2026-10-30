import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:question_reponse/features/statistics/domain/demographic_statistics.dart';
import 'package:question_reponse/features/statistics/domain/question_statistics.dart';
import 'package:question_reponse/features/statistics/domain/statistics_failure.dart';
import 'package:question_reponse/features/statistics/presentation/controllers/statistics_providers.dart';
import 'package:question_reponse/features/statistics/presentation/widgets/demographic_comparisons.dart';
import 'package:question_reponse/features/statistics/presentation/widgets/response_distribution.dart';
import 'package:question_reponse/features/statistics/presentation/widgets/statistics_chart.dart';

void main() {
  QuestionStatistics stats(int a, int b) => QuestionStatistics(
    totalResponses: a + b,
    choiceCounts: {'a': a, 'b': b},
    blankCount: 0,
    abstentionCount: 0,
    updatedAt: DateTime(2026),
  );
  List<StatisticEntry> entriesOf(QuestionStatistics stats) => [
    StatisticEntry(
      id: 'a',
      label: 'Oui',
      count: stats.countForChoice('a'),
      color: Colors.blue,
    ),
    StatisticEntry(
      id: 'b',
      label: 'Non',
      count: stats.countForChoice('b'),
      color: Colors.red,
    ),
  ];

  test('decodes group statistics without exposing dates of birth', () {
    final data = DemographicStatistics.fromCallable({
      'groups': {
        'country': {
          'FR': {
            'totalResponses': 2,
            'choiceCounts': {'a': 1},
            'blankCount': 1,
          },
        },
        'sex': {},
        'age': {
          'unknown': {'totalResponses': 1, 'abstentionCount': 1},
        },
      },
      'updatedAt': '2026-10-30T00:00:00Z',
    });
    expect(data.groups[DemographicDimension.country]!['FR']!.blankCount, 1);
    expect(
      data.groups[DemographicDimension.age]!['unknown']!.abstentionCount,
      1,
    );
    expect(data.groups[DemographicDimension.sex], isEmpty);
  });

  testWidgets('compares countries, sexes and ordered ages on a small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          demographicStatisticsProvider('q').overrideWith(
            (ref) async => DemographicStatistics({
              DemographicDimension.country: {
                'FR': stats(3, 1),
                'BE': stats(1, 3),
              },
              DemographicDimension.sex: {
                'female': stats(3, 1),
                'male': stats(1, 3),
              },
              DemographicDimension.age: {
                'unknown': stats(1, 0),
                '65plus': stats(0, 1),
                '18-24': stats(3, 1),
              },
            }),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DemographicComparisons(questionId: 'q', entriesOf: entriesOf),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('France'), findsOneWidget);
    expect(find.text('Belgique'), findsOneWidget);
    expect(find.byType(ResponseDistribution), findsNWidgets(2));
    expect(find.text('Oui'), findsOneWidget);
    expect(find.text('Non'), findsOneWidget);
    await tester.tap(find.text('Sexes'));
    await tester.pumpAndSettle();
    expect(find.text('Femmes'), findsOneWidget);
    expect(find.text('Hommes'), findsOneWidget);
    await tester.tap(find.text('Âges'));
    await tester.pumpAndSettle();
    expect(find.text('Âge non renseigné'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('18–24 ans')).dy,
      lessThan(tester.getTopLeft(find.text('65 ans et plus')).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('reports errors and retries instead of showing invented data', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          demographicStatisticsProvider('q').overrideWith((ref) async {
            if (attempts++ == 0) throw const StatisticsFailure('Indisponible.');
            return const DemographicStatistics({});
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DemographicComparisons(questionId: 'q', entriesOf: entriesOf),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Indisponible.'), findsOneWidget);
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.text('Aucune donnée disponible.'), findsOneWidget);
    expect(attempts, 2);
  });

  testWidgets('distribution uses actual proportions and handles zero counts', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            child: ResponseDistribution(entries: entriesOf(stats(3, 1))),
          ),
        ),
      ),
    );
    final blue = find.byWidgetPredicate(
      (w) => w is ColoredBox && w.color == Colors.blue,
    );
    final red = find.byWidgetPredicate(
      (w) => w is ColoredBox && w.color == Colors.red,
    );
    expect(tester.getSize(blue), const Size(150, 10));
    expect(tester.getSize(red), const Size(50, 10));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResponseDistribution(entries: entriesOf(stats(0, 0))),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('Aucune réponse'), findsOneWidget);
  });
}
