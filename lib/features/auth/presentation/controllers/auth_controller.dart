import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:question_reponse/features/auth/data/firebase_auth_repository.dart';
import 'package:question_reponse/features/auth/domain/auth_repository.dart';
import 'package:question_reponse/features/auth/domain/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(FirebaseAuth.instance),
);

final authStateProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);

class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> signIn({required String email, required String password}) {
    return _run(
      () => ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password),
    );
  }

  Future<bool> register({required String email, required String password}) {
    return _run(
      () => ref
          .read(authRepositoryProvider)
          .register(email: email, password: password),
    );
  }

  Future<bool> sendPasswordResetEmail(String email) {
    return _run(
      () => ref.read(authRepositoryProvider).sendPasswordResetEmail(email),
    );
  }

  Future<bool> signOut() {
    return _run(() => ref.read(authRepositoryProvider).signOut());
  }

  void clearError() {
    if (state.hasError) {
      state = const AsyncData(null);
    }
  }

  Future<bool> _run(Future<void> Function() operation) async {
    state = const AsyncLoading();

    try {
      await operation();
      state = const AsyncData(null);
      return true;
    } on Object catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}
