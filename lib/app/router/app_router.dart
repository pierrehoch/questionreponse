import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:question_reponse/features/auth/presentation/auth_loading_page.dart';
import 'package:question_reponse/features/auth/presentation/controllers/auth_controller.dart';
import 'package:question_reponse/features/auth/presentation/register_page.dart';
import 'package:question_reponse/features/auth/presentation/reset_password_page.dart';
import 'package:question_reponse/features/auth/presentation/sign_in_page.dart';
import 'package:question_reponse/features/profile/presentation/controllers/profile_controller.dart';
import 'package:question_reponse/features/profile/presentation/profile_page.dart';
import 'package:question_reponse/features/questions/presentation/question_history_page.dart';
import 'package:question_reponse/features/questions/presentation/question_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final profileState = ref.watch(profileProvider);
  final router = GoRouter(
    initialLocation: AuthLoadingPage.routePath,
    redirect: (context, state) {
      final path = state.matchedLocation;
      final isAuthRoute =
          path == SignInPage.routePath ||
          path == RegisterPage.routePath ||
          path == ResetPasswordPage.routePath;

      if (authState.isLoading) {
        return path == AuthLoadingPage.routePath
            ? null
            : AuthLoadingPage.routePath;
      }

      final user = authState.value;
      if (user == null) {
        return isAuthRoute ? null : SignInPage.routePath;
      }

      if (profileState.isLoading) {
        return path == AuthLoadingPage.routePath
            ? null
            : AuthLoadingPage.routePath;
      }

      if (profileState.value == null) {
        return path == ProfilePage.routePath ? null : ProfilePage.routePath;
      }

      return isAuthRoute || path == AuthLoadingPage.routePath
          ? QuestionPage.homePath
          : null;
    },
    routes: [
      GoRoute(
        path: AuthLoadingPage.routePath,
        builder: (context, state) => const AuthLoadingPage(),
      ),
      GoRoute(
        path: SignInPage.routePath,
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: RegisterPage.routePath,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: ResetPasswordPage.routePath,
        builder: (context, state) => const ResetPasswordPage(),
      ),
      GoRoute(
        path: ProfilePage.routePath,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: QuestionPage.homePath,
        builder: (context, state) => const QuestionPage(),
      ),
      GoRoute(
        path: QuestionHistoryPage.routePath,
        builder: (context, state) => const QuestionHistoryPage(),
      ),
      GoRoute(
        path: QuestionPage.routePath,
        builder: (context, state) =>
            QuestionPage(questionId: state.pathParameters['questionId']!),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
