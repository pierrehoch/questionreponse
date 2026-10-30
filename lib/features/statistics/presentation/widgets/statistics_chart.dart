import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:question_reponse/core/formatting/number_formatting.dart';
import 'package:question_shared/question_shared.dart';

class StatisticEntry {
  const StatisticEntry({
    required this.id,
    required this.label,
    required this.count,
    required this.color,
  });

  final String id;
  final String label;
  final int count;
  final Color color;
}

/// A statistic ready to be drawn: animated count and share of the total.
class ChartSlice {
  const ChartSlice({
    required this.entry,
    required this.fraction,
    required this.count,
    required this.highlighted,
    required this.index,
  });

  final StatisticEntry entry;
  final double fraction;
  final int count;
  final bool highlighted;
  final int index;

  Color get color => entry.color;
  String get percent => '${(fraction * 100).round()} %';
  String get badge => String.fromCharCode(0x41 + index);
}

/// Results chart that animates smoothly between successive values.
///
/// The figure is drawn according to [chartType]; a legend with percentages
/// always follows it. When [animateVote] is true, the chart first shows the
/// results without the highlighted vote, then adds it so the user sees the
/// impact of their answer.
class StatisticsChart extends StatefulWidget {
  const StatisticsChart({
    required this.entries,
    this.chartType = QuestionChartType.donut,
    this.highlightedId,
    this.animateVote = false,
    this.expand = false,
    super.key,
  });

  final List<StatisticEntry> entries;
  final QuestionChartType chartType;
  final String? highlightedId;
  final bool animateVote;

  /// Lets the figure fill the free height (which must be bounded), shrinking
  /// it on short screens and hiding it when there is no room left.
  final bool expand;

  @override
  State<StatisticsChart> createState() => _StatisticsChartState();
}

class _StatisticsChartState extends State<StatisticsChart>
    with TickerProviderStateMixin {
  late final _transition = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final _progress = CurvedAnimation(
    parent: _transition,
    curve: Curves.easeOutCubic,
  );
  late final _impact = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  Map<String, double> _from = const {};
  Map<String, double> _to = const {};
  late Map<String, double> _target = _countsOf(widget.entries);

  @override
  void initState() {
    super.initState();
    final highlightedId = widget.highlightedId;
    if (widget.animateVote &&
        highlightedId != null &&
        (_target[highlightedId] ?? 0) > 0) {
      _playVoteImpact(highlightedId);
    } else {
      _animateTo(_target);
    }
  }

  @override
  void didUpdateWidget(StatisticsChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = _countsOf(widget.entries);
    if (!mapEquals(target, _target)) {
      _target = target;
      _animateTo(target);
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    _transition.dispose();
    _impact.dispose();
    super.dispose();
  }

  Map<String, double> _countsOf(List<StatisticEntry> entries) => {
    for (final entry in entries) entry.id: entry.count.toDouble(),
  };

  Map<String, double> get _current => {
    for (final id in {..._from.keys, ..._to.keys})
      id: lerpDouble(_from[id] ?? 0, _to[id] ?? 0, _progress.value)!,
  };

  TickerFuture _animateTo(Map<String, double> counts) {
    _from = _current;
    _to = counts;
    return _transition.forward(from: 0);
  }

  Future<void> _playVoteImpact(String highlightedId) async {
    final before = {..._target, highlightedId: _target[highlightedId]! - 1};
    try {
      await _animateTo(before).orCancel;
      await Future<void>.delayed(const Duration(milliseconds: 250));
    } on TickerCanceled {
      return;
    }
    if (!mounted || !identical(_to, before)) {
      return;
    }
    _animateTo(_target);
    _impact.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_progress, _impact]),
      builder: (context, _) {
        final counts = _current;
        final total = counts.values.fold<double>(
          0,
          (sum, value) => sum + value,
        );
        final slices = [
          for (final (index, entry) in widget.entries.indexed)
            ChartSlice(
              entry: entry,
              fraction: total == 0 ? 0 : counts[entry.id]! / total,
              count: counts[entry.id]!.round(),
              highlighted: entry.id == widget.highlightedId,
              index: index,
            ),
        ];
        final pulse = math.sin(math.pi * _impact.value);
        final participants = total.round();
        final type = widget.chartType;
        final expand = widget.expand;
        final participantsLabel = _ParticipantsLabel(
          participants: participants,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (type != QuestionChartType.donut) participantsLabel,
            switch (type) {
              QuestionChartType.donut => _FigureSlot(
                expand: expand,
                height: 200,
                reserved: 40,
                minHeight: 64,
                // The count sits inside the donut, keep it when it is hidden.
                fallback: participantsLabel,
                child: _DonutFigure(
                  slices: slices,
                  participants: participants,
                  pulse: pulse,
                ),
              ),
              QuestionChartType.bars => const SizedBox.shrink(),
              QuestionChartType.columns => _FigureSlot(
                expand: expand,
                height: 220,
                child: _ColumnsFigure(slices: slices, pulse: pulse),
              ),
              QuestionChartType.waffle => _FigureSlot(
                expand: expand,
                height: 220,
                child: _WaffleFigure(slices: slices, pulse: pulse),
              ),
              QuestionChartType.podium => _FigureSlot(
                expand: expand,
                height: 230,
                minHeight: 90,
                child: _PodiumFigure(slices: slices, pulse: pulse),
              ),
              QuestionChartType.bubbles => _FigureSlot(
                expand: expand,
                height: 200,
                child: _BubblesFigure(slices: slices, pulse: pulse),
              ),
              QuestionChartType.versus =>
                expand
                    ? Expanded(
                        child: Center(
                          child: _VersusFigure(slices: slices, pulse: pulse),
                        ),
                      )
                    : _VersusFigure(slices: slices, pulse: pulse),
            },
            SizedBox(
              height: type == QuestionChartType.bars
                  ? 4
                  : expand
                  ? 16
                  : 28,
            ),
            for (final slice in slices)
              _StatisticBar(
                slice: slice,
                impact: _impact.value,
                filled: type == QuestionChartType.bars,
              ),
            if (expand && type == QuestionChartType.bars) const Spacer(),
          ],
        );
      },
    );
  }
}

/// Hosts a figure that fills whatever box it is given.
///
/// Without [expand] the figure gets a fixed [height]. With [expand] it takes
/// the free height of the enclosing column, up to [maxHeight]; below
/// [minHeight] there is no room for a readable figure and [fallback] is shown
/// instead. Only [reserved] counts towards the column's intrinsic height so
/// the page can be sized to fit the screen.
class _FigureSlot extends StatelessWidget {
  const _FigureSlot({
    required this.expand,
    required this.height,
    required this.child,
    this.reserved = 0,
    this.minHeight = 110,
    this.fallback,
  });

  final bool expand;
  final double height;
  final double reserved;
  final double minHeight;
  final Widget? fallback;
  final Widget child;

  static const maxHeight = 260.0;

  @override
  Widget build(BuildContext context) {
    if (!expand) {
      return SizedBox(height: height, child: child);
    }
    return Expanded(
      child: _ReservedHeight(
        height: reserved,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxHeight < minHeight) {
              final fallback = this.fallback;
              return fallback != null && constraints.maxHeight >= reserved
                  ? Center(child: fallback)
                  : const SizedBox.shrink();
            }
            return Center(
              child: SizedBox(
                height: math.min(constraints.maxHeight, maxHeight),
                width: double.infinity,
                child: child,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Reports a fixed intrinsic height whatever its child, which lets an
/// [IntrinsicHeight] ancestor size a page without measuring the figure.
class _ReservedHeight extends SingleChildRenderObjectWidget {
  const _ReservedHeight({required this.height, super.child});

  final double height;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderReservedHeight(height);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderReservedHeight renderObject,
  ) {
    renderObject.reserved = height;
  }
}

class _RenderReservedHeight extends RenderProxyBox {
  _RenderReservedHeight(this._reserved);

  double _reserved;

  set reserved(double value) {
    if (value != _reserved) {
      _reserved = value;
      markNeedsLayout();
    }
  }

  @override
  double computeMinIntrinsicHeight(double width) => _reserved;

  @override
  double computeMaxIntrinsicHeight(double width) => _reserved;

  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMaxIntrinsicWidth(double height) => 0;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;
}

class _ParticipantsLabel extends StatelessWidget {
  const _ParticipantsLabel({required this.participants});

  final int participants;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.groups_rounded,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(formatCount(participants), style: textTheme.titleMedium),
          const SizedBox(width: 4),
          Text(
            participants > 1 ? 'participants' : 'participant',
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutFigure extends StatelessWidget {
  const _DonutFigure({
    required this.slices,
    required this.participants,
    required this.pulse,
  });

  final List<ChartSlice> slices;
  final int participants;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final painter = _DonutPainter(
      segments: [
        for (final slice in slices)
          (
            fraction: slice.fraction,
            color: slice.color,
            highlighted: slice.highlighted,
          ),
      ],
      trackColor: colorScheme.surfaceContainerHigh,
      pulse: pulse,
    );
    final count = Text(
      formatCount(participants),
      style: textTheme.headlineMedium,
    );
    final label = Text(
      participants > 1 ? 'participants' : 'participant',
      style: textTheme.labelMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Too small to hold the count: put it beside the ring.
        if (constraints.maxHeight < 150) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox.square(
                dimension: constraints.maxHeight,
                child: CustomPaint(painter: painter),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [count, label],
              ),
            ],
          );
        }
        return Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: CustomPaint(
              painter: painter,
              child: Padding(
                padding: const EdgeInsets.all(36),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [count, label],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Vertical bars, one per answer, with the share printed on top.
class _ColumnsFigure extends StatelessWidget {
  const _ColumnsFigure({required this.slices, required this.pulse});

  final List<ChartSlice> slices;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final maxFraction = slices.fold<double>(
      0,
      (max, slice) => math.max(max, slice.fraction),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final slice in slices)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                children: [
                  Text(
                    slice.percent,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: slice.highlighted
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: maxFraction == 0
                            ? 0.04
                            : (0.04 + 0.96 * slice.fraction / maxFraction)
                                  .clamp(0.04, 1.0),
                        widthFactor: slice.highlighted
                            ? 0.85 + 0.15 * pulse
                            : 0.7,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: slice.fraction == 0
                                ? colorScheme.surfaceContainerHigh
                                : slice.color,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                              bottom: Radius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _Badge(slice: slice),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// 10 × 10 grid: each cell stands for one percent of the participants.
class _WaffleFigure extends StatelessWidget {
  const _WaffleFigure({required this.slices, required this.pulse});

  final List<ChartSlice> slices;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: CustomPaint(
          painter: _WafflePainter(
            segments: [
              for (final slice in slices)
                (
                  fraction: slice.fraction,
                  color: slice.color,
                  highlighted: slice.highlighted,
                ),
            ],
            trackColor: colorScheme.surfaceContainerHigh,
            pulse: pulse,
          ),
        ),
      ),
    );
  }
}

/// Top three answers on a podium; the rest stay in the legend.
class _PodiumFigure extends StatelessWidget {
  const _PodiumFigure({required this.slices, required this.pulse});

  final List<ChartSlice> slices;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ranked = [...slices]
      ..sort((a, b) {
        final byCount = b.count.compareTo(a.count);
        return byCount != 0 ? byCount : a.index.compareTo(b.index);
      });
    final top = ranked.take(3).toList();
    // Silver, gold, bronze left to right like a real podium.
    final order = switch (top.length) {
      1 => [0],
      2 => [1, 0],
      _ => [1, 0, 2],
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        // Room left once the medal and the percentage are laid out.
        final tallest = (constraints.maxHeight - 40).clamp(24.0, 180.0);
        final heights = [tallest, tallest * 0.72, tallest * 0.55];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final rank in order)
              Expanded(
                flex: rank == 0 ? 5 : 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Medal(rank: rank),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              top[rank].percent,
                              maxLines: 1,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height:
                            heights[rank] +
                            (top[rank].highlighted ? 6 * pulse : 0),
                        decoration: BoxDecoration(
                          color: top[rank].fraction == 0
                              ? colorScheme.surfaceContainerHigh
                              : top[rank].color,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(14),
                          ),
                          boxShadow: top[rank].highlighted
                              ? [
                                  BoxShadow(
                                    color: top[rank].color.withValues(
                                      alpha: 0.35 + 0.3 * pulse,
                                    ),
                                    blurRadius: 12 + 12 * pulse,
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.topCenter,
                        padding: const EdgeInsets.all(8),
                        child: _podiumLabel(
                          top[rank].entry.label,
                          lines: ((heights[rank] - 16) / 18).floor(),
                          style: textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// The legend names every answer: short blocks simply drop it.
Widget? _podiumLabel(String label, {required int lines, TextStyle? style}) =>
    lines < 1
    ? null
    : Text(
        label,
        maxLines: math.min(lines, 2),
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: style,
      );

/// Gold, silver or bronze disc with the rank number (emoji-free so it
/// renders identically on every platform).
class _Medal extends StatelessWidget {
  const _Medal({required this.rank});

  final int rank;

  static const _colors = [
    Color(0xffF4B400),
    Color(0xffB8BEC7),
    Color(0xffCD8A4B),
  ];

  @override
  Widget build(BuildContext context) {
    final size = rank == 0 ? 28.0 : 24.0;
    final color = _colors[rank];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(color, Colors.white, 0.35)!, color],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '${rank + 1}',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: rank == 0 ? 14 : 12,
        ),
      ),
    );
  }
}

/// Circles whose area is proportional to each answer's share.
class _BubblesFigure extends StatelessWidget {
  const _BubblesFigure({required this.slices, required this.pulse});

  final List<ChartSlice> slices;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SizedBox.expand(
      child: CustomPaint(
        painter: _BubblesPainter(
          slices: slices,
          pulse: pulse,
          trackColor: colorScheme.surfaceContainerHigh,
          labelStyle: textTheme.labelLarge!.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
          badgeStyle: textTheme.labelMedium!.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// One stacked bar with a "VS" badge, made for two-sided questions.
class _VersusFigure extends StatelessWidget {
  const _VersusFigure({required this.slices, required this.pulse});

  final List<ChartSlice> slices;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final visible = slices.where((slice) => slice.fraction > 0).toList();
    final leading = slices.first;
    final trailing = slices.length > 1 ? slices[1] : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _VersusSide(
                slice: leading,
                alignment: CrossAxisAlignment.start,
              ),
            ),
            if (trailing != null)
              Expanded(
                child: _VersusSide(
                  slice: trailing,
                  alignment: CrossAxisAlignment.end,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: visible.isEmpty
                    ? ColoredBox(color: colorScheme.surfaceContainerHigh)
                    : Row(
                        children: [
                          for (final slice in visible)
                            Expanded(
                              flex: math.max(
                                1,
                                (slice.fraction * 1000).round(),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: slice.color,
                                  border: Border.symmetric(
                                    vertical: BorderSide(
                                      color: colorScheme.surface,
                                      width: 1.5,
                                    ),
                                  ),
                                  boxShadow: slice.highlighted
                                      ? [
                                          BoxShadow(
                                            color: slice.color.withValues(
                                              alpha: 0.5 * pulse,
                                            ),
                                            blurRadius: 16 * pulse,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
              // The badge sits on the split between both sides.
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const badgeWidth = 48.0;
                    final split = constraints.maxWidth * leading.fraction;
                    final left = (split - badgeWidth / 2)
                        .clamp(
                          0.0,
                          math.max(0.0, constraints.maxWidth - badgeWidth),
                        )
                        .toDouble();
                    return Stack(
                      children: [
                        Positioned(
                          left: left,
                          top: 0,
                          bottom: 0,
                          width: badgeWidth,
                          child: Center(
                            child: Container(
                              width: badgeWidth,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                ),
                              ),
                              child: Text(
                                'VS',
                                textAlign: TextAlign.center,
                                style: textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VersusSide extends StatelessWidget {
  const _VersusSide({required this.slice, required this.alignment});

  final ChartSlice slice;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final textAlign = alignment == CrossAxisAlignment.start
        ? TextAlign.start
        : TextAlign.end;
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          slice.percent,
          style: textTheme.displaySmall?.copyWith(
            color: slice.color,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          slice.entry.label,
          textAlign: textAlign,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: slice.highlighted ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.slice});

  final ChartSlice slice;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: slice.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        slice.badge,
        style: textTheme.labelMedium?.copyWith(
          color: slice.color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatisticBar extends StatelessWidget {
  const _StatisticBar({
    required this.slice,
    required this.impact,
    this.filled = false,
  });

  final ChartSlice slice;
  final double impact;

  /// The row background doubles as a bar showing the share, when the bars
  /// are the main figure.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final entry = slice.entry;
    final highlighted = slice.highlighted;
    final pulse = math.sin(math.pi * impact);
    final glow = highlighted ? 0.1 + 0.12 * pulse : 0.0;

    final row = Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: entry.color, shape: BoxShape.circle),
          child: const SizedBox.square(dimension: 10),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            entry.label,
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        if (highlighted) ...[
          Icon(Icons.check_circle_rounded, size: 18, color: entry.color),
          const SizedBox(width: 8),
        ],
        Stack(
          clipBehavior: Clip.none,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: slice.percent,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: '  ${formatCount(slice.count)}',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (highlighted && impact > 0 && impact < 1)
              Positioned(
                right: 0,
                bottom: 18 + 18 * impact,
                child: Opacity(
                  opacity: _bubbleOpacity(impact),
                  child: Text(
                    '+1',
                    style: textTheme.titleMedium?.copyWith(
                      color: entry.color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );

    if (!filled) {
      return Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: entry.color.withValues(alpha: glow),
          borderRadius: BorderRadius.circular(12),
        ),
        child: row,
      );
    }

    final dark = colorScheme.brightness == Brightness.dark;
    final fill = (dark ? 0.34 : 0.22) + (highlighted ? 0.1 + 0.12 * pulse : 0);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: slice.fraction.clamp(0, 1),
                child: ColoredBox(color: entry.color.withValues(alpha: fill)),
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(12), child: row),
        ],
      ),
    );
  }

  static double _bubbleOpacity(double t) {
    if (t < 0.15) {
      return t / 0.15;
    }
    if (t > 0.6) {
      return (1 - t) / 0.4;
    }
    return 1;
  }
}

typedef _Segment = ({double fraction, Color color, bool highlighted});

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.segments,
    required this.trackColor,
    required this.pulse,
  });

  final List<_Segment> segments;
  final Color trackColor;
  final double pulse;

  static const _stroke = 20.0;
  static const _gap = 0.05;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final scale = math.min(1, size.shortestSide / 180);
    final baseStroke = _stroke * scale;
    final radius = size.shortestSide / 2 - baseStroke / 2 - 8 * scale;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()..style = PaintingStyle.stroke;

    canvas.drawCircle(
      center,
      radius,
      paint
        ..color = trackColor
        ..strokeWidth = baseStroke,
    );

    final visible = segments.where((segment) => segment.fraction > 0).length;
    var start = -math.pi / 2;
    for (final segment in segments) {
      final sweep = segment.fraction * 2 * math.pi;
      final stroke = segment.highlighted
          ? baseStroke + (4 + 8 * pulse) * scale
          : baseStroke;
      paint
        ..color = segment.color
        ..strokeWidth = stroke;
      if (visible == 1 && sweep > 0) {
        canvas.drawCircle(center, radius, paint..strokeCap = StrokeCap.butt);
      } else if (sweep > 0) {
        // Round caps overflow each end by half the stroke: shorten the arc
        // so neighbours keep a clean gap, and draw tiny shares as dots.
        final caps = stroke / radius;
        final arc = sweep - _gap - caps;
        if (arc > 0) {
          canvas.drawArc(
            rect,
            start + (_gap + caps) / 2,
            arc,
            false,
            paint..strokeCap = StrokeCap.round,
          );
        } else {
          final angle = start + sweep / 2;
          final dotRadius =
              stroke / 2 * math.min(1, sweep / (_gap + caps)).clamp(0.45, 1);
          canvas.drawCircle(
            center + Offset(math.cos(angle), math.sin(angle)) * radius,
            dotRadius,
            Paint()..color = segment.color,
          );
        }
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) =>
      pulse != oldDelegate.pulse ||
      trackColor != oldDelegate.trackColor ||
      !listEquals(segments, oldDelegate.segments);
}

class _WafflePainter extends CustomPainter {
  const _WafflePainter({
    required this.segments,
    required this.trackColor,
    required this.pulse,
  });

  final List<_Segment> segments;
  final Color trackColor;
  final double pulse;

  static const _cells = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.shortestSide / _cells;
    final gap = cell * 0.14;
    final offset = Offset(
      (size.width - cell * _cells) / 2,
      (size.height - cell * _cells) / 2,
    );
    final paint = Paint();

    // Largest remainder rounding so the cells always sum to 100.
    final exact = segments.map((s) => s.fraction * _cells * _cells).toList();
    final counts = exact.map((value) => value.floor()).toList();
    var remaining = _cells * _cells - counts.fold<int>(0, (a, b) => a + b);
    final order = List.generate(exact.length, (i) => i)
      ..sort((a, b) => (exact[b] - counts[b]).compareTo(exact[a] - counts[a]));
    final totalFraction = segments.fold<double>(0, (a, s) => a + s.fraction);
    for (final index in order) {
      if (remaining <= 0 || totalFraction == 0) break;
      counts[index]++;
      remaining--;
    }

    var filled = 0;
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      paint.color = segment.color;
      for (var n = 0; n < counts[i]; n++) {
        final position = filled + n;
        // Fill bottom-up, left to right, like a bar being poured.
        final column = position ~/ _cells;
        final row = _cells - 1 - position % _cells;
        final inset = segment.highlighted ? gap - gap * 0.6 * pulse : gap;
        final rect = Rect.fromLTWH(
          offset.dx + column * cell + inset / 2,
          offset.dy + row * cell + inset / 2,
          cell - inset,
          cell - inset,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.22)),
          paint,
        );
      }
      filled += counts[i];
    }

    paint.color = trackColor;
    for (var position = filled; position < _cells * _cells; position++) {
      final column = position ~/ _cells;
      final row = _cells - 1 - position % _cells;
      final rect = Rect.fromLTWH(
        offset.dx + column * cell + gap / 2,
        offset.dy + row * cell + gap / 2,
        cell - gap,
        cell - gap,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.22)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WafflePainter oldDelegate) =>
      pulse != oldDelegate.pulse ||
      trackColor != oldDelegate.trackColor ||
      !listEquals(segments, oldDelegate.segments);
}

class _BubblesPainter extends CustomPainter {
  const _BubblesPainter({
    required this.slices,
    required this.pulse,
    required this.trackColor,
    required this.labelStyle,
    required this.badgeStyle,
  });

  final List<ChartSlice> slices;
  final double pulse;
  final Color trackColor;
  final TextStyle labelStyle;
  final TextStyle badgeStyle;

  static const _minRadius = 14.0;
  static const _gap = 10.0;
  static const _badgeHeight = 22.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (slices.isEmpty) return;
    final maxRadius = (size.height - _badgeHeight) / 2;
    // Area proportional to the share: radius grows with the square root.
    var radii = [
      for (final slice in slices)
        math.max(_minRadius, math.sqrt(slice.fraction) * maxRadius),
    ];
    final width =
        radii.fold<double>(0, (a, r) => a + 2 * r) + _gap * (radii.length - 1);
    if (width > size.width) {
      final scale =
          (size.width - _gap * (radii.length - 1)) /
          (width - _gap * (radii.length - 1));
      radii = radii.map((r) => math.max(_minRadius * 0.6, r * scale)).toList();
    }
    final totalWidth =
        radii.fold<double>(0, (a, r) => a + 2 * r) + _gap * (radii.length - 1);
    var x = (size.width - totalWidth) / 2;
    final baseline = maxRadius;
    final paint = Paint();

    for (var i = 0; i < slices.length; i++) {
      final slice = slices[i];
      final radius = radii[i] + (slice.highlighted ? 4 * pulse : 0);
      final center = Offset(x + radii[i], baseline);
      if (slice.fraction == 0) {
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = trackColor;
      } else {
        paint
          ..style = PaintingStyle.fill
          ..color = slice.color;
      }
      if (slice.highlighted && pulse > 0) {
        canvas.drawCircle(
          center,
          radius + 10 * pulse,
          Paint()..color = slice.color.withValues(alpha: 0.25 * (1 - pulse)),
        );
      }
      canvas.drawCircle(center, radius, paint);

      if (radius >= 22 && slice.fraction > 0) {
        _drawText(
          canvas,
          slice.percent,
          labelStyle.copyWith(fontSize: radius >= 40 ? 16 : 12),
          center,
        );
      }
      _drawText(
        canvas,
        slice.badge,
        badgeStyle,
        Offset(center.dx, baseline + maxRadius + _badgeHeight / 2),
      );
      x += 2 * radii[i] + _gap;
    }
  }

  void _drawText(Canvas canvas, String text, TextStyle style, Offset center) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_BubblesPainter oldDelegate) {
    if (pulse != oldDelegate.pulse ||
        trackColor != oldDelegate.trackColor ||
        slices.length != oldDelegate.slices.length) {
      return true;
    }
    for (var i = 0; i < slices.length; i++) {
      final a = slices[i];
      final b = oldDelegate.slices[i];
      if (a.fraction != b.fraction ||
          a.color != b.color ||
          a.highlighted != b.highlighted) {
        return true;
      }
    }
    return false;
  }
}
