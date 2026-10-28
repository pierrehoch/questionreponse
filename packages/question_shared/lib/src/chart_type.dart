/// Graphical representation of a question's results.
///
/// The [key] is persisted in Firestore (`questions/{id}.chartType`) and
/// validated by the security rules, so existing keys must never change.
enum QuestionChartType {
  donut(
    'donut',
    'Anneau',
    'Anneau de répartition accompagné de barres de détail. '
        'Lisible et polyvalent.',
    playful: false,
  ),
  bars(
    'bars',
    'Barres',
    'Barres horizontales classées, idéales pour comparer de nombreux choix.',
    playful: false,
  ),
  columns(
    'columns',
    'Colonnes',
    'Colonnes verticales côte à côte, simples et directes.',
    playful: false,
  ),
  waffle(
    'waffle',
    'Gaufre',
    'Cent carrés colorés : chaque carré représente 1 % des participants.',
    playful: true,
  ),
  podium(
    'podium',
    'Podium',
    'Les trois choix en tête montent sur le podium. '
        'Parfait pour les classements et les préférences.',
    playful: true,
  ),
  bubbles(
    'bubbles',
    'Bulles',
    'Des bulles dont la taille suit le nombre de votes. '
        'Ludique pour les thèmes libres.',
    playful: true,
  ),
  versus(
    'versus',
    'Face-à-face',
    'Une jauge partagée entre les camps, taillée pour les duels '
        'et les questions oui / non.',
    playful: true,
  );

  const QuestionChartType(
    this.key,
    this.label,
    this.description, {
    required this.playful,
  });

  /// Stable identifier stored in Firestore.
  final String key;
  final String label;
  final String description;

  /// Playful charts favour originality over precision.
  final bool playful;

  static const fallback = QuestionChartType.donut;

  /// Resolves a persisted key, falling back to [fallback] for unknown or
  /// missing values so older questions keep rendering.
  static QuestionChartType fromKey(String? key) {
    for (final type in values) {
      if (type.key == key) {
        return type;
      }
    }
    return fallback;
  }
}
