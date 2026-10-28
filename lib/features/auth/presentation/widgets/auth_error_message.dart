import 'package:flutter/material.dart';
import 'package:question_reponse/features/auth/domain/auth_failure.dart';

class AuthErrorMessage extends StatelessWidget {
  const AuthErrorMessage({required this.error, super.key});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final message = error is AuthFailure
        ? (error as AuthFailure).message
        : 'Une erreur inattendue est survenue.';

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
      ),
    );
  }
}
