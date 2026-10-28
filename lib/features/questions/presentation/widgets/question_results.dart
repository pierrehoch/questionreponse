import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:question_reponse/app/theme/app_theme.dart';
import 'package:question_reponse/core/countries/country.dart';
import 'package:question_reponse/features/comments/presentation/widgets/comments_section.dart';
import 'package:question_reponse/features/profile/presentation/controllers/profile_controller.dart';
import 'package:question_reponse/features/questions/domain/question_choice.dart';
import 'package:question_reponse/features/responses/domain/user_response.dart';
import 'package:question_reponse/features/statistics/domain/question_statistics.dart';
import 'package:question_reponse/features/statistics/domain/statistics_failure.dart';
import 'package:question_reponse/features/statistics/domain/statistics_filter.dart';
import 'package:question_reponse/features/statistics/presentation/controllers/statistics_providers.dart';
import 'package:question_reponse/features/statistics/presentation/widgets/statistics_chart.dart';
import 'package:question_reponse/features/statistics/presentation/widgets/statistics_filter_sheet.dart';
import 'package:question_shared/question_shared.dart';

class QuestionResults extends ConsumerStatefulWidget {
  const QuestionResults({
    required this.response,
    required this.choices,
    this.allowBlank = false,
    this.allowAbstention = false,
    this.chartType = QuestionChartType.fallback,
    this.initialStatistics,
    this.animateVote = false,
    super.key,
  });

  final UserResponse response;
  final List<QuestionChoice> choices;

  /// Optional answers enabled on the question; historical counts are still
  /// listed when present even if the option was later disabled.
  final bool allowBlank;
  final bool allowAbstention;
  final QuestionChartType chartType;

  /// Statistics already known (e.g. returned by the vote submission), shown
  /// immediately while the live stream connects.
  final QuestionStatistics? initialStatistics;

  /// Replays the user's vote in the chart, used right after voting.
  final bool animateVote;

  @override
  ConsumerState<QuestionResults> createState() => _QuestionResultsState();
}

class _QuestionResultsState extends ConsumerState<QuestionResults> {
  StatisticsFilter? _filter;
  late QuestionStatistics? _lastSummary = widget.initialStatistics;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final questionId = widget.response.questionId;
    final AsyncValue<QuestionStatistics?> statistics = switch (_filter) {
      null => ref.watch(questionStatisticsProvider(questionId)),
      final filter => ref.watch(
        filteredQuestionStatisticsProvider((
          questionId: questionId,
          filter: filter,
        )),
      ),
    };
    final summary = statistics.value ?? _lastSummary;
    _lastSummary = summary;
    // Known-fresh statistics are not dimmed while the live stream connects.
    final refreshing =
        statistics.isLoading && !identical(summary, widget.initialStatistics);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Résultats', style: textTheme.titleLarge),
                  const SizedBox(height: 2),
                  Text(
                    _filter == null ? 'En temps réel' : 'Résultats filtrés',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Badge(
              isLabelVisible: _filter != null,
              child: IconButton.filledTonal(
                tooltip: 'Filtrer les statistiques',
                onPressed: _showFilters,
                icon: const Icon(Icons.tune_rounded),
              ),
            ),
          ],
        ),
        if (_filter case final filter?) ...[
          const SizedBox(height: 12),
          _ActiveFilterChips(
            filter: filter,
            onChanged: (next) =>
                setState(() => _filter = next.isEmpty ? null : next),
          ),
        ],
        const SizedBox(height: 24),
        if (statistics case AsyncError(:final error)) ...[
          Text(
            error is StatisticsFailure
                ? error.message
                : 'Impossible de charger les statistiques.',
            style: TextStyle(color: colorScheme.error),
          ),
          const SizedBox(height: 16),
        ],
        if (summary != null)
          AnimatedOpacity(
            opacity: refreshing ? 0.5 : 1,
            duration: const Duration(milliseconds: 200),
            child: StatisticsChart(
              entries: _entriesOf(summary),
              chartType: widget.chartType,
              highlightedId: switch (widget.response.type) {
                ResponseType.choice => widget.response.choiceId,
                final type => type.name,
              },
              animateVote: widget.animateVote,
            ),
          )
        else if (statistics.isLoading)
          const SizedBox(
            height: 196,
            child: Center(child: CircularProgressIndicator()),
          )
        else
          const Text('Les statistiques sont en cours de préparation.'),
        const SizedBox(height: 28),
        CommentsSection(
          questionId: questionId,
          choices: widget.choices,
          response: widget.response,
        ),
      ],
    );
  }

  List<StatisticEntry> _entriesOf(QuestionStatistics summary) {
    final colorScheme = Theme.of(context).colorScheme;
    return [
      for (final (index, choice) in widget.choices.indexed)
        StatisticEntry(
          id: choice.id,
          label: choice.text,
          count: summary.countForChoice(choice.id),
          color: AppTheme.choiceColor(index),
        ),
      if (widget.allowBlank || summary.blankCount > 0)
        StatisticEntry(
          id: ResponseType.blank.name,
          label: 'Vote blanc',
          count: summary.blankCount,
          color: colorScheme.outline,
        ),
      if (widget.allowAbstention || summary.abstentionCount > 0)
        StatisticEntry(
          id: ResponseType.abstention.name,
          label: 'Abstention',
          count: summary.abstentionCount,
          color: colorScheme.outlineVariant,
        ),
    ];
  }

  Future<void> _showFilters() async {
    final filter = await showStatisticsFilterSheet(
      context,
      initialFilter: _filter,
      userCountry: ref.read(profileProvider).value?.country,
    );
    if (filter != null && mounted) {
      setState(() => _filter = filter.isEmpty ? null : filter);
    }
  }
}

/// Active facets, each removable on its own.
class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips({required this.filter, required this.onChanged});

  final StatisticsFilter filter;
  final ValueChanged<StatisticsFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final country = Countries.byCode(filter.country);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (filter.countryLabel case final label?)
          InputChip(
            avatar: country == null
                ? const Icon(Icons.public_rounded, size: 18)
                : Text(country.flag),
            label: Text(label),
            deleteButtonTooltipMessage: 'Retirer le pays',
            onDeleted: () => onChanged(filter.copyWith(country: () => null)),
          ),
        if (filter.sexLabel case final label?)
          InputChip(
            avatar: const Icon(Icons.wc_rounded, size: 18),
            label: Text(label),
            deleteButtonTooltipMessage: 'Retirer le sexe',
            onDeleted: () => onChanged(filter.copyWith(sex: () => null)),
          ),
      ],
    );
  }
}
