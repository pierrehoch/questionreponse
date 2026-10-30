import 'package:flutter/material.dart';
import 'package:question_reponse/features/statistics/presentation/widgets/statistics_chart.dart';

class ResponseDistribution extends StatelessWidget {
  const ResponseDistribution({
    required this.entries,
    this.height = 10,
    super.key,
  });

  final List<StatisticEntry> entries;
  final double height;

  @override
  Widget build(BuildContext context) {
    final positive = entries.where((entry) => entry.count > 0).toList();
    final total = positive.fold(0, (sum, entry) => sum + entry.count);
    String description(StatisticEntry entry) =>
        '${entry.label.isEmpty ? '' : '${entry.label} : '}'
        '${(entry.count / total * 100).round()} % (${entry.count})';
    return Semantics(
      label: positive.isEmpty
          ? 'Aucune réponse'
          : 'Répartition des réponses : ${positive.map(description).join(', ')}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: positive.isEmpty
              ? ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final entry in positive)
                      Expanded(
                        flex: entry.count,
                        child: entry.label.isEmpty
                            ? ColoredBox(color: entry.color)
                            : Tooltip(
                                message: description(entry),
                                child: ColoredBox(color: entry.color),
                              ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
