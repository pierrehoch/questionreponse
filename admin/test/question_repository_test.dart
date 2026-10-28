import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:question_reponse_admin/question_options.dart';
import 'package:question_reponse_admin/question_repository.dart';
import 'package:question_shared/question_shared.dart';

void main() {
  final now = DateTime(2026, 1, 1, 12);

  test('accepts a complete draft question', () {
    final draft = QuestionDraft(
      text: 'Une question valide ?',
      infoText: null,
      choices: const ['Oui', 'Non'],
      status: AdminQuestionStatus.pending,
      scheduledAt: null,
    );

    expect(validateQuestionDraft(draft, now: now), isNull);
  });

  test('requires a future date for a scheduled question', () {
    final draft = QuestionDraft(
      text: 'Une question valide ?',
      infoText: null,
      choices: const ['Oui', 'Non'],
      status: AdminQuestionStatus.scheduled,
      scheduledAt: now,
    );

    expect(
      validateQuestionDraft(draft, now: now),
      'Choisissez une date de publication future.',
    );
  });

  test('rejects duplicate choices after trimming', () {
    final draft = QuestionDraft(
      text: 'Une question valide ?',
      infoText: null,
      choices: const ['Oui', ' Oui '],
      status: AdminQuestionStatus.pending,
      scheduledAt: null,
    );

    expect(
      validateQuestionDraft(draft, now: now),
      'Chaque choix doit être unique.',
    );
  });

  test('serialises optional answers, chart type and icon', () {
    final draft = QuestionDraft(
      text: 'Une question valide ?',
      infoText: ' ',
      choices: const ['Oui', 'Non'],
      status: AdminQuestionStatus.pending,
      scheduledAt: null,
      allowAbstention: true,
      chartType: QuestionChartType.podium,
      iconKey: 'vote',
    );

    final fields = draft.toFirestoreFields();

    expect(fields['infoText'], isNull);
    expect(fields['allowBlank'], isFalse);
    expect(fields['allowAbstention'], isTrue);
    expect(fields['chartType'], 'podium');
    expect(fields['icon'], 'vote');
  });

  test('defaults to no optional answers, donut chart and no icon', () {
    final draft = QuestionDraft(
      text: 'Une question valide ?',
      infoText: null,
      choices: const ['Oui', 'Non'],
      status: AdminQuestionStatus.pending,
      scheduledAt: null,
      iconKey: 'unknown_icon',
    );

    final fields = draft.toFirestoreFields();

    expect(fields['allowBlank'], isFalse);
    expect(fields['allowAbstention'], isFalse);
    expect(fields['chartType'], 'donut');
    expect(fields['icon'], isNull, reason: 'unknown keys are dropped');
  });

  testWidgets('pickers report the selected options', (tester) async {
    QuestionChartType? chartType;
    String? iconKey;
    bool? blankToggled;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                OptionalAnswersSection(
                  allowBlank: false,
                  allowAbstention: false,
                  onChanged: ({bool? allowBlank, bool? allowAbstention}) =>
                      blankToggled = allowBlank,
                ),
                ChartTypePicker(
                  selected: QuestionChartType.donut,
                  onChanged: (type) => chartType = type,
                ),
                QuestionIconPicker(
                  selectedKey: null,
                  onChanged: (key) => iconKey = key,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('allow-blank')));
    await tester.tap(find.byKey(const Key('chart-type-waffle')));
    await tester.ensureVisible(find.byKey(const Key('icon-vote')));
    await tester.tap(find.byKey(const Key('icon-vote')));

    expect(blankToggled, isTrue);
    expect(chartType, QuestionChartType.waffle);
    expect(iconKey, 'vote');
    expect(find.text('Ludique'), findsWidgets);
  });
}
