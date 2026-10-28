import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:question_reponse/features/auth/presentation/auth_validators.dart';
import 'package:question_reponse/features/auth/presentation/controllers/auth_controller.dart';
import 'package:question_reponse/features/auth/presentation/widgets/auth_error_message.dart';
import 'package:question_reponse/features/auth/presentation/widgets/auth_page_scaffold.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  static const routePath = '/inscription';

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  var _passwordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(authControllerProvider);

    return AuthPageScaffold(
      title: 'Créer un compte',
      subtitle: 'Votre compte est nécessaire pour participer.',
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
              autofillHints: const [AutofillHints.newUsername],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Adresse e-mail',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: validateEmail,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              enabled: !action.isLoading,
              obscureText: !_passwordVisible,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                helperText: '6 caractères minimum',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _passwordVisible = !_passwordVisible),
                  icon: Icon(
                    _passwordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  tooltip: _passwordVisible
                      ? 'Masquer le mot de passe'
                      : 'Afficher le mot de passe',
                ),
              ),
              validator: (value) => (value?.length ?? 0) < 6
                  ? 'Utilisez au moins 6 caractères.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmationController,
              enabled: !action.isLoading,
              obscureText: !_passwordVisible,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Confirmer le mot de passe',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (value) => value != _passwordController.text
                  ? 'Les mots de passe ne correspondent pas.'
                  : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            if (action case AsyncError(:final error)) ...[
              const SizedBox(height: 16),
              AuthErrorMessage(error: error),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: action.isLoading ? null : _submit,
              child: action.isLoading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Créer mon compte'),
            ),
            TextButton(
              onPressed: action.isLoading
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('J’ai déjà un compte'),
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
        .register(
          email: _emailController.text,
          password: _passwordController.text,
        );
  }
}
