import 'package:flutter/material.dart';
import 'package:question_reponse/app/widgets/notice_banner.dart';
import 'package:question_reponse/features/auth/domain/auth_failure.dart';

class AuthErrorMessage extends StatelessWidget {
  const AuthErrorMessage({required this.error, super.key});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final message = error is AuthFailure
        ? (error as AuthFailure).message
        : 'Une erreur inattendue est survenue.';

    return NoticeBanner(message: message);
  }
}
