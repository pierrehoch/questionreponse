import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:question_reponse/app/app.dart';
import 'package:question_reponse/core/config/app_environment.dart';
import 'package:question_reponse/core/firebase/firebase_bootstrap.dart';
import 'package:question_reponse/features/auth/domain/auth_repository.dart';
import 'package:question_reponse/features/auth/domain/auth_user.dart';
import 'package:question_reponse/features/auth/presentation/controllers/auth_controller.dart';
import 'package:question_reponse/features/profile/domain/profile_repository.dart';
import 'package:question_reponse/features/profile/domain/user_profile.dart';
import 'package:question_reponse/features/profile/presentation/controllers/profile_controller.dart';
import 'package:question_reponse/features/questions/domain/question.dart';
import 'package:question_reponse/features/questions/domain/question_choice.dart';
import 'package:question_reponse/features/questions/domain/question_repository.dart';
import 'package:question_reponse/features/questions/presentation/controllers/question_providers.dart';

void main() {
  testWidgets('shows a configuration error when Firebase is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: QuestionReponseApp(
          environment: AppEnvironment.development,
          bootstrap: FirebaseBootstrapFailure('Configuration absente'),
        ),
      ),
    );

    expect(find.text('Configuration Firebase requise'), findsOneWidget);
    expect(find.text('Configuration absente'), findsOneWidget);
  });

  testWidgets('redirects signed-out users to sign in', (tester) async {
    final repository = FakeAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const QuestionReponseApp(
          environment: AppEnvironment.development,
          bootstrap: FirebaseBootstrapReady(),
        ),
      ),
    );
    repository.emit(null);
    await tester.pumpAndSettle();

    expect(find.text('Bon retour'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });

  testWidgets('redirects signed-in users to the latest question', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    final profileRepository = FakeProfileRepository();
    repository.emit(const AuthUser(id: 'user-1', email: 'user@example.com'));
    profileRepository.emit(
      UserProfile(
        id: 'user-1',
        username: 'user_1',
        normalizedUsername: 'user_1',
        email: 'user@example.com',
        country: 'FR',
        sex: UserSex.other,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          profileRepositoryProvider.overrideWithValue(profileRepository),
          questionRepositoryProvider.overrideWithValue(
            FakeQuestionRepository(),
          ),
        ],
        child: const QuestionReponseApp(
          environment: AppEnvironment.development,
          bootstrap: FirebaseBootstrapReady(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Aucune question publiée pour le moment.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Mon profil'), findsOneWidget);
    expect(find.byTooltip('Questions précédentes'), findsOneWidget);
  });
}

class FakeQuestionRepository implements QuestionRepository {
  @override
  Stream<List<QuestionChoice>> watchChoices(String questionId) =>
      Stream.value([]);

  @override
  Stream<List<Question>> watchPublishedQuestions() => Stream.value([]);

  @override
  Stream<Question?> watchLatestPublishedQuestion() => Stream.value(null);

  @override
  Stream<Question?> watchQuestion(String questionId) => Stream.value(null);
}

class FakeProfileRepository implements ProfileRepository {
  final _controller = StreamController<UserProfile?>.broadcast();
  UserProfile? _currentProfile;

  void emit(UserProfile? profile) {
    _currentProfile = profile;
    _controller.add(profile);
  }

  @override
  Future<void> saveProfile({
    required String userId,
    required String email,
    required ProfileInput input,
  }) async {}

  @override
  Stream<UserProfile?> watchProfile(String userId) async* {
    yield _currentProfile;
    yield* _controller.stream;
  }
}

class FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _currentUser;

  void emit(AuthUser? user) {
    _currentUser = user;
    _controller.add(user);
  }

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

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
