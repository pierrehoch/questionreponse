import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:question_reponse/app/theme/app_theme.dart';
import 'package:question_reponse/core/formatting/date_formatting.dart';
import 'package:question_reponse/features/questions/domain/question.dart';
import 'package:question_reponse/features/questions/presentation/controllers/question_providers.dart';
import 'package:question_reponse/features/questions/presentation/question_page.dart';
import 'package:question_reponse/features/questions/presentation/widgets/question_message.dart';
import 'package:question_reponse/features/responses/presentation/controllers/response_controller.dart';
import 'package:question_reponse/features/statistics/presentation/controllers/statistics_providers.dart';
import 'package:question_reponse/features/statistics/presentation/widgets/response_distribution.dart';
import 'package:question_reponse/features/statistics/presentation/widgets/statistics_chart.dart';

class QuestionHistoryPage extends ConsumerWidget {
  const QuestionHistoryPage({super.key});

  static const routePath = '/questions';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questions = ref.watch(publishedQuestionsProvider);
    final answeredIds = {
      for (final response in ref.watch(userResponsesProvider).value ?? [])
        response.questionId,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Questions')),
      body: questions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => QuestionMessage(
          icon: Icons.cloud_off_rounded,
          message: 'Impossible de charger les questions.',
          onRetry: () => ref.invalidate(publishedQuestionsProvider),
        ),
        data: (items) => items.isEmpty
            ? const QuestionMessage(
                icon: Icons.inbox_rounded,
                message: 'Aucune question publiée pour le moment.',
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.pagePadding - 8,
                  8,
                  AppTheme.pagePadding - 8,
                  32,
                ),
                itemCount: items.length + 1,
                separatorBuilder: (context, index) => index == 0
                    ? const SizedBox(height: 16)
                    : const Divider(indent: 68, endIndent: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _ProgressHeader(
                      answered: items
                          .where((item) => answeredIds.contains(item.id))
                          .length,
                      total: items.length,
                    );
                  }
                  final question = items[index - 1];
                  return _QuestionTile(
                    question: question,
                    answered: answeredIds.contains(question.id),
                  );
                },
              ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.answered, required this.total});

  final int answered;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final remaining = total - answered;
    final done = remaining == 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 52,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: total == 0 ? 0 : answered / total),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: value,
                    strokeWidth: 5,
                    strokeCap: StrokeCap.round,
                    backgroundColor: colorScheme.surfaceContainerHigh,
                  ),
                  Center(
                    child: done
                        ? Icon(
                            Icons.emoji_events_rounded,
                            size: 22,
                            color: colorScheme.primary,
                          )
                        : Text(
                            '${(value * 100).round()}%',
                            style: textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  done
                      ? 'Votre participation est complète'
                      : '$remaining ${remaining > 1 ? 'questions' : 'question'} '
                            'à répondre',
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '$answered / $total',
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        answered > 1 ? 'réponses données' : 'réponse donnée',
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({required this.question, required this.answered});

  final Question question;
  final bool answered;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      // Back to the timeline, which jumps to the picked question.
      onTap: () => context.canPop()
          ? context.pop(question.id)
          : context.go(QuestionPage.location(question.id)),
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: answered
                    ? colorScheme.surfaceContainer
                    : colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                question.icon?.icon ?? Icons.help_outline_rounded,
                size: 22,
                color: answered
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      fontSize: 15,
                      height: 1.3,
                      fontWeight: answered ? FontWeight.w500 : FontWeight.w700,
                      color: answered ? colorScheme.onSurfaceVariant : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (question.publishedAt case final date?)
                    Text(
                      formatShortDate(date),
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 10),
                  // Results stay hidden until the user has voted.
                  if (answered)
                    _HistoryDistribution(questionId: question.id)
                  else
                    const ResponseDistribution(entries: [], height: 8),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryDistribution extends ConsumerWidget {
  const _HistoryDistribution({required this.questionId});

  final String questionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statistics = ref.watch(questionStatisticsProvider(questionId));
    final choices = ref.watch(questionChoicesProvider(questionId));
    if (statistics.hasError || choices.hasError) {
      return TextButton.icon(
        onPressed: () {
          ref.invalidate(questionStatisticsProvider(questionId));
          ref.invalidate(questionChoicesProvider(questionId));
        },
        icon: const Icon(Icons.refresh_rounded, size: 14),
        label: const Text('Répartition indisponible'),
      );
    }
    if (statistics.isLoading || choices.isLoading) {
      return const SizedBox(height: 8, child: LinearProgressIndicator());
    }
    final summary = statistics.value;
    final colors = Theme.of(context).colorScheme;
    return ResponseDistribution(
      height: 8,
      entries: [
        for (final (index, choice) in (choices.value ?? []).indexed)
          StatisticEntry(
            id: choice.id,
            label: '',
            count: summary?.countForChoice(choice.id) ?? 0,
            color: AppTheme.choiceColor(index),
          ),
        StatisticEntry(
          id: 'blank',
          label: '',
          count: summary?.blankCount ?? 0,
          color: colors.onSurfaceVariant,
        ),
        StatisticEntry(
          id: 'abstention',
          label: '',
          count: summary?.abstentionCount ?? 0,
          color: colors.outline,
        ),
      ],
    );
  }
}
