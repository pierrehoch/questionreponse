import 'package:flutter/material.dart';
import 'package:question_reponse/app/theme/app_theme.dart';
import 'package:question_reponse/features/questions/domain/question_choice.dart';
import 'package:question_reponse/features/responses/domain/user_response.dart';

/// Choices are submitted as soon as they are tapped.
class ParticipationForm extends StatelessWidget {
  const ParticipationForm({
    required this.choices,
    required this.pendingId,
    required this.onSubmit,
    this.allowBlank = false,
    this.allowAbstention = false,
    super.key,
  });

  final List<QuestionChoice> choices;

  /// Optional answers, only shown when enabled on the question.
  final bool allowBlank;
  final bool allowAbstention;

  /// Choice id, or response type name for blank/abstention, being submitted.
  final String? pendingId;
  final ValueChanged<ResponseSubmission> onSubmit;

  @override
  Widget build(BuildContext context) {
    final isBusy = pendingId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, choice) in choices.indexed) ...[
          _ChoiceCard(
            label: choice.text,
            badge: String.fromCharCode(0x41 + index),
            color: AppTheme.choiceColor(index),
            selected: pendingId == choice.id,
            dimmed: isBusy && pendingId != choice.id,
            onTap: isBusy
                ? null
                : () => onSubmit(ResponseSubmission.choice(choice.id)),
          ),
          const SizedBox(height: 12),
        ],
        if (allowBlank || allowAbstention) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              if (allowBlank)
                Expanded(
                  child: _AlternativeButton(
                    label: 'Vote blanc',
                    icon: Icons.crop_square_rounded,
                    pending: pendingId == ResponseType.blank.name,
                    onPressed: isBusy
                        ? null
                        : () => onSubmit(const ResponseSubmission.blank()),
                  ),
                ),
              if (allowBlank && allowAbstention) const SizedBox(width: 12),
              if (allowAbstention)
                Expanded(
                  child: _AlternativeButton(
                    label: 'Abstention',
                    icon: Icons.do_not_disturb_on_outlined,
                    pending: pendingId == ResponseType.abstention.name,
                    onPressed: isBusy
                        ? null
                        : () => onSubmit(const ResponseSubmission.abstention()),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.label,
    required this.badge,
    required this.color,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  final String label;
  final String badge;
  final Color color;
  final bool selected;
  final bool dimmed;
  final VoidCallback? onTap;

  static const _duration = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final foreground = selected ? Colors.white : colorScheme.onSurface;

    return AnimatedOpacity(
      opacity: dimmed ? 0.35 : 1,
      duration: _duration,
      child: AnimatedScale(
        scale: selected ? 1.03 : 1,
        duration: _duration,
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: _duration,
          curve: Curves.easeOutCubic,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: selected ? color : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              splashColor: color.withValues(alpha: 0.2),
              highlightColor: color.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: _duration,
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.25)
                            : color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: AnimatedSwitcher(
                        duration: _duration,
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: selected
                            ? const Icon(
                                Icons.check_rounded,
                                key: ValueKey('check'),
                                color: Colors.white,
                              )
                            : Text(
                                badge,
                                key: const ValueKey('badge'),
                                style: textTheme.titleMedium?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: _duration,
                        style: textTheme.bodyLarge!.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w600,
                        ),
                        child: Text(label),
                      ),
                    ),
                    if (selected)
                      const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AlternativeButton extends StatelessWidget {
  const _AlternativeButton({
    required this.label,
    required this.icon,
    required this.pending,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool pending;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: pending
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
