import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:question_reponse/app/theme/app_theme.dart';
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

class QuestionPage extends ConsumerStatefulWidget {
  const QuestionPage({this.questionId, super.key});

  static const homePath = '/';
  static const routePath = '/questions/:questionId';

  static String location(String questionId) => '/questions/$questionId';

  /// Question shown first; the latest published one when null.
  final String? questionId;

  @override
  ConsumerState<QuestionPage> createState() => _QuestionPageState();
}

/// Published questions laid out as a timeline: the newest on the right,
/// older ones reached by swiping right.
class _QuestionPageState extends ConsumerState<QuestionPage> {
  PageController? _pager;
  late String? _currentId = widget.questionId;

  @override
  void didUpdateWidget(QuestionPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.questionId != oldWidget.questionId &&
        widget.questionId != null) {
      _show(widget.questionId!);
    }
  }

  @override
  void dispose() {
    _pager?.dispose();
    super.dispose();
  }

  List<Question> _timelineOf(List<Question>? questions) =>
      questions?.reversed.toList(growable: false) ?? const [];

  /// Page of the displayed question, null when it is not published (it is
  /// then shown on its own).
  int? _indexIn(List<Question> timeline) {
    if (timeline.isEmpty) {
      return null;
    }
    final id = _currentId;
    final index = id == null
        ? -1
        : timeline.indexWhere((question) => question.id == id);
    if (index >= 0) {
      return index;
    }
    return id != null && id == widget.questionId ? null : timeline.length - 1;
  }

  void _show(String questionId) {
    setState(() => _currentId = questionId);
    final timeline = _timelineOf(ref.read(publishedQuestionsProvider).value);
    final index = _indexIn(timeline);
    final pager = _pager;
    if (index != null && pager != null && pager.hasClients) {
      pager.jumpToPage(index);
    }
  }

  Future<void> _openHistory() async {
    final questionId = await context.push<String>(
      QuestionHistoryPage.routePath,
    );
    if (questionId != null && mounted) {
      _show(questionId);
    }
  }

  @override
  Widget build(BuildContext context) {
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

    final questions = ref.watch(publishedQuestionsProvider);
    final timeline = _timelineOf(questions.value);
    final index = _indexIn(timeline);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Questions précédentes',
          onPressed: _openHistory,
          icon: const Icon(Icons.history_rounded),
        ),
        centerTitle: true,
        title: index != null && timeline.length > 1
            ? _PageDots(count: timeline.length, index: index)
            : null,
        actions: const [ProfileButton()],
      ),
      body: SafeArea(top: false, child: _buildBody(questions, timeline, index)),
    );
  }

  Widget _buildBody(
    AsyncValue<List<Question>> questions,
    List<Question> timeline,
    int? index,
  ) {
    final requestedId = widget.questionId;
    if (index != null) {
      return _buildPager(timeline, index);
    }
    if (questions.hasValue && requestedId != null) {
      return _QuestionView(questionId: requestedId);
    }
    if (questions.hasValue) {
      return const QuestionMessage(
        icon: Icons.inbox_rounded,
        message: 'Aucune question publiée pour le moment.',
      );
    }
    if (questions.hasError) {
      return requestedId != null
          ? _QuestionView(questionId: requestedId)
          : QuestionMessage(
              icon: Icons.cloud_off_rounded,
              message: 'Impossible de charger les questions.',
              onRetry: () => ref.invalidate(publishedQuestionsProvider),
            );
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildPager(List<Question> timeline, int index) {
    final pager = _pager ??= PageController(initialPage: index);
    // Questions published or removed meanwhile shift the pages: stay on the
    // displayed question.
    if (pager.hasClients &&
        !pager.position.isScrollingNotifier.value &&
        pager.page?.round() != index) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (pager.hasClients) {
          pager.jumpToPage(index);
        }
      });
    }

    return ScrollConfiguration(
      // Lets mouse users drag between questions too.
      behavior: ScrollConfiguration.of(context)
          .copyWith(dragDevices: PointerDeviceKind.values.toSet()),
      child: PageView.builder(
        controller: pager,
        // Neighbours are built ahead so a swipe never reveals a loader.
        allowImplicitScrolling: true,
        itemCount: timeline.length,
        onPageChanged: (page) => setState(() => _currentId = timeline[page].id),
        findChildIndexCallback: (key) {
          final index = timeline.indexWhere(
            (question) => ValueKey(question.id) == key,
          );
          return index < 0 ? null : index;
        },
        itemBuilder: (context, page) => _QuestionView(
          key: ValueKey(timeline[page].id),
          questionId: timeline[page].id,
        ),
      ),
    );
  }
}

/// Position in the timeline; long timelines show a sliding window of dots.
class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  static const _window = 7;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final start =
        (index - _window ~/ 2).clamp(0, math.max(0, count - _window)) as int;
    final end = math.min(count, start + _window);

    return Semantics(
      label: 'Question ${index + 1} sur $count',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = start; i < end; i++)
              AnimatedContainer(
                key: ValueKey(i),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == index ? 18 : _dotSize(i, start, end),
                height: _dotSize(i, start, end),
                decoration: BoxDecoration(
                  color: i == index
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Edge dots shrink when more questions lie beyond the window.
  double _dotSize(int i, int start, int end) =>
      (i == start && start > 0) || (i == end - 1 && end < count) ? 4 : 6;
}

class _QuestionView extends ConsumerStatefulWidget {
  const _QuestionView({required this.questionId, super.key});

  final String questionId;

  @override
  ConsumerState<_QuestionView> createState() => _QuestionViewState();
}

class _QuestionViewState extends ConsumerState<_QuestionView>
    with AutomaticKeepAliveClientMixin {
  String? _pendingId;
  bool _votedHere = false;

  /// Result returned by the backend, displayed until the Firestore listener
  /// delivers the persisted response.
  SubmitResult? _localResult;

  /// Keeps a vote in progress alive when the user swipes away.
  @override
  bool get wantKeepAlive => _pendingId != null || _localResult != null;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final question = ref.watch(questionProvider(widget.questionId));
    final choices = ref.watch(questionChoicesProvider(widget.questionId));
    final response = ref.watch(userResponseProvider(widget.questionId));

    return question.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => QuestionMessage(
        icon: Icons.cloud_off_rounded,
        message: 'Impossible de charger cette question.',
        onRetry: _reload,
      ),
      data: (item) {
        if (item == null) {
          return const QuestionMessage(
            icon: Icons.search_off_rounded,
            message: 'Cette question est introuvable.',
          );
        }
        return _FitToViewport(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.pagePadding,
            4,
            AppTheme.pagePadding,
            16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _QuestionHeader(question: item),
              const SizedBox(height: 24),
              Expanded(child: _buildBody(item, choices, response)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(
    Question item,
    AsyncValue<List<QuestionChoice>> choices,
    AsyncValue<UserResponse?> response,
  ) {
    return choices.when(
      loading: () => const _InlineLoader(),
      error: (error, stackTrace) =>
          const _InlineError('Impossible de charger les choix.'),
      data: (items) => response.when(
        loading: () => const _InlineLoader(),
        error: (error, stackTrace) =>
            const _InlineError('Impossible de vérifier votre participation.'),
        data: (persistedResponse) {
          final existingResponse = persistedResponse ?? _localResult?.response;
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
    updateKeepAlive();
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
      updateKeepAlive();
      return;
    }
    // Show the results right away instead of waiting for the listener.
    HapticFeedback.mediumImpact();
    setState(() => _localResult = result);
    updateKeepAlive();
  }
}

/// Sizes its child to exactly the viewport height so flexible parts (the
/// chart) absorb the free space.
///
/// When even their minimum does not fit (small screens, long texts), the page
/// is slightly scaled down rather than scrolled; it only scrolls beyond
/// [_ShrinkToFit.minScale] (very large text sizes).
class _FitToViewport extends StatelessWidget {
  const _FitToViewport({required this.padding, required this.child});

  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: padding,
        child: _ShrinkToFit(
          height: math.max(0, constraints.maxHeight - padding.vertical),
          child: child,
        ),
      ),
    );
  }
}

class _ShrinkToFit extends SingleChildRenderObjectWidget {
  const _ShrinkToFit({required this.height, super.child});

  final double height;

  static const minScale = 0.8;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderShrinkToFit(height);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderShrinkToFit renderObject,
  ) {
    renderObject.height = height;
  }
}

class _RenderShrinkToFit extends RenderProxyBox {
  _RenderShrinkToFit(this._height);

  double _height;
  double _scale = 1;

  set height(double value) {
    if (value != _height) {
      _height = value;
      markNeedsLayout();
    }
  }

  Matrix4 get _transform => Matrix4.diagonal3Values(_scale, _scale, 1);

  @override
  void performLayout() {
    final child = this.child;
    final width = constraints.maxWidth;
    if (child == null) {
      size = constraints.constrain(Size(width, _height));
      return;
    }
    double heightAt(double scale) =>
        child.getMaxIntrinsicHeight(width / scale) * scale;

    var scale = 1.0;
    if (heightAt(1) > _height && _height > 0) {
      // Laid out wider then scaled, texts wrap less: the first estimate
      // always fits, a second one gets closer to the screen height.
      scale = _height / child.getMaxIntrinsicHeight(width);
      final refined = _height / child.getMaxIntrinsicHeight(width / scale);
      if (heightAt(refined) <= _height) {
        scale = refined;
      }
      scale = math.min(1, math.max(_ShrinkToFit.minScale, scale));
    }
    _scale = scale;
    final innerWidth = width / scale;
    final innerHeight = math.max(
      _height / scale,
      child.getMaxIntrinsicHeight(innerWidth),
    );
    child.layout(
      BoxConstraints.tightFor(width: innerWidth, height: innerHeight),
    );
    size = constraints.constrain(Size(width, innerHeight * scale));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) {
      return;
    }
    if (_scale == 1) {
      layer = null;
      context.paintChild(child, offset);
      return;
    }
    layer = context.pushTransform(
      needsCompositing,
      offset,
      _transform,
      (context, offset) => context.paintChild(child, offset),
      oldLayer: layer as TransformLayer?,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) {
      return false;
    }
    return result.addWithPaintTransform(
      transform: _transform,
      position: position,
      hitTest: (result, position) => child.hitTest(result, position: position),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(_transform);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      constraints.constrain(Size(constraints.maxWidth, _height));
}

class _InlineLoader extends StatelessWidget {
  const _InlineLoader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 20, color: colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: colorScheme.error)),
          ),
        ],
      ),
    );
  }
}

class _QuestionHeader extends StatelessWidget {
  const _QuestionHeader({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final infoText = question.infoText;
    final icon = question.icon;
    final publishedAt = question.publishedAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            question.text,
            style: question.text.length > 90
                ? textTheme.headlineSmall
                : textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: 8),
        if (icon != null || publishedAt != null || infoText != null) ...[
          SizedBox(
            height: 36,
            child: Row(
              children: [
                if (icon != null) ...[
                  Semantics(
                    label: icon.label,
                    image: true,
                    child: Icon(
                      icon.icon,
                      size: 22,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (publishedAt != null)
                  Expanded(
                    child: Text(
                      formatLongDate(publishedAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  const Spacer(),
                if (infoText != null)
                  _InfoButton(onPressed: () => _showInfo(context, infoText)),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  /// In a sheet so the page layout never moves.
  Future<void> _showInfo(BuildContext context, String infoText) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
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
        minimum: const EdgeInsets.only(bottom: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.sizeOf(context).width,
            minHeight: MediaQuery.sizeOf(context).height * 0.45,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.pagePadding + 4,
              0,
              AppTheme.pagePadding + 4,
              32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('En savoir plus', style: textTheme.titleLarge),
                const SizedBox(height: 12),
                Text(
                  infoText,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
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

class _InfoButton extends StatelessWidget {
  const _InfoButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Tooltip(
      message: 'Informations',
      excludeFromSemantics: true,
      child: Material(
        color: colorScheme.surfaceContainer,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 7, 12, 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: colorScheme.onSurface,
                ),
                const SizedBox(width: 6),
                Text('En savoir plus', style: textTheme.labelMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
