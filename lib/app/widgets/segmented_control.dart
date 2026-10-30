import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Segment<T> {
  const Segment({required this.value, required this.label});

  final T value;
  final String label;
}

/// Flat iOS-style segmented control with a sliding selection thumb.
class SegmentedControl<T> extends StatelessWidget {
  const SegmentedControl({
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.hasError = false,
    super.key,
  });

  final List<Segment<T>> segments;
  final T? selected;
  final ValueChanged<T>? onChanged;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final selectedIndex = segments.indexWhere(
      (segment) => segment.value == selected,
    );
    final count = segments.length;
    final alignmentX = count == 1 || selectedIndex < 0
        ? 0.0
        : -1 + 2 * selectedIndex / (count - 1);

    return Semantics(
      container: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasError ? colorScheme.error : Colors.transparent,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                alignment: Alignment(alignmentX, 0),
                child: FractionallySizedBox(
                  widthFactor: 1 / count,
                  heightFactor: 1,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: selectedIndex < 0 ? 0 : 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: isDark
                            ? colorScheme.surfaceContainerHighest
                            : colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (var index = 0; index < count; index++)
                  Expanded(
                    child: _SegmentButton(
                      label: segments[index].label,
                      selected: index == selectedIndex,
                      textStyle: textTheme.labelLarge,
                      onTap: onChanged == null
                          ? null
                          : () {
                              if (index != selectedIndex) {
                                HapticFeedback.selectionClick();
                                onChanged!(segments[index].value);
                              }
                            },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.textStyle,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final TextStyle? textStyle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style: (textStyle ?? const TextStyle()).copyWith(
                    color: selected
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  child: Text(label),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// [SegmentedControl] wired to a [Form], with validation feedback.
class SegmentedControlFormField<T> extends FormField<T> {
  SegmentedControlFormField({
    required List<Segment<T>> segments,
    ValueChanged<T>? onChanged,
    super.initialValue,
    super.validator,
    super.enabled,
    super.key,
  }) : super(
         builder: (field) {
           final theme = Theme.of(field.context);
           return Column(
             crossAxisAlignment: CrossAxisAlignment.stretch,
             children: [
               SegmentedControl<T>(
                 segments: segments,
                 selected: field.value,
                 hasError: field.hasError,
                 onChanged: field.widget.enabled
                     ? (value) {
                         field.didChange(value);
                         onChanged?.call(value);
                       }
                     : null,
               ),
               if (field.errorText case final errorText?)
                 Padding(
                   padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                   child: Text(
                     errorText,
                     style: theme.textTheme.bodySmall?.copyWith(
                       color: theme.colorScheme.error,
                     ),
                   ),
                 ),
             ],
           );
         },
       );
}
