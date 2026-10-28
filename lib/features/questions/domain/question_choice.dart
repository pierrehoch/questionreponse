class QuestionChoice {
  const QuestionChoice({
    required this.id,
    required this.text,
    required this.position,
  });

  final String id;
  final String text;
  final int position;

  factory QuestionChoice.fromFirestore(String id, Map<String, Object?> data) {
    return QuestionChoice(
      id: id,
      text: data['text']! as String,
      position: data['position']! as int,
    );
  }
}
