import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:question_reponse/app/widgets/loading_button.dart';
import 'package:question_reponse/app/widgets/notice_banner.dart';
import 'package:question_reponse/features/auth/presentation/auth_validators.dart';
import 'package:question_reponse/features/auth/presentation/controllers/auth_controller.dart';
import 'package:question_reponse/features/auth/presentation/widgets/auth_error_message.dart';
import 'package:question_reponse/features/auth/presentation/widgets/auth_page_scaffold.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  static const routePath = '/mot-de-passe-oublie';

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  var _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(authControllerProvider);

    return AuthPageScaffold(
      title: 'Mot de passe oublié',
      subtitle:
          'Saisissez votre adresse e-mail, nous vous enverrons un lien '
          'pour choisir un nouveau mot de passe.',
      footer: AuthFooterLink(
        prompt: 'Vous vous en souvenez ?',
        action: 'Retour à la connexion',
        onPressed: action.isLoading ? null : () => Navigator.of(context).pop(),
      ),
      child: Form(
        key: _formKey,
        onChanged: () {
          ref.read(authControllerProvider.notifier).clearError();
          if (_emailSent) {
            setState(() => _emailSent = false);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              enabled: !action.isLoading,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Adresse e-mail',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: validateEmail,
              onFieldSubmitted: (_) => _submit(),
            ),
            if (action case AsyncError(:final error)) ...[
              const SizedBox(height: 16),
              AuthErrorMessage(error: error),
            ],
            if (_emailSent) ...[
              const SizedBox(height: 16),
              const NoticeBanner(
                tone: NoticeTone.success,
                icon: Icons.mark_email_read_outlined,
                message:
                    'Si un compte correspond à cette adresse, un e-mail vient '
                    'd’être envoyé.',
              ),
            ],
            const SizedBox(height: 24),
            LoadingButton(
              label: 'Envoyer le lien',
              loading: action.isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final succeeded = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordResetEmail(_emailController.text);
    if (succeeded && mounted) {
      setState(() => _emailSent = true);
    }
  }
}
