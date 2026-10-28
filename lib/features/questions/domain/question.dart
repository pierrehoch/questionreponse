import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:question_shared/question_shared.dart';

enum QuestionStatus {
  pending,
  scheduled,
  published;

  static QuestionStatus fromValue(String value) {
    return values.firstWhere((status) => status.name == value);
  }
}

class Question {
  const Question({
    required this.id,
    required this.text,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.infoText,
    this.publishedAt,
    this.allowBlank = false,
    this.allowAbstention = false,
    this.chartType = QuestionChartType.fallback,
    this.iconKey,
  });

  final String id;
  final String text;
  final String? infoText;
  final QuestionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;
  final String createdBy;

  /// Whether "Vote blanc" is offered as an answer.
  final bool allowBlank;

  /// Whether "Abstention" is offered as an answer.
  final bool allowAbstention;

  /// How the results are drawn.
  final QuestionChartType chartType;

  /// Key in [QuestionIcons], displayed above the question text.
  final String? iconKey;

  QuestionIcon? get icon => QuestionIcons.byKey(iconKey);

  factory Question.fromFirestore(String id, Map<String, Object?> data) {
    return Question(
      id: id,
      text: data['text']! as String,
      infoText: data['infoText'] as String?,
      status: QuestionStatus.fromValue(data['status']! as String),
      createdAt: (data['createdAt']! as Timestamp).toDate(),
      updatedAt: (data['updatedAt']! as Timestamp).toDate(),
      publishedAt: (data['publishedAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy']! as String,
      allowBlank: data['allowBlank'] as bool? ?? false,
      allowAbstention: data['allowAbstention'] as bool? ?? false,
      chartType: QuestionChartType.fromKey(data['chartType'] as String?),
      iconKey: data['icon'] as String?,
    );
  }
}
