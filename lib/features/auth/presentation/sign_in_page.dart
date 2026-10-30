import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:question_reponse/app/widgets/loading_button.dart';
import 'package:question_reponse/features/auth/presentation/auth_validators.dart';
import 'package:question_reponse/features/auth/presentation/controllers/auth_controller.dart';
import 'package:question_reponse/features/auth/presentation/register_page.dart';
import 'package:question_reponse/features/auth/presentation/reset_password_page.dart';
import 'package:question_reponse/features/auth/presentation/widgets/auth_error_message.dart';
import 'package:question_reponse/features/auth/presentation/widgets/auth_page_scaffold.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  static const routePath = '/connexion';

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _passwordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(authControllerProvider);

    return AuthPageScaffold(
      title: 'Bon retour',
      subtitle: 'Connectez-vous pour répondre aux questions.',
      footer: AuthFooterLink(
        prompt: 'Pas encore de compte ?',
        action: 'Créer un compte',
        onPressed: action.isLoading
            ? null
            : () {
                ref.read(authControllerProvider.notifier).clearError();
                context.push(RegisterPage.routePath);
              },
      ),
      child: Form(
        key: _formKey,
        onChanged: ref.read(authControllerProvider.notifier).clearError,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              enabled: !action.isLoading,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Adresse e-mail',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: validateEmail,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              enabled: !action.isLoading,
              obscureText: !_passwordVisible,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _passwordVisible = !_passwordVisible),
                  icon: Icon(
                    _passwordVisible
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                  tooltip: _passwordVisible
                      ? 'Masquer le mot de passe'
                      : 'Afficher le mot de passe',
                ),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Saisissez votre mot de passe.'
                  : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: action.isLoading
                    ? null
                    : () {
                        ref.read(authControllerProvider.notifier).clearError();
                        context.push(ResetPasswordPage.routePath);
                      },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 44),
                ),
                child: const Text('Mot de passe oublié ?'),
              ),
            ),
            if (action case AsyncError(:final error)) ...[
              const SizedBox(height: 8),
              AuthErrorMessage(error: error),
            ],
            const SizedBox(height: 16),
            LoadingButton(
              label: 'Se connecter',
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

    await ref
        .read(authControllerProvider.notifier)
        .signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
  }
}
