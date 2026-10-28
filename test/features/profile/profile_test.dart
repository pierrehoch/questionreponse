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

void main() {
  test('normalizes usernames for uniqueness', () {
    expect(normalizeUsername('  Alex_75 '), 'alex_75');
  });

  testWidgets('requires profile completion for a new authenticated user', (
    tester,
  ) async {
    final authRepository = ProfileTestAuthRepository();
    final profileRepository = RecordingProfileRepository();
    authRepository.emit(
      const AuthUser(id: 'user-1', email: 'user@example.com'),
    );
    profileRepository.emit(null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          profileRepositoryProvider.overrideWithValue(profileRepository),
        ],
        child: const QuestionReponseApp(
          environment: AppEnvironment.development,
          bootstrap: FirebaseBootstrapReady(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Compléter mon profil'), findsOneWidget);

    final submitButton = find.text('Créer mon profil');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pump();

    expect(
      find.text('Utilisez entre 3 et 24 caractères autorisés.'),
      findsOneWidget,
    );
    expect(find.text('Sélectionnez votre pays dans la liste.'), findsOneWidget);
    expect(find.text('Sélectionnez une valeur.'), findsOneWidget);
    expect(profileRepository.saveCalls, 0);
  });
}

class ProfileTestAuthRepository implements AuthRepository {
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

class RecordingProfileRepository implements ProfileRepository {
  final _controller = StreamController<UserProfile?>.broadcast();
  UserProfile? _currentProfile;
  var saveCalls = 0;

  void emit(UserProfile? profile) {
    _currentProfile = profile;
    _controller.add(profile);
  }

  @override
  Future<void> saveProfile({
    required String userId,
    required String email,
    required ProfileInput input,
  }) async {
    saveCalls++;
  }

  @override
  Stream<UserProfile?> watchProfile(String userId) async* {
    yield _currentProfile;
    yield* _controller.stream;
  }
}
