import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
          icon: Icons.cloud_off_outlined,
          message: 'Impossible de charger les questions.',
          onRetry: () => ref.invalidate(publishedQuestionsProvider),
        ),
        data: (items) => items.isEmpty
            ? const QuestionMessage(
                icon: Icons.inbox_outlined,
                message: 'Aucune question publiée pour le moment.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length + 1,
                separatorBuilder: (context, index) =>
                    SizedBox(height: index == 0 ? 20 : 10),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  remaining == 0
                      ? 'Vous avez répondu à toutes les questions'
                      : '$remaining ${remaining > 1 ? 'questions' : 'question'} '
                            'à répondre',
                  style: textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$answered / $total',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: total == 0 ? 0 : answered / total),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) =>
                  LinearProgressIndicator(value: value, minHeight: 6),
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
    final accent = answered
        ? colorScheme.onSurfaceVariant
        : colorScheme.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: answered ? colorScheme.surfaceContainerLow : null,
      child: InkWell(
        onTap: () => context.push(QuestionPage.location(question.id)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Badge(
                isLabelVisible: answered,
                backgroundColor: colorScheme.primary,
                label: Icon(
                  Icons.check_rounded,
                  size: 10,
                  color: colorScheme.onPrimary,
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: answered
                      ? colorScheme.surfaceContainerHighest
                      : colorScheme.primaryContainer,
                  foregroundColor: answered
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onPrimaryContainer,
                  child: Icon(
                    question.icon?.icon ?? Icons.how_to_vote_outlined,
                    size: 20,
                  ),
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
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: answered
                            ? FontWeight.w400
                            : FontWeight.w700,
                        color: answered ? colorScheme.onSurfaceVariant : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        answered ? 'Répondu' : 'À répondre',
                        if (question.publishedAt case final date?)
                          formatDate(date),
                      ].join(' · '),
                      style: textTheme.labelMedium?.copyWith(color: accent),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}
