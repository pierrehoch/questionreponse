import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:question_reponse/app/app.dart';
import 'package:question_reponse/core/config/app_environment.dart';
import 'package:question_reponse/core/firebase/firebase_bootstrap.dart';
import 'package:question_reponse/features/auth/domain/auth_repository.dart';
import 'package:question_reponse/features/auth/domain/auth_user.dart';
import 'package:question_reponse/features/auth/presentation/controllers/auth_controller.dart';

void main() {
  testWidgets('validates sign-in fields before calling Firebase', (
    tester,
  ) async {
    final repository = RecordingAuthRepository();
    await _pumpApp(tester, repository);

    await tester.tap(find.text('Se connecter'));
    await tester.pump();

    expect(find.text('Saisissez votre adresse e-mail.'), findsOneWidget);
    expect(find.text('Saisissez votre mot de passe.'), findsOneWidget);
    expect(repository.signInCalls, 0);
  });

  testWidgets('submits valid sign-in credentials', (tester) async {
    final repository = RecordingAuthRepository();
    await _pumpApp(tester, repository);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Adresse e-mail'),
      'user@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mot de passe'),
      'password',
    );
    await tester.tap(find.text('Se connecter'));
    await tester.pump();

    expect(repository.signInCalls, 1);
    expect(repository.lastEmail, 'user@example.com');
  });
}

Future<void> _pumpApp(
  WidgetTester tester,
  RecordingAuthRepository repository,
) async {
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
}

class RecordingAuthRepository implements AuthRepository {
  final _controller = StreamController<AuthUser?>.broadcast();
  var signInCalls = 0;
  String? lastEmail;

  void emit(AuthUser? user) => _controller.add(user);

  @override
  Stream<AuthUser?> authStateChanges() => _controller.stream;

  @override
  Future<void> signIn({required String email, required String password}) async {
    signInCalls++;
    lastEmail = email;
  }

  @override
  Future<void> register({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> signOut() async {}
}
