import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:question_reponse/features/statistics/presentation/widgets/statistics_chart.dart';
import 'package:question_shared/question_shared.dart';

void main() {
  const entries = [
    StatisticEntry(id: 'a', label: 'Chat', count: 3, color: Colors.indigo),
    StatisticEntry(id: 'b', label: 'Chien', count: 1, color: Colors.teal),
  ];

  Widget chart({
    bool animateVote = false,
    bool showLive = false,
    QuestionChartType chartType = QuestionChartType.donut,
    List<StatisticEntry> entries = entries,
  }) => MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: StatisticsChart(
          entries: entries,
          chartType: chartType,
          highlightedId: 'a',
          animateVote: animateVote,
          showLive: showLive,
        ),
      ),
    ),
  );

  testWidgets('shows the vote impact before settling on final results', (
    tester,
  ) async {
    await tester.pumpWidget(chart(animateVote: true));
    await tester.pump(const Duration(milliseconds: 1000));

    // Results without the user's vote: 2 of 3 participants.
    expect(find.text('3'), findsOneWidget);
    expect(find.text('67 %  2'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('4'), findsOneWidget);
    expect(find.text('75 %  3'), findsOneWidget);
    expect(find.text('25 %  1'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('shows final results directly without vote animation', (
    tester,
  ) async {
    await tester.pumpWidget(chart());
    await tester.pumpAndSettle();

    expect(find.text('4'), findsOneWidget);
    expect(find.text('+1'), findsNothing);
  });

  for (final type in QuestionChartType.values) {
    testWidgets('renders the ${type.key} chart with a legend', (tester) async {
      await tester.pumpWidget(chart(chartType: type, showLive: true));
      await tester.pumpAndSettle();

      expect(find.text('Chat'), findsWidgets);
      expect(find.text('75 %  3'), findsOneWidget);
      expect(find.text('25 %  1'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('● En direct'), findsOneWidget);
      expect(
        tester.getCenter(find.text('● En direct')).dy,
        closeTo(tester.getCenter(find.text('4')).dy, 1),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('versus chart shows both sides and a VS badge', (tester) async {
    await tester.pumpWidget(chart(chartType: QuestionChartType.versus));
    await tester.pumpAndSettle();

    expect(find.text('VS'), findsOneWidget);
    expect(find.text('75 %'), findsOneWidget);
    expect(find.text('25 %'), findsOneWidget);
  });

  testWidgets('podium ranks the top answers with medals', (tester) async {
    const many = [
      StatisticEntry(id: 'a', label: 'Chat', count: 1, color: Colors.indigo),
      StatisticEntry(id: 'b', label: 'Chien', count: 5, color: Colors.teal),
      StatisticEntry(id: 'c', label: 'Poisson', count: 3, color: Colors.red),
      StatisticEntry(id: 'd', label: 'Lapin', count: 0, color: Colors.amber),
    ];
    await tester.pumpWidget(
      chart(chartType: QuestionChartType.podium, entries: many),
    );
    await tester.pumpAndSettle();

    // Medal badges 1, 2, 3 (numbered, not emoji, for consistent rendering).
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Chien'), findsNWidgets(2), reason: 'podium + legend');
    expect(find.text('Lapin'), findsOneWidget, reason: 'legend only');
  });

  testWidgets('charts survive an empty result set', (tester) async {
    const empty = [
      StatisticEntry(id: 'a', label: 'Chat', count: 0, color: Colors.indigo),
      StatisticEntry(id: 'b', label: 'Chien', count: 0, color: Colors.teal),
    ];
    for (final type in QuestionChartType.values) {
      await tester.pumpWidget(chart(chartType: type, entries: empty));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: type.key);
      expect(find.text('0 %  0'), findsNWidgets(2), reason: type.key);
    }
  });
}
