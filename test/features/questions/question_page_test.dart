import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:question_reponse/features/auth/domain/auth_repository.dart';
import 'package:question_reponse/features/auth/domain/auth_user.dart';
import 'package:question_reponse/features/auth/presentation/controllers/auth_controller.dart';
import 'package:question_reponse/features/questions/domain/question.dart';
import 'package:question_reponse/features/questions/domain/question_choice.dart';
import 'package:question_reponse/features/questions/domain/question_repository.dart';
import 'package:question_reponse/features/questions/presentation/controllers/question_providers.dart';
import 'package:question_reponse/features/questions/presentation/question_history_page.dart';
import 'package:question_reponse/features/questions/presentation/question_page.dart';
import 'package:question_reponse/features/responses/domain/response_failure.dart';
import 'package:question_reponse/features/responses/domain/response_repository.dart';
import 'package:question_reponse/features/responses/domain/user_response.dart';
import 'package:question_reponse/features/responses/presentation/controllers/response_controller.dart';
import 'package:question_reponse/features/statistics/domain/question_statistics.dart';
import 'package:question_reponse/features/statistics/domain/statistics_repository.dart';
import 'package:question_reponse/features/statistics/domain/statistics_filter.dart';
import 'package:question_reponse/features/statistics/presentation/controllers/statistics_providers.dart';
import 'package:question_shared/question_shared.dart';

void main() {
  final question = Question(
    id: 'question-1',
    text: 'Quel langage préférez-vous ?',
    infoText: 'Choisissez une seule réponse.',
    status: QuestionStatus.published,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    publishedAt: DateTime(2026),
    createdBy: 'admin-1',
    iconKey: 'vote',
  );
  final openQuestion = Question(
    id: 'question-2',
    text: 'Faut-il autoriser le vote blanc ?',
    status: QuestionStatus.published,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    publishedAt: DateTime(2026),
    createdBy: 'admin-1',
    allowBlank: true,
    allowAbstention: true,
    chartType: QuestionChartType.versus,
  );

  testWidgets('shows the empty published-question state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_NoopAuthRepository()),
          questionRepositoryProvider.overrideWithValue(
            _QuestionTestRepository(questions: const []),
          ),
        ],
        child: const MaterialApp(home: QuestionPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Aucune question publiée pour le moment.'),
      findsOneWidget,
    );
  });

  testWidgets('shows published questions and their ordered choices', (
    tester,
  ) async {
    final repository = _QuestionTestRepository(
      questions: [question],
      question: question,
      choices: const [
        QuestionChoice(id: 'python', text: 'Python', position: 0),
        QuestionChoice(id: 'dart', text: 'Dart', position: 1),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_NoopAuthRepository()),
          questionRepositoryProvider.overrideWithValue(repository),
          responseRepositoryProvider.overrideWithValue(
            _NoopResponseRepository(),
          ),
        ],
        child: MaterialApp(home: QuestionPage(questionId: question.id)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(question.text), findsOneWidget);
    expect(find.text('Python'), findsOneWidget);
    expect(find.text('Dart'), findsOneWidget);
    expect(find.byIcon(QuestionIcons.byKey('vote')!.icon), findsOneWidget);
    expect(find.textContaining('Publiée le'), findsOneWidget);
    expect(find.byTooltip('Informations'), findsOneWidget);
    expect(find.text('Vote blanc'), findsNothing);
    expect(find.text('Abstention'), findsNothing);
  });

  testWidgets('offers blank vote and abstention only when enabled', (
    tester,
  ) async {
    final repository = _QuestionTestRepository(
      questions: [openQuestion],
      question: openQuestion,
      choices: const [
        QuestionChoice(id: 'yes', text: 'Oui', position: 0),
        QuestionChoice(id: 'no', text: 'Non', position: 1),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_NoopAuthRepository()),
          questionRepositoryProvider.overrideWithValue(repository),
          responseRepositoryProvider.overrideWithValue(
            _NoopResponseRepository(),
          ),
        ],
        child: MaterialApp(home: QuestionPage(questionId: openQuestion.id)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vote blanc'), findsOneWidget);
    expect(find.text('Abstention'), findsOneWidget);
    expect(find.byTooltip('Informations'), findsNothing);
  });

  testWidgets('shows the latest published question on the home page', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_NoopAuthRepository()),
          questionRepositoryProvider.overrideWithValue(
            _QuestionTestRepository(questions: [question], question: question),
          ),
          responseRepositoryProvider.overrideWithValue(
            _NoopResponseRepository(),
          ),
        ],
        child: const MaterialApp(home: QuestionPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(question.text), findsOneWidget);
    expect(find.byTooltip('Questions précédentes'), findsOneWidget);
    expect(find.byTooltip('Mon profil'), findsOneWidget);
  });

  testWidgets('distinguishes answered questions in the history', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_SignedInAuthRepository()),
          questionRepositoryProvider.overrideWithValue(
            _QuestionTestRepository(questions: [question]),
          ),
          responseRepositoryProvider.overrideWithValue(
            _NoopResponseRepository(
              responses: [
                UserResponse(
                  questionId: question.id,
                  type: ResponseType.blank,
                  country: 'FR',
                  sex: 'other',
                  createdAt: DateTime(2026),
                ),
              ],
            ),
          ),
        ],
        child: const MaterialApp(home: QuestionHistoryPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(question.text), findsOneWidget);
    expect(find.textContaining('Répondu'), findsOneWidget);
    expect(find.textContaining('À répondre'), findsNothing);
    expect(
      find.text('Vous avez répondu à toutes les questions'),
      findsOneWidget,
    );
    expect(find.text('1 / 1'), findsOneWidget);
  });

  testWidgets('shows results from the submission without waiting for streams', (
    tester,
  ) async {
    final statistics = QuestionStatistics(
      totalResponses: 3,
      choiceCounts: const {'python': 2, 'dart': 1},
      blankCount: 0,
      abstentionCount: 0,
      updatedAt: DateTime(2026),
    );
    final repository = _QuestionTestRepository(
      questions: [question],
      question: question,
      choices: const [
        QuestionChoice(id: 'python', text: 'Python', position: 0),
        QuestionChoice(id: 'dart', text: 'Dart', position: 1),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_SignedInAuthRepository()),
          questionRepositoryProvider.overrideWithValue(repository),
          responseRepositoryProvider.overrideWithValue(
            _NoopResponseRepository(
              submitResult: SubmitResult(
                response: UserResponse(
                  questionId: question.id,
                  type: ResponseType.choice,
                  choiceId: 'python',
                  country: 'FR',
                  sex: 'other',
                  createdAt: DateTime(2026),
                ),
                statistics: statistics,
              ),
            ),
          ),
          statisticsRepositoryProvider.overrideWithValue(
            _SilentStatisticsRepository(),
          ),
        ],
        child: MaterialApp(home: QuestionPage(questionId: question.id)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Python'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Résultats'), findsOneWidget);
    expect(find.text('Vote blanc'), findsNothing);
    expect(find.text('Abstention'), findsNothing);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('67 %  2'), findsOneWidget);
    expect(find.text('33 %  1'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('restores the form when the submission fails', (tester) async {
    final repository = _QuestionTestRepository(
      questions: [question],
      question: question,
      choices: const [
        QuestionChoice(id: 'python', text: 'Python', position: 0),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_SignedInAuthRepository()),
          questionRepositoryProvider.overrideWithValue(repository),
          responseRepositoryProvider.overrideWithValue(
            _NoopResponseRepository(),
          ),
        ],
        child: MaterialApp(home: QuestionPage(questionId: question.id)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Python'));
    await tester.pumpAndSettle();

    expect(find.text('Indisponible.'), findsOneWidget);
    expect(find.text('Résultats'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}

class _SilentStatisticsRepository implements StatisticsRepository {
  final _summaries = StreamController<QuestionStatistics?>();

  @override
  Stream<QuestionStatistics?> watchSummary(String questionId) =>
      _summaries.stream;

  @override
  Future<QuestionStatistics> getFiltered({
    required String questionId,
    required StatisticsFilter filter,
  }) => Completer<QuestionStatistics>().future;
}

class _SignedInAuthRepository extends _NoopAuthRepository {
  @override
  Stream<AuthUser?> authStateChanges() =>
      Stream.value(const AuthUser(id: 'user-1', email: 'user@example.com'));
}

class _NoopResponseRepository implements ResponseRepository {
  _NoopResponseRepository({this.responses = const [], this.submitResult});

  final List<UserResponse> responses;

  /// Returned by [submit]; the persisted response stream never emits it, so
  /// results must be displayed from this value alone.
  final SubmitResult? submitResult;

  @override
  Stream<List<UserResponse>> watchResponses(String userId) =>
      Stream.value(responses);

  @override
  Future<SubmitResult> submit({
    required String questionId,
    required ResponseSubmission submission,
  }) async {
    return submitResult ?? (throw const ResponseFailure('Indisponible.'));
  }

  @override
  Stream<UserResponse?> watchResponse({
    required String userId,
    required String questionId,
  }) => Stream.value(null);
}

class _QuestionTestRepository implements QuestionRepository {
  _QuestionTestRepository({
    required this.questions,
    this.question,
    this.choices = const [],
  });

  final List<Question> questions;
  final Question? question;
  final List<QuestionChoice> choices;

  @override
  Stream<List<QuestionChoice>> watchChoices(String questionId) =>
      Stream.value(choices);

  @override
  Stream<List<Question>> watchPublishedQuestions() => Stream.value(questions);

  @override
  Stream<Question?> watchLatestPublishedQuestion() =>
      Stream.value(questions.firstOrNull);

  @override
  Stream<Question?> watchQuestion(String questionId) => Stream.value(question);
}

class _NoopAuthRepository implements AuthRepository {
  @override
  Stream<AuthUser?> authStateChanges() => Stream.value(null);

  @override
  Future<void> register({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {}
}
