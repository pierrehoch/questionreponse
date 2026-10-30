const _months = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

const _shortMonths = [
  'janv.',
  'févr.',
  'mars',
  'avr.',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];

String formatDate(DateTime date) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year}';
}

/// `28 octobre 2026`.
String formatLongDate(DateTime date) {
  final day = date.day == 1 ? '1er' : '${date.day}';
  return '$day ${_months[date.month - 1]} ${date.year}';
}

/// `28 oct.`, with the year appended when it differs from [now]'s.
String formatShortDate(DateTime date, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final label = '${date.day} ${_shortMonths[date.month - 1]}';
  return date.year == reference.year ? label : '$label ${date.year}';
}
