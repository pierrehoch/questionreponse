import 'dart:ui';

/// Harmonious palette shared by choice cards and statistics charts.
abstract final class ChartPalette {
  static const colors = [
    Color(0xFF6366F1),
    Color(0xFF14B8A6),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF0EA5E9),
    Color(0xFF8B5CF6),
    Color(0xFF84CC16),
    Color(0xFFF97316),
  ];

  static Color colorAt(int index) => colors[index % colors.length];
}
