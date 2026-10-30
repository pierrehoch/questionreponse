import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:question_reponse/app/theme/app_theme.dart';
import 'package:question_reponse/core/countries/country.dart';
import 'package:question_reponse/features/comments/presentation/controllers/comment_providers.dart';
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Résultats', style: textTheme.titleLarge),
            const SizedBox(width: 10),
            _StatusPill(filtered: _filter != null),
            const Spacer(),
            _FilterButton(
              activeCount: switch (_filter) {
                null => 0,
                final filter =>
                  (filter.country == null ? 0 : 1) +
                      (filter.sex == null ? 0 : 1),
              },
              onPressed: _showFilters,
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
        const SizedBox(height: 16),
        if (statistics case AsyncError(:final error)) ...[
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 20,
                color: colorScheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  error is StatisticsFailure
                      ? error.message
                      : 'Impossible de charger les statistiques.',
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: summary != null
              ? AnimatedOpacity(
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
                    expand: true,
                  ),
                )
              : statistics.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Align(
                  alignment: AlignmentDirectional.topStart,
                  child: Text(
                    'Les statistiques sont en cours de préparation.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        _DiscussionButton(questionId: questionId, onPressed: _showDiscussion),
      ],
    );
  }

  Future<void> _showDiscussion() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => Padding(
      // Keeps the composer above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 1,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(
            AppTheme.pagePadding,
            0,
            AppTheme.pagePadding,
            24,
          ),
          child: CommentsSection(
            questionId: widget.response.questionId,
            choices: widget.choices,
            response: widget.response,
          ),
        ),
      ),
    ),
  );

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
          color: colorScheme.onSurfaceVariant,
        ),
      if (widget.allowAbstention || summary.abstentionCount > 0)
        StatisticEntry(
          id: ResponseType.abstention.name,
          label: 'Abstention',
          count: summary.abstentionCount,
          color: colorScheme.outline,
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

/// Entry point to the discussion sheet, with a peek at the latest comment.
class _DiscussionButton extends ConsumerWidget {
  const _DiscussionButton({required this.questionId, required this.onPressed});

  final String questionId;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // Same query as the sheet's first page, so opening it is instant.
    final comments =
        ref
            .watch(
              commentsProvider((
                questionId: questionId,
                limit: commentsPageSize,
              )),
            )
            .value ??
        const [];
    final latest = comments.firstOrNull;
    final count = comments.length >= commentsPageSize
        ? '$commentsPageSize+'
        : '${comments.length}';

    return Material(
      color: colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium + 2),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: [
              Icon(
                Icons.forum_outlined,
                size: 22,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Discussion', style: textTheme.titleSmall),
                        if (comments.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            count,
                            style: textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      latest == null
                          ? 'Lancez la discussion'
                          : '${latest.username} : ${latest.text}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_up_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.filtered});

  final bool filtered;

  static const _live = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final color = filtered ? colorScheme.primary : _live;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            filtered ? 'Filtrés' : 'En direct',
            style: textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.activeCount, required this.onPressed});

  final int activeCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final active = activeCount > 0;
    final foreground = active
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;

    return Tooltip(
      message: 'Filtrer les statistiques',
      excludeFromSemantics: true,
      child: Material(
        color: active
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune_rounded, size: 18, color: foreground),
                  const SizedBox(width: 6),
                  Text(
                    active ? 'Filtres · $activeCount' : 'Filtrer',
                    style: textTheme.labelLarge?.copyWith(color: foreground),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
