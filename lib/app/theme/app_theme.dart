import 'dart:ui' show lerpDouble;

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:question_shared/question_shared.dart';

/// Flat, neutral design system: plain surfaces, hairline outlines and a
/// single indigo accent. Colorful hues are reserved for answers and charts.
abstract final class AppTheme {
  /// Corner radii shared by every rounded surface.
  static const radiusSmall = 10.0;
  static const radiusMedium = 14.0;
  static const radiusLarge = 20.0;

  /// Horizontal padding of full-width pages.
  static const pagePadding = 20.0;

  /// Harmonious palette shared by choice cards and statistics charts.
  static const chartColors = ChartPalette.colors;

  static Color choiceColor(int index) => ChartPalette.colorAt(index);

  static ThemeData get light => _build(_lightScheme);

  static ThemeData get dark => _build(_darkScheme);

  static final _lightScheme =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF4F46E5),
        dynamicSchemeVariant: DynamicSchemeVariant.neutral,
      ).copyWith(
        primary: const Color(0xFF4F46E5),
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFEEF0FF),
        onPrimaryContainer: const Color(0xFF312E81),
        secondaryContainer: const Color(0xFFEDEDF2),
        onSecondaryContainer: const Color(0xFF26262E),
        surface: Colors.white,
        onSurface: const Color(0xFF111118),
        onSurfaceVariant: const Color(0xFF6B6B78),
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: const Color(0xFFF7F7F9),
        surfaceContainer: const Color(0xFFF2F2F5),
        surfaceContainerHigh: const Color(0xFFECECF0),
        surfaceContainerHighest: const Color(0xFFE4E4EA),
        outline: const Color(0xFFA1A1AC),
        outlineVariant: const Color(0xFFE6E6EB),
        inverseSurface: const Color(0xFF18181F),
        onInverseSurface: const Color(0xFFF4F4F6),
        error: const Color(0xFFDC2626),
        onError: Colors.white,
        errorContainer: const Color(0xFFFEECEC),
        onErrorContainer: const Color(0xFF8A1C1C),
        surfaceTint: Colors.transparent,
      );

  static final _darkScheme =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF4F46E5),
        brightness: Brightness.dark,
        dynamicSchemeVariant: DynamicSchemeVariant.neutral,
      ).copyWith(
        primary: const Color(0xFF8B8FFA),
        onPrimary: const Color(0xFF0B0B1E),
        primaryContainer: const Color(0xFF25244A),
        onPrimaryContainer: const Color(0xFFD0D2FF),
        secondaryContainer: const Color(0xFF26262E),
        onSecondaryContainer: const Color(0xFFE6E6EB),
        surface: const Color(0xFF0C0C10),
        onSurface: const Color(0xFFF3F3F6),
        onSurfaceVariant: const Color(0xFFA0A0AD),
        surfaceContainerLowest: const Color(0xFF08080B),
        surfaceContainerLow: const Color(0xFF131318),
        surfaceContainer: const Color(0xFF18181E),
        surfaceContainerHigh: const Color(0xFF202027),
        surfaceContainerHighest: const Color(0xFF2A2A33),
        outline: const Color(0xFF5A5A66),
        outlineVariant: const Color(0xFF26262E),
        inverseSurface: const Color(0xFFF3F3F6),
        onInverseSurface: const Color(0xFF18181F),
        error: const Color(0xFFF87171),
        onError: const Color(0xFF2B0606),
        errorContainer: const Color(0xFF3A1515),
        onErrorContainer: const Color(0xFFFECACA),
        surfaceTint: Colors.transparent,
      );

  static ThemeData _build(ColorScheme colorScheme) {
    final base = ThemeData(useMaterial3: true, colorScheme: colorScheme);
    final textTheme = base.textTheme
        .copyWith(
          displaySmall: base.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            height: 1.2,
          ),
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            height: 1.2,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
          titleSmall: base.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.45),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.45),
          labelLarge: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          labelMedium: base.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        )
        .apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        );
    final buttonText = textTheme.labelLarge?.copyWith(fontSize: 15);
    final mediumShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
    );
    const inputBorder = _FilledInputBorder(radius: radiusMedium);
    final isDark = colorScheme.brightness == Brightness.dark;
    final sheetColor = isDark ? colorScheme.surfaceContainerLow : Colors.white;

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 20),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        side: BorderSide.none,
        backgroundColor: colorScheme.surfaceContainerHigh,
        labelStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: mediumShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outlineVariant),
          shape: mediumShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        backgroundColor: colorScheme.inverseSurface,
        foregroundColor: colorScheme.onInverseSurface,
        shape: const StadiumBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainer,
        contentPadding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.error)
                ? colorScheme.error
                : states.contains(WidgetState.focused)
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        disabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        helperStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        iconColor: colorScheme.onSurfaceVariant,
        selectedColor: colorScheme.primary,
        selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.6),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: sheetColor,
        modalBackgroundColor: sheetColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        dragHandleColor: colorScheme.outline.withValues(alpha: 0.5),
        dragHandleSize: const Size(36, 4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: sheetColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: colorScheme.primary,
        textColor: colorScheme.onPrimary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHigh,
        circularTrackColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colorScheme.primary,
      ),
    );
  }
}

/// Borderless rounded field that keeps the floating label inside the fill
/// (unlike [OutlineInputBorder]) and draws a ring when focused or invalid.
class _FilledInputBorder extends InputBorder {
  const _FilledInputBorder({required this.radius, super.borderSide}) : super();

  final double radius;

  RRect _shape(Rect rect) =>
      RRect.fromRectAndRadius(rect, Radius.circular(radius));

  @override
  bool get isOutline => false;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  bool get preferPaintInterior => true;

  @override
  _FilledInputBorder copyWith({BorderSide? borderSide}) => _FilledInputBorder(
    radius: radius,
    borderSide: borderSide ?? this.borderSide,
  );

  @override
  ShapeBorder scale(double t) =>
      _FilledInputBorder(radius: radius * t, borderSide: borderSide.scale(t));

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_shape(rect).deflate(borderSide.width));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_shape(rect));

  @override
  void paintInterior(
    Canvas canvas,
    Rect rect,
    Paint paint, {
    TextDirection? textDirection,
  }) => canvas.drawRRect(_shape(rect), paint);

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    if (borderSide.style == BorderStyle.none || borderSide.width == 0) {
      return;
    }
    canvas.drawRRect(
      _shape(rect).deflate(borderSide.width / 2),
      borderSide.toPaint(),
    );
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) => a is _FilledInputBorder
      ? _FilledInputBorder(
          radius: lerpDouble(a.radius, radius, t)!,
          borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
        )
      : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) => b is _FilledInputBorder
      ? _FilledInputBorder(
          radius: lerpDouble(radius, b.radius, t)!,
          borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
        )
      : super.lerpTo(b, t);

  @override
  bool operator ==(Object other) =>
      other is _FilledInputBorder &&
      other.radius == radius &&
      other.borderSide == borderSide;

  @override
  int get hashCode => Object.hash(radius, borderSide);
}
