import 'package:flutter/material.dart';

/// Icon selectable when creating a question, displayed above its text.
class QuestionIcon {
  const QuestionIcon._(this.key, this.label, this.icon, this.category);

  /// Stable identifier stored in Firestore (`questions/{id}.icon`).
  final String key;
  final String label;
  final IconData icon;
  final QuestionIconCategory category;
}

enum QuestionIconCategory {
  society('Société'),
  everyday('Vie quotidienne'),
  culture('Culture et loisirs'),
  science('Sciences et technologies'),
  nature('Nature et environnement'),
  misc('Émotions et divers');

  const QuestionIconCategory(this.label);

  final String label;
}

/// Bank of icons shared by the administration and the mobile application.
///
/// Keys must remain stable: a removed key would leave published questions
/// without an icon.
abstract final class QuestionIcons {
  static const all = <QuestionIcon>[
    // Society.
    QuestionIcon._(
      'vote',
      'Vote',
      Icons.how_to_vote_rounded,
      QuestionIconCategory.society,
    ),
    QuestionIcon._(
      'justice',
      'Justice',
      Icons.gavel_rounded,
      QuestionIconCategory.society,
    ),
    QuestionIcon._(
      'institutions',
      'Institutions',
      Icons.account_balance_rounded,
      QuestionIconCategory.society,
    ),
    QuestionIcon._(
      'people',
      'Société',
      Icons.groups_rounded,
      QuestionIconCategory.society,
    ),
    QuestionIcon._(
      'world',
      'Monde',
      Icons.public_rounded,
      QuestionIconCategory.society,
    ),
    QuestionIcon._(
      'news',
      'Actualité',
      Icons.newspaper_rounded,
      QuestionIconCategory.society,
    ),
    QuestionIcon._(
      'debate',
      'Débat',
      Icons.campaign_rounded,
      QuestionIconCategory.society,
    ),
    QuestionIcon._(
      'agreement',
      'Accord',
      Icons.handshake_rounded,
      QuestionIconCategory.society,
    ),
    QuestionIcon._(
      'diversity',
      'Diversité',
      Icons.diversity_3_rounded,
      QuestionIconCategory.society,
    ),
    QuestionIcon._(
      'solidarity',
      'Solidarité',
      Icons.volunteer_activism_rounded,
      QuestionIconCategory.society,
    ),
    QuestionIcon._(
      'education',
      'Éducation',
      Icons.school_rounded,
      QuestionIconCategory.society,
    ),
    QuestionIcon._(
      'health',
      'Santé',
      Icons.local_hospital_rounded,
      QuestionIconCategory.society,
    ),
    // Everyday life.
    QuestionIcon._(
      'work',
      'Travail',
      Icons.work_rounded,
      QuestionIconCategory.everyday,
    ),
    QuestionIcon._(
      'money',
      'Argent',
      Icons.payments_rounded,
      QuestionIconCategory.everyday,
    ),
    QuestionIcon._(
      'shopping',
      'Consommation',
      Icons.shopping_cart_rounded,
      QuestionIconCategory.everyday,
    ),
    QuestionIcon._(
      'economy',
      'Économie',
      Icons.trending_up_rounded,
      QuestionIconCategory.everyday,
    ),
    QuestionIcon._(
      'home',
      'Logement',
      Icons.home_rounded,
      QuestionIconCategory.everyday,
    ),
    QuestionIcon._(
      'transport',
      'Transports',
      Icons.directions_bus_rounded,
      QuestionIconCategory.everyday,
    ),
    QuestionIcon._(
      'family',
      'Famille',
      Icons.family_restroom_rounded,
      QuestionIconCategory.everyday,
    ),
    QuestionIcon._(
      'sleep',
      'Sommeil',
      Icons.bedtime_rounded,
      QuestionIconCategory.everyday,
    ),
    QuestionIcon._(
      'coffee',
      'Café',
      Icons.coffee_rounded,
      QuestionIconCategory.everyday,
    ),
    QuestionIcon._(
      'food',
      'Cuisine',
      Icons.restaurant_rounded,
      QuestionIconCategory.everyday,
    ),
    QuestionIcon._(
      'time',
      'Temps',
      Icons.schedule_rounded,
      QuestionIconCategory.everyday,
    ),
    // Culture and leisure.
    QuestionIcon._(
      'cinema',
      'Cinéma',
      Icons.movie_rounded,
      QuestionIconCategory.culture,
    ),
    QuestionIcon._(
      'music',
      'Musique',
      Icons.music_note_rounded,
      QuestionIconCategory.culture,
    ),
    QuestionIcon._(
      'books',
      'Lecture',
      Icons.menu_book_rounded,
      QuestionIconCategory.culture,
    ),
    QuestionIcon._(
      'football',
      'Football',
      Icons.sports_soccer_rounded,
      QuestionIconCategory.culture,
    ),
    QuestionIcon._(
      'sport',
      'Sport',
      Icons.fitness_center_rounded,
      QuestionIconCategory.culture,
    ),
    QuestionIcon._(
      'games',
      'Jeux vidéo',
      Icons.sports_esports_rounded,
      QuestionIconCategory.culture,
    ),
    QuestionIcon._(
      'art',
      'Art',
      Icons.palette_rounded,
      QuestionIconCategory.culture,
    ),
    QuestionIcon._(
      'show',
      'Spectacle',
      Icons.theater_comedy_rounded,
      QuestionIconCategory.culture,
    ),
    QuestionIcon._(
      'travel',
      'Voyage',
      Icons.flight_rounded,
      QuestionIconCategory.culture,
    ),
    QuestionIcon._(
      'party',
      'Fête',
      Icons.celebration_rounded,
      QuestionIconCategory.culture,
    ),
    QuestionIcon._(
      'trophy',
      'Compétition',
      Icons.emoji_events_rounded,
      QuestionIconCategory.culture,
    ),
    // Science and technology.
    QuestionIcon._(
      'science',
      'Sciences',
      Icons.science_rounded,
      QuestionIconCategory.science,
    ),
    QuestionIcon._(
      'digital',
      'Numérique',
      Icons.smartphone_rounded,
      QuestionIconCategory.science,
    ),
    QuestionIcon._(
      'mind',
      'Psychologie',
      Icons.psychology_rounded,
      QuestionIconCategory.science,
    ),
    QuestionIcon._(
      'space',
      'Espace',
      Icons.rocket_launch_rounded,
      QuestionIconCategory.science,
    ),
    QuestionIcon._(
      'technology',
      'Technologie',
      Icons.memory_rounded,
      QuestionIconCategory.science,
    ),
    QuestionIcon._(
      'robot',
      'Intelligence artificielle',
      Icons.smart_toy_rounded,
      QuestionIconCategory.science,
    ),
    QuestionIcon._(
      'biology',
      'Biologie',
      Icons.biotech_rounded,
      QuestionIconCategory.science,
    ),
    QuestionIcon._(
      'energy',
      'Énergie',
      Icons.bolt_rounded,
      QuestionIconCategory.science,
    ),
    // Nature and environment.
    QuestionIcon._(
      'ecology',
      'Écologie',
      Icons.eco_rounded,
      QuestionIconCategory.nature,
    ),
    QuestionIcon._(
      'animals',
      'Animaux',
      Icons.pets_rounded,
      QuestionIconCategory.nature,
    ),
    QuestionIcon._(
      'weather',
      'Météo',
      Icons.wb_sunny_rounded,
      QuestionIconCategory.nature,
    ),
    QuestionIcon._(
      'water',
      'Eau',
      Icons.water_drop_rounded,
      QuestionIconCategory.nature,
    ),
    QuestionIcon._(
      'forest',
      'Forêt',
      Icons.forest_rounded,
      QuestionIconCategory.nature,
    ),
    QuestionIcon._(
      'recycling',
      'Recyclage',
      Icons.recycling_rounded,
      QuestionIconCategory.nature,
    ),
    QuestionIcon._(
      'landscape',
      'Paysage',
      Icons.landscape_rounded,
      QuestionIconCategory.nature,
    ),
    // Emotions and miscellaneous.
    QuestionIcon._(
      'love',
      'Amour',
      Icons.favorite_rounded,
      QuestionIconCategory.misc,
    ),
    QuestionIcon._(
      'mood',
      'Humeur',
      Icons.sentiment_satisfied_rounded,
      QuestionIconCategory.misc,
    ),
    QuestionIcon._(
      'idea',
      'Idée',
      Icons.lightbulb_rounded,
      QuestionIconCategory.misc,
    ),
    QuestionIcon._(
      'question',
      'Question',
      Icons.help_rounded,
      QuestionIconCategory.misc,
    ),
    QuestionIcon._(
      'star',
      'Favori',
      Icons.star_rounded,
      QuestionIconCategory.misc,
    ),
    QuestionIcon._(
      'trend',
      'Tendance',
      Icons.local_fire_department_rounded,
      QuestionIconCategory.misc,
    ),
  ];

  static final _byKey = {for (final icon in all) icon.key: icon};

  /// Returns the icon for a persisted key, or null when unknown or missing.
  static QuestionIcon? byKey(String? key) => key == null ? null : _byKey[key];

  static List<QuestionIcon> inCategory(QuestionIconCategory category) => [
    for (final icon in all)
      if (icon.category == category) icon,
  ];
}
