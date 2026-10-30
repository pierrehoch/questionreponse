import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:question_reponse/core/countries/country.dart';
import 'package:question_reponse/core/formatting/number_formatting.dart';
import 'package:question_reponse/features/statistics/domain/demographic_statistics.dart';
import 'package:question_reponse/features/statistics/domain/question_statistics.dart';
import 'package:question_reponse/features/statistics/domain/statistics_failure.dart';
import 'package:question_reponse/features/statistics/presentation/controllers/statistics_providers.dart';
import 'package:question_reponse/features/statistics/presentation/widgets/response_distribution.dart';
import 'package:question_reponse/features/statistics/presentation/widgets/statistics_chart.dart';

class DemographicComparisons extends ConsumerWidget {
  const DemographicComparisons({
    required this.questionId,
    required this.entriesOf,
    super.key,
  });

  final String questionId;
  final List<StatisticEntry> Function(QuestionStatistics) entriesOf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statistics = ref.watch(demographicStatisticsProvider(questionId));
    return statistics.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error is StatisticsFailure
                  ? error.message
                  : 'Impossible de charger les comparaisons.',
            ),
            TextButton(
              onPressed: () =>
                  ref.invalidate(demographicStatisticsProvider(questionId)),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
      data: (data) => DefaultTabController(
        length: DemographicDimension.values.length,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Pays'),
                Tab(text: 'Sexes'),
                Tab(text: 'Âges'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                children: [
                  for (final dimension in DemographicDimension.values)
                    _Groups(
                      dimension: dimension,
                      groups: data.groups[dimension] ?? const {},
                      entriesOf: entriesOf,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _ageLabels = {
  'under18': 'Moins de 18 ans',
  '18-24': '18–24 ans',
  '25-34': '25–34 ans',
  '35-44': '35–44 ans',
  '45-54': '45–54 ans',
  '55-64': '55–64 ans',
  '65plus': '65 ans et plus',
  'unknown': 'Âge non renseigné',
};

class _Groups extends StatelessWidget {
  const _Groups({
    required this.dimension,
    required this.groups,
    required this.entriesOf,
  });

  final DemographicDimension dimension;
  final Map<String, QuestionStatistics> groups;
  final List<StatisticEntry> Function(QuestionStatistics) entriesOf;

  String _label(String key) => switch (dimension) {
    DemographicDimension.country =>
      Countries.byCode(key)?.name ??
          (key == 'unknown' ? 'Pays non renseigné' : key),
    DemographicDimension.sex => switch (key) {
      'male' => 'Hommes',
      'female' => 'Femmes',
      'other' => 'Autre',
      _ => 'Sexe non renseigné',
    },
    DemographicDimension.age => _ageLabels[key] ?? key,
  };

  @override
  Widget build(BuildContext context) {
    final legend = {
      for (final group in groups.values)
        for (final entry in entriesOf(group)) entry.id: entry,
    }.values;
    final keys = groups.keys.toList()
      ..sort((a, b) {
        if (dimension == DemographicDimension.age) {
          return _ageLabels.keys
              .toList()
              .indexOf(a)
              .compareTo(_ageLabels.keys.toList().indexOf(b));
        }
        return _label(a).compareTo(_label(b));
      });
    if (keys.isEmpty) {
      return const Center(child: Text('Aucune donnée disponible.'));
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Répartition au sein de chaque groupe',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          for (final key in keys) ...[
            Row(
              children: [
                Expanded(child: Text(_label(key))),
                Text(
                  '${formatCount(groups[key]!.totalResponses)} '
                  '${groups[key]!.totalResponses > 1 ? 'participants' : 'participant'}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ResponseDistribution(entries: entriesOf(groups[key]!), height: 14),
            const SizedBox(height: 16),
          ],
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              for (final entry in legend)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: entry.color),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        entry.label,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (dimension == DemographicDimension.age) ...[
            const SizedBox(height: 12),
            const Text(
              'Âge au moment du vote. Les anciennes réponses sans âge restent non renseignées.',
            ),
          ],
        ],
      ),
    );
  }
}
