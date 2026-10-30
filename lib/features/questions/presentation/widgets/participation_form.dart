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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.touch_app_outlined,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Touchez une réponse pour voter. Votre choix est définitif.',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
          const SizedBox(height: 10),
        ],
        if (allowBlank || allowAbstention) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              if (allowBlank)
                Expanded(
                  child: _AlternativeButton(
                    label: 'Vote blanc',
                    icon: Icons.crop_square_rounded,
                    pending: pendingId == ResponseType.blank.name,
                    dimmed: isBusy && pendingId != ResponseType.blank.name,
                    onPressed: isBusy
                        ? null
                        : () => onSubmit(const ResponseSubmission.blank()),
                  ),
                ),
              if (allowBlank && allowAbstention) const SizedBox(width: 10),
              if (allowAbstention)
                Expanded(
                  child: _AlternativeButton(
                    label: 'Abstention',
                    icon: Icons.do_not_disturb_on_outlined,
                    pending: pendingId == ResponseType.abstention.name,
                    dimmed: isBusy && pendingId != ResponseType.abstention.name,
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

  static const _duration = Duration(milliseconds: 280);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final foreground = selected ? Colors.white : colorScheme.onSurface;

    return AnimatedOpacity(
      opacity: dimmed ? 0.4 : 1,
      duration: _duration,
      child: AnimatedContainer(
        duration: _duration,
        curve: Curves.easeOutCubic,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: selected ? color : colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium + 2),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            splashColor: color.withValues(alpha: 0.18),
            highlightColor: color.withValues(alpha: 0.08),
            hoverColor: color.withValues(alpha: 0.06),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: _duration,
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.22)
                            : color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
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
                                size: 20,
                                color: Colors.white,
                              )
                            : Text(
                                badge,
                                key: const ValueKey('badge'),
                                style: textTheme.titleSmall?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: _duration,
                        style: textTheme.bodyLarge!.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        child: Text(label),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox.square(
                      dimension: 20,
                      child: selected
                          ? const CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            )
                          : Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.6,
                              ),
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
    required this.dimmed,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool pending;
  final bool dimmed;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedOpacity(
      opacity: dimmed ? 0.4 : 1,
      duration: const Duration(milliseconds: 280),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          foregroundColor: colorScheme.onSurfaceVariant,
          disabledForegroundColor: colorScheme.onSurfaceVariant,
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        icon: pending
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}
