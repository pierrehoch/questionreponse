import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:question_reponse/features/auth/domain/auth_user.dart';
import 'package:question_reponse/features/auth/presentation/controllers/auth_controller.dart';
import 'package:question_reponse/features/comments/domain/comment.dart';
import 'package:question_reponse/features/comments/domain/comment_repository.dart';
import 'package:question_reponse/features/comments/presentation/controllers/comment_providers.dart';
import 'package:question_reponse/features/comments/presentation/widgets/comments_section.dart';
import 'package:question_reponse/features/profile/domain/user_profile.dart';
import 'package:question_reponse/features/profile/presentation/controllers/profile_controller.dart';
import 'package:question_reponse/features/questions/domain/question_choice.dart';
import 'package:question_reponse/features/responses/domain/user_response.dart';

void main() {
  const choices = [
    QuestionChoice(id: 'a', text: 'Oui', position: 0),
    QuestionChoice(id: 'b', text: 'Non', position: 1),
  ];
  final response = UserResponse(
    questionId: 'q1',
    type: ResponseType.choice,
    choiceId: 'b',
    country: 'FR',
    sex: 'other',
    createdAt: DateTime(2026),
  );

  Future<_FakeCommentRepository> pump(
    WidgetTester tester,
    List<Comment> initial,
  ) async {
    final repository = _FakeCommentRepository(initial);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          commentRepositoryProvider.overrideWithValue(repository),
          authStateProvider.overrideWith(
            (ref) => Stream.value(
              const AuthUser(id: 'user-1', email: 'user@example.com'),
            ),
          ),
          profileProvider.overrideWith(
            (ref) => Stream.value(
              UserProfile(
                id: 'user-1',
                username: 'moi',
                normalizedUsername: 'moi',
                email: 'user@example.com',
                country: 'FR',
                sex: UserSex.other,
                createdAt: DateTime(2026),
                updatedAt: DateTime(2026),
              ),
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CommentsSection(
                questionId: 'q1',
                choices: choices,
                response: response,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return repository;
  }

  testWidgets('shows an empty state then publishes a comment', (tester) async {
    final repository = await pump(tester, []);

    expect(find.textContaining('Aucun commentaire'), findsOneWidget);
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).onPressed,
      isNull,
    );

    await tester.enterText(find.byType(TextField), '  Bonne question  ');
    await tester.pump();
    await tester.tap(find.byTooltip('Publier'));
    await tester.pump();
    await tester.pump();

    expect(repository.added.single.text, 'Bonne question');
    expect(repository.added.single.vote, 'b');
    expect(repository.added.single.username, 'moi');
    expect(find.text('Bonne question'), findsOneWidget);
    expect(find.text('Vote B'), findsOneWidget);
  });

  testWidgets('lets authors delete only their own comments', (tester) async {
    final repository = await pump(tester, [
      Comment(
        id: 'c1',
        userId: 'user-1',
        username: 'moi',
        vote: 'b',
        text: 'Mon avis',
        createdAt: DateTime.now(),
      ),
      Comment(
        id: 'c2',
        userId: 'user-2',
        username: 'autre',
        vote: 'a',
        text: 'Son avis',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ]);

    expect(find.text('Vote A'), findsOneWidget);
    expect(find.text('il y a 3 h'), findsOneWidget);
    expect(find.byTooltip('Supprimer mon commentaire'), findsOneWidget);

    await tester.tap(find.byTooltip('Supprimer mon commentaire'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();

    expect(repository.deleted, ['c1']);
    expect(find.text('Mon avis'), findsNothing);
    expect(find.text('Son avis'), findsOneWidget);
  });

  test('formats comment ages in French', () {
    final now = DateTime(2026, 5, 20, 12);
    expect(formatCommentAge(null, now), 'à l’instant');
    expect(
      formatCommentAge(now.subtract(const Duration(minutes: 5)), now),
      'il y a 5 min',
    );
    expect(
      formatCommentAge(now.subtract(const Duration(days: 2)), now),
      'il y a 2 j',
    );
    expect(formatCommentAge(DateTime(2026, 1, 3), now), '03/01/2026');
  });
}

class _FakeCommentRepository implements CommentRepository {
  _FakeCommentRepository(this._comments);

  final List<Comment> _comments;
  final added = <Comment>[];
  final deleted = <String>[];
  final _changes = StreamController<void>.broadcast();

  @override
  Stream<List<Comment>> watchComments(String questionId, {required int limit}) {
    late StreamController<List<Comment>> controller;
    StreamSubscription<void>? subscription;
    controller = StreamController<List<Comment>>(
      onListen: () {
        controller.add(List.of(_comments));
        subscription = _changes.stream.listen(
          (_) => controller.add(List.of(_comments)),
        );
      },
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream;
  }

  @override
  Future<void> add({
    required String questionId,
    required String userId,
    required String username,
    required String vote,
    required String text,
  }) async {
    final comment = Comment(
      id: 'new-${added.length}',
      userId: userId,
      username: username,
      vote: vote,
      text: text,
      createdAt: null,
    );
    added.add(comment);
    _comments.insert(0, comment);
    _changes.add(null);
  }

  @override
  Future<void> delete({
    required String questionId,
    required String commentId,
  }) async {
    deleted.add(commentId);
    _comments.removeWhere((comment) => comment.id == commentId);
    _changes.add(null);
  }
}
