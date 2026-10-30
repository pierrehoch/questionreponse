/// Formats an integer the French way, grouping thousands with a narrow
/// no-break space (`1 284`).
String formatCount(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write('\u202F');
    }
    buffer.write(digits[index]);
  }
  return buffer.toString();
}
