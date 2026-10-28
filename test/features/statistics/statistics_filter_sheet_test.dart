import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:question_reponse/features/statistics/domain/statistics_filter.dart';
import 'package:question_reponse/features/statistics/presentation/widgets/statistics_filter_sheet.dart';

void main() {
  /// Opens the sheet; [results] receives the value once it closes.
  Future<void> open(
    WidgetTester tester,
    List<StatisticsFilter?> results, {
    StatisticsFilter? initialFilter,
    String? userCountry,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async => results.add(
                await showStatisticsFilterSheet(
                  context,
                  initialFilter: initialFilter,
                  userCountry: userCountry,
                ),
              ),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('applies sex and the profile country shortcut', (tester) async {
    final results = <StatisticsFilter?>[];
    await open(tester, results, userCountry: 'FR');

    expect(find.text('Tous les pays'), findsOneWidget);
    await tester.tap(find.text('Femme'));
    await tester.tap(find.textContaining('Mon pays'));
    await tester.pumpAndSettle();

    expect(find.text('France'), findsOneWidget);
    expect(find.textContaining('Mon pays'), findsNothing);

    await tester.tap(find.text('Appliquer'));
    await tester.pumpAndSettle();

    expect(results, hasLength(1));
    expect(results.single?.country, 'FR');
    expect(results.single?.sex, 'female');
  });

  testWidgets('resets to an empty filter', (tester) async {
    final results = <StatisticsFilter?>[];
    await open(
      tester,
      results,
      initialFilter: StatisticsFilter(country: 'BE', sex: 'male'),
    );

    expect(find.text('Belgique'), findsOneWidget);
    await tester.tap(find.text('Réinitialiser'));
    await tester.pumpAndSettle();

    expect(results.single, isNotNull);
    expect(results.single!.isEmpty, isTrue);
  });

  testWidgets('picks a country from the list', (tester) async {
    final results = <StatisticsFilter?>[];
    await open(tester, results);

    await tester.tap(find.text('Tous les pays'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'canad');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Canada'));
    await tester.pumpAndSettle();

    expect(find.text('Canada'), findsOneWidget);

    await tester.tap(find.text('Appliquer'));
    await tester.pumpAndSettle();

    expect(results.single?.country, 'CA');
    expect(results.single?.sex, isNull);
  });
}
