import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:question_shared/question_shared.dart';

void main() {
  test('chart type keys are unique and resolve back to their type', () {
    final keys = QuestionChartType.values.map((type) => type.key).toSet();
    expect(keys.length, QuestionChartType.values.length);
    for (final type in QuestionChartType.values) {
      expect(QuestionChartType.fromKey(type.key), type);
    }
  });

  test('unknown chart types fall back to the donut', () {
    expect(QuestionChartType.fromKey(null), QuestionChartType.donut);
    expect(QuestionChartType.fromKey('spiral'), QuestionChartType.donut);
  });

  test('icon keys are unique and every category has icons', () {
    final keys = QuestionIcons.all.map((icon) => icon.key).toSet();
    expect(keys.length, QuestionIcons.all.length);
    expect(QuestionIcons.byKey('vote')?.icon, Icons.how_to_vote_rounded);
    expect(QuestionIcons.byKey('unknown'), isNull);
    expect(QuestionIcons.byKey(null), isNull);
    for (final category in QuestionIconCategory.values) {
      expect(QuestionIcons.inCategory(category), isNotEmpty);
    }
  });

  testWidgets('every chart type has a thumbnail that paints', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Wrap(
          children: [
            for (final type in QuestionChartType.values)
              SizedBox.square(
                dimension: 64,
                child: ChartTypeThumbnail(type: type),
              ),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      find.byType(ChartTypeThumbnail),
      findsNWidgets(QuestionChartType.values.length),
    );
  });
}
