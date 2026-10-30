import 'package:flutter/material.dart';

/// Primary action that keeps its color and shows a spinner while [loading].
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: loading
          ? FilledButton.styleFrom(
              disabledBackgroundColor: colorScheme.primary,
              disabledForegroundColor: colorScheme.onPrimary,
            )
          : null,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: loading
            ? SizedBox.square(
                key: const ValueKey('loading'),
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: colorScheme.onPrimary,
                ),
              )
            : Text(label, key: const ValueKey('label')),
      ),
    );
  }
}
