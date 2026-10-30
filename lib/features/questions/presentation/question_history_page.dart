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
                      ? 'Vous avez répondu à toutes les questions'
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
                  Row(
                    children: [
                      if (answered)
                        Icon(
                          Icons.done_rounded,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        )
                      else
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          [
                            answered ? 'Répondu' : 'À répondre',
                            if (question.publishedAt case final date?)
                              formatShortDate(date),
                          ].join(' · '),
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelMedium?.copyWith(
                            color: answered
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.primary,
                            fontWeight: answered
                                ? FontWeight.w500
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
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
