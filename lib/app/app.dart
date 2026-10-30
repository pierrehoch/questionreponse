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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.cloud_off_rounded,
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Configuration Firebase requise',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: SelectableText(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
