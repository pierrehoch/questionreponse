import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionStatistics {
  const QuestionStatistics({
    required this.totalResponses,
    required this.choiceCounts,
    required this.blankCount,
    required this.abstentionCount,
    required this.updatedAt,
  });

  final int totalResponses;
  final Map<String, int> choiceCounts;
  final int blankCount;
  final int abstentionCount;
  final DateTime updatedAt;

  factory QuestionStatistics.fromFirestore(Map<String, Object?> data) {
    final rawChoiceCounts =
        data['choiceCounts'] as Map<String, Object?>? ?? const {};
    return QuestionStatistics(
      totalResponses: (data['totalResponses'] as num?)?.toInt() ?? 0,
      choiceCounts: rawChoiceCounts.map(
        (choiceId, value) => MapEntry(choiceId, (value as num).toInt()),
      ),
      blankCount: (data['blankCount'] as num?)?.toInt() ?? 0,
      abstentionCount: (data['abstentionCount'] as num?)?.toInt() ?? 0,
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory QuestionStatistics.fromCallable(Map<Object?, Object?> data) {
    final rawChoiceCounts =
        data['choiceCounts'] as Map<Object?, Object?>? ?? const {};
    return QuestionStatistics(
      totalResponses: (data['totalResponses'] as num?)?.toInt() ?? 0,
      choiceCounts: rawChoiceCounts.map(
        (choiceId, value) =>
            MapEntry(choiceId! as String, (value! as num).toInt()),
      ),
      blankCount: (data['blankCount'] as num?)?.toInt() ?? 0,
      abstentionCount: (data['abstentionCount'] as num?)?.toInt() ?? 0,
      updatedAt:
          DateTime.tryParse(data['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  int countForChoice(String choiceId) => choiceCounts[choiceId] ?? 0;

  double percentage(int count) {
    if (totalResponses == 0) {
      return 0;
    }
    return count / totalResponses * 100;
  }
}
