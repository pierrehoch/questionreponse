import 'package:flutter/material.dart';
import 'package:question_shared/question_shared.dart';

/// Optional answers (blank vote, abstention) offered on top of the choices.
class OptionalAnswersSection extends StatelessWidget {
  const OptionalAnswersSection({
    required this.allowBlank,
    required this.allowAbstention,
    required this.onChanged,
    super.key,
  });

  final bool allowBlank;
  final bool allowAbstention;
  final void Function({bool? allowBlank, bool? allowAbstention}) onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Réponses optionnelles', style: textTheme.titleMedium),
        Text(
          'Décochées par défaut : seules les réponses activées ici seront '
          'proposées aux participants.',
          style: textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        CheckboxListTile(
          key: const Key('allow-blank'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: allowBlank,
          onChanged: (value) => onChanged(allowBlank: value ?? false),
          title: const Text('Proposer le vote blanc'),
          secondary: const Icon(Icons.crop_square_rounded),
        ),
        CheckboxListTile(
          key: const Key('allow-abstention'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: allowAbstention,
          onChanged: (value) => onChanged(allowAbstention: value ?? false),
          title: const Text("Proposer l'abstention"),
          secondary: const Icon(Icons.do_not_disturb_on_outlined),
        ),
      ],
    );
  }
}

/// Grid of chart type cards with a schematic thumbnail of each rendering.
class ChartTypePicker extends StatelessWidget {
  const ChartTypePicker({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final QuestionChartType selected;
  final ValueChanged<QuestionChartType> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Représentation graphique', style: theme.textTheme.titleMedium),
        Text(
          'Choisissez comment les résultats seront dessinés dans l’application.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final type in QuestionChartType.values)
              _ChartTypeCard(
                key: Key('chart-type-${type.key}'),
                type: type,
                selected: type == selected,
                onTap: () => onChanged(type),
              ),
          ],
        ),
      ],
    );
  }
}

class _ChartTypeCard extends StatelessWidget {
  const _ChartTypeCard({
    required this.type,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final QuestionChartType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: selected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? colorScheme.primary : colorScheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 176,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 92,
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ChartTypeThumbnail(
                        type: type,
                        trackColor: colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    if (type.playful)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: _PlayfulBadge(colorScheme: colorScheme),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        type.label,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    if (selected)
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  type.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayfulBadge extends StatelessWidget {
  const _PlayfulBadge({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Ludique',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: colorScheme.onTertiaryContainer,
        ),
      ),
    );
  }
}

/// Icon bank grouped by category, with a "none" option.
class QuestionIconPicker extends StatelessWidget {
  const QuestionIconPicker({
    required this.selectedKey,
    required this.onChanged,
    super.key,
  });

  final String? selectedKey;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selected = QuestionIcons.byKey(selectedKey);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Icône de la question',
                style: theme.textTheme.titleMedium,
              ),
            ),
            if (selected != null)
              TextButton.icon(
                key: const Key('icon-none'),
                onPressed: () => onChanged(null),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Aucune'),
              ),
          ],
        ),
        Text(
          selected == null
              ? 'Facultatif : affichée au-dessus de la question.'
              : 'Sélection : ${selected.label}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        for (final category in QuestionIconCategory.values) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 6),
            child: Text(
              category.label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final icon in QuestionIcons.inCategory(category))
                Tooltip(
                  message: icon.label,
                  child: Material(
                    key: Key('icon-${icon.key}'),
                    color: icon.key == selectedKey
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => onChanged(icon.key),
                      child: SizedBox.square(
                        dimension: 44,
                        child: Icon(
                          icon.icon,
                          color: icon.key == selectedKey
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
