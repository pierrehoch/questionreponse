import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:question_reponse/core/formatting/date_formatting.dart';
import 'package:question_reponse/features/profile/presentation/widgets/profile_button.dart';
import 'package:question_reponse/features/questions/domain/question.dart';
import 'package:question_reponse/features/questions/domain/question_choice.dart';
import 'package:question_reponse/features/questions/presentation/controllers/question_providers.dart';
import 'package:question_reponse/features/questions/presentation/question_history_page.dart';
import 'package:question_reponse/features/questions/presentation/widgets/participation_form.dart';
import 'package:question_reponse/features/questions/presentation/widgets/question_message.dart';
import 'package:question_reponse/features/questions/presentation/widgets/question_results.dart';
import 'package:question_reponse/features/responses/domain/response_failure.dart';
import 'package:question_reponse/features/responses/domain/user_response.dart';
import 'package:question_reponse/features/responses/presentation/controllers/response_controller.dart';

class QuestionPage extends ConsumerWidget {
  const QuestionPage({this.questionId, super.key});

  static const homePath = '/';
  static const routePath = '/questions/:questionId';

  static String location(String questionId) => '/questions/$questionId';

  /// When null, the latest published question is displayed.
  final String? questionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(actions: const [ProfileButton()]),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: questionId == null
          ? FloatingActionButton.small(
              heroTag: null,
              tooltip: 'Questions précédentes',
              onPressed: () => context.push(QuestionHistoryPage.routePath),
              child: const Icon(Icons.history_rounded),
            )
          : null,
      body: switch (questionId) {
        final id? => _QuestionView(questionId: id),
        null =>
          ref
              .watch(latestPublishedQuestionProvider)
              .when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => QuestionMessage(
                  icon: Icons.cloud_off_outlined,
                  message: 'Impossible de charger les questions.',
                  onRetry: () =>
                      ref.invalidate(latestPublishedQuestionProvider),
                ),
                data: (latest) => latest == null
                    ? const QuestionMessage(
                        icon: Icons.inbox_outlined,
                        message: 'Aucune question publiée pour le moment.',
                      )
                    : _QuestionView(
                        key: ValueKey(latest.id),
                        questionId: latest.id,
                      ),
              ),
      },
    );
  }
}

class _QuestionView extends ConsumerStatefulWidget {
  const _QuestionView({required this.questionId, super.key});

  final String questionId;

  @override
  ConsumerState<_QuestionView> createState() => _QuestionViewState();
}

class _QuestionViewState extends ConsumerState<_QuestionView> {
  String? _pendingId;
  bool _votedHere = false;

  /// Result returned by the backend, displayed until the Firestore listener
  /// delivers the persisted response.
  SubmitResult? _localResult;

  final _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final show = _scrollController.offset > 600;
      if (show != _showScrollToTop) {
        setState(() => _showScrollToTop = show);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = ref.watch(questionProvider(widget.questionId));
    final choices = ref.watch(questionChoicesProvider(widget.questionId));
    final response = ref.watch(userResponseProvider(widget.questionId));

    ref.listen(responseControllerProvider, (previous, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                error is ResponseFailure
                    ? error.message
                    : 'Une erreur inattendue est survenue.',
              ),
            ),
          );
      }
    });

    return question.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => QuestionMessage(
        icon: Icons.cloud_off_outlined,
        message: 'Impossible de charger cette question.',
        onRetry: _reload,
      ),
      data: (item) {
        if (item == null) {
          return const QuestionMessage(
            icon: Icons.search_off_outlined,
            message: 'Cette question est introuvable.',
          );
        }

        return Stack(
          children: [
            _buildList(item, choices, response),
            Positioned(
              right: 16,
              bottom: 16,
              child: AnimatedScale(
                scale: _showScrollToTop ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: FloatingActionButton.small(
                  heroTag: null,
                  tooltip: 'Remonter en haut',
                  onPressed: _showScrollToTop
                      ? () => _scrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOutCubic,
                        )
                      : null,
                  child: const Icon(Icons.keyboard_arrow_up_rounded),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildList(
    Question item,
    AsyncValue<List<QuestionChoice>> choices,
    AsyncValue<UserResponse?> response,
  ) {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 96),
      children: [
        _QuestionHeader(question: item),
        const SizedBox(height: 32),
        choices.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              const Text('Impossible de charger les choix.'),
          data: (items) => response.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) =>
                const Text('Impossible de vérifier votre participation.'),
            data: (persistedResponse) {
              final existingResponse =
                  persistedResponse ?? _localResult?.response;
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topCenter,
                  children: [...previous, ?current],
                ),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.04),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: existingResponse == null
                    ? ParticipationForm(
                        key: const ValueKey('form'),
                        choices: items,
                        allowBlank: item.allowBlank,
                        allowAbstention: item.allowAbstention,
                        pendingId: _pendingId,
                        onSubmit: _submit,
                      )
                    : QuestionResults(
                        key: const ValueKey('results'),
                        response: existingResponse,
                        choices: items,
                        allowBlank: item.allowBlank,
                        allowAbstention: item.allowAbstention,
                        chartType: item.chartType,
                        initialStatistics: _localResult?.statistics,
                        animateVote: _votedHere,
                      ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _reload() {
    ref
      ..invalidate(questionProvider(widget.questionId))
      ..invalidate(questionChoicesProvider(widget.questionId))
      ..invalidate(userResponseProvider(widget.questionId));
  }

  Future<void> _submit(ResponseSubmission submission) async {
    HapticFeedback.selectionClick();
    setState(() {
      _pendingId = submission.choiceId ?? submission.type.name;
      _votedHere = true;
    });
    final result = await ref
        .read(responseControllerProvider.notifier)
        .submit(questionId: widget.questionId, submission: submission);
    if (!mounted) {
      return;
    }
    if (result == null) {
      setState(() {
        _pendingId = null;
        _votedHere = false;
      });
      return;
    }
    // Show the results right away instead of waiting for the listener.
    HapticFeedback.mediumImpact();
    setState(() => _localResult = result);
  }
}

class _QuestionHeader extends StatefulWidget {
  const _QuestionHeader({required this.question});

  final Question question;

  @override
  State<_QuestionHeader> createState() => _QuestionHeaderState();
}

class _QuestionHeaderState extends State<_QuestionHeader> {
  bool _infoExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final question = widget.question;
    final infoText = question.infoText;
    final icon = question.icon;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        if (icon != null) ...[
          Center(
            child: Semantics(
              label: icon.label,
              image: true,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon.icon,
                  size: 36,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        Text(
          question.text,
          textAlign: TextAlign.center,
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (question.publishedAt case final publishedAt?)
              Text(
                'Publiée le ${formatDate(publishedAt)}',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            if (infoText != null)
              IconButton(
                tooltip: 'Informations',
                isSelected: _infoExpanded,
                visualDensity: VisualDensity.compact,
                iconSize: 20,
                color: colorScheme.onSurfaceVariant,
                onPressed: () => setState(() => _infoExpanded = !_infoExpanded),
                icon: const Icon(Icons.info_outline_rounded),
                selectedIcon: Icon(
                  Icons.info_rounded,
                  color: colorScheme.primary,
                ),
              ),
          ],
        ),
        if (infoText != null)
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _infoExpanded
                ? Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      infoText,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
      ],
    );
  }
}
