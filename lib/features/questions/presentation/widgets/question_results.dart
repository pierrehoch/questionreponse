import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:question_reponse/app/theme/app_theme.dart';
import 'package:question_reponse/features/comments/presentation/controllers/comment_providers.dart';
import 'package:question_reponse/features/comments/presentation/widgets/comments_section.dart';
import 'package:question_reponse/features/questions/domain/question_choice.dart';
import 'package:question_reponse/features/responses/domain/user_response.dart';
import 'package:question_reponse/features/statistics/domain/question_statistics.dart';
import 'package:question_reponse/features/statistics/domain/statistics_failure.dart';
import 'package:question_reponse/features/statistics/presentation/controllers/statistics_providers.dart';
import 'package:question_reponse/features/statistics/presentation/widgets/demographic_comparisons.dart';
import 'package:question_reponse/features/statistics/presentation/widgets/statistics_chart.dart';
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
  final bool allowBlank;
  final bool allowAbstention;
  final QuestionChartType chartType;
  final QuestionStatistics? initialStatistics;
  final bool animateVote;

  @override
  ConsumerState<QuestionResults> createState() => _QuestionResultsState();
}

class _QuestionResultsState extends ConsumerState<QuestionResults> {
  late QuestionStatistics? _lastSummary = widget.initialStatistics;

  @override
  Widget build(BuildContext context) {
    final statistics = ref.watch(
      questionStatisticsProvider(widget.response.questionId),
    );
    final summary = statistics.value ?? _lastSummary;
    _lastSummary = summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (statistics case AsyncError(:final error))
          Text(
            error is StatisticsFailure
                ? error.message
                : 'Impossible de charger les statistiques.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        Expanded(
          child: summary != null
              ? StatisticsChart(
                  entries: _entriesOf(summary),
                  chartType: widget.chartType,
                  highlightedId: switch (widget.response.type) {
                    ResponseType.choice => widget.response.choiceId,
                    final type => type.name,
                  },
                  animateVote: widget.animateVote,
                  showLive: !statistics.hasError && !statistics.isLoading,
                  expand: true,
                )
              : statistics.isLoading
              ? const Center(child: CircularProgressIndicator())
              : const Text('Les statistiques sont en cours de préparation.'),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _showComparisons,
          icon: const Icon(Icons.bar_chart_rounded, size: 20),
          label: const Text('Comparer les pays, sexes et âges'),
        ),
        const SizedBox(height: 8),
        _DiscussionButton(
          questionId: widget.response.questionId,
          onPressed: _showDiscussion,
        ),
      ],
    );
  }

  Future<void> _showComparisons() {
    final questionId = widget.response.questionId;
    ref.invalidate(demographicStatisticsProvider(questionId));
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      constraints: BoxConstraints.tightFor(
        width: MediaQuery.sizeOf(context).width,
      ),
      builder: (context) => SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.75,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.pagePadding,
            ),
            child: DemographicComparisons(
              questionId: questionId,
              entriesOf: _entriesOf,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDiscussion() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: BoxConstraints.tightFor(
      width: MediaQuery.sizeOf(context).width,
    ),
    builder: (context) => SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
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
    ),
  );

  List<StatisticEntry> _entriesOf(QuestionStatistics summary) {
    final colors = Theme.of(context).colorScheme;
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
          color: colors.onSurfaceVariant,
        ),
      if (widget.allowAbstention || summary.abstentionCount > 0)
        StatisticEntry(
          id: ResponseType.abstention.name,
          label: 'Abstention',
          count: summary.abstentionCount,
          color: colors.outline,
        ),
    ];
  }
}

class _DiscussionButton extends ConsumerWidget {
  const _DiscussionButton({required this.questionId, required this.onPressed});

  final String questionId;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final comments = ref.watch(
      commentsProvider((questionId: questionId, limit: commentsPageSize)),
    );
    final latest = comments.value?.firstOrNull;
    final count = comments.value?.length ?? 0;
    return Material(
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.forum_outlined, size: 20, color: colors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count == 0
                          ? 'Discussion'
                          : 'Discussion · ${count >= commentsPageSize ? '$commentsPageSize+' : count}',
                      style: textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      comments.hasError
                          ? 'Impossible de charger la discussion'
                          : latest == null
                          ? 'Partagez votre point de vue'
                          : '${latest.username} : ${latest.text}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.expand_less_rounded, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
