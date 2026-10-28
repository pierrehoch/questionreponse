import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:question_reponse/app/router/app_router.dart';
import 'package:question_reponse/app/theme/app_theme.dart';
import 'package:question_reponse/core/config/app_environment.dart';
import 'package:question_reponse/core/firebase/firebase_bootstrap.dart';

class QuestionReponseApp extends ConsumerWidget {
  const QuestionReponseApp({
    required this.environment,
    required this.bootstrap,
    super.key,
  });

  final AppEnvironment environment;
  final FirebaseBootstrapResult bootstrap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (bootstrap case FirebaseBootstrapFailure(:final message)) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: _ConfigurationErrorPage(message: message),
      );
    }

    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Question Réponse',
      debugShowCheckedModeBanner: environment.isDevelopment,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
    );
  }
}

class _ConfigurationErrorPage extends StatelessWidget {
  const _ConfigurationErrorPage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 56,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Configuration Firebase requise',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(message, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
