import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:question_shared/question_shared.dart';

enum AdminQuestionStatus { pending, scheduled, published }

class AdminQuestion {
  const AdminQuestion({
    required this.id,
    required this.text,
    required this.infoText,
    required this.status,
    required this.scheduledAt,
    required this.updatedAt,
    this.allowBlank = false,
    this.allowAbstention = false,
    this.chartType = QuestionChartType.fallback,
    this.iconKey,
  });

  final String id;
  final String text;
  final String? infoText;
  final AdminQuestionStatus status;
  final DateTime? scheduledAt;
  final DateTime updatedAt;
  final bool allowBlank;
  final bool allowAbstention;
  final QuestionChartType chartType;
  final String? iconKey;

  bool get canEdit => status != AdminQuestionStatus.published;

  factory AdminQuestion.fromDocument(
    QueryDocumentSnapshot<Map<String, Object?>> document,
  ) {
    final data = document.data();
    return AdminQuestion(
      id: document.id,
      text: data['text']! as String,
      infoText: data['infoText'] as String?,
      status: AdminQuestionStatus.values.byName(data['status']! as String),
      scheduledAt: (data['scheduledAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt']! as Timestamp).toDate(),
      allowBlank: data['allowBlank'] as bool? ?? false,
      allowAbstention: data['allowAbstention'] as bool? ?? false,
      chartType: QuestionChartType.fromKey(data['chartType'] as String?),
      iconKey: data['icon'] as String?,
    );
  }
}

class QuestionDraft {
  const QuestionDraft({
    required this.text,
    required this.infoText,
    required this.choices,
    required this.status,
    required this.scheduledAt,
    this.allowBlank = false,
    this.allowAbstention = false,
    this.chartType = QuestionChartType.fallback,
    this.iconKey,
  });

  final String text;
  final String? infoText;
  final List<String> choices;
  final AdminQuestionStatus status;
  final DateTime? scheduledAt;
  final bool allowBlank;
  final bool allowAbstention;
  final QuestionChartType chartType;
  final String? iconKey;

  /// Fields shared by creation and update writes.
  Map<String, Object?> toFirestoreFields() => {
    'text': text.trim(),
    'infoText': _optionalText(infoText),
    'status': status.name,
    'scheduledAt': scheduledAt == null
        ? null
        : Timestamp.fromDate(scheduledAt!),
    'publishedAt': null,
    'allowBlank': allowBlank,
    'allowAbstention': allowAbstention,
    'chartType': chartType.key,
    'icon': QuestionIcons.byKey(iconKey)?.key,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

String? _optionalText(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

String? validateQuestionDraft(QuestionDraft draft, {DateTime? now}) {
  if (draft.text.trim().length < 3) {
    return 'La question doit contenir au moins 3 caractères.';
  }
  final choices = draft.choices.map((choice) => choice.trim()).toList();
  if (choices.length < 2 || choices.any((choice) => choice.isEmpty)) {
    return 'Ajoutez au moins deux choix non vides.';
  }
  if (choices.toSet().length != choices.length) {
    return 'Chaque choix doit être unique.';
  }
  if (draft.status == AdminQuestionStatus.scheduled &&
      (draft.scheduledAt == null ||
          !draft.scheduledAt!.isAfter(now ?? DateTime.now()))) {
    return 'Choisissez une date de publication future.';
  }
  return null;
}

class QuestionRepository {
  QuestionRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, Object?>> get _questions =>
      _firestore.collection('questions');

  Stream<List<AdminQuestion>> watchQuestions() {
    return _questions
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(AdminQuestion.fromDocument).toList(),
        );
  }

  Future<List<String>> loadChoices(String questionId) async {
    final snapshot = await _questions
        .doc(questionId)
        .collection('choices')
        .orderBy('position')
        .get();
    return snapshot.docs
        .map((document) => document.data()['text']! as String)
        .toList();
  }

  Future<void> save({
    required QuestionDraft draft,
    required String userId,
    String? questionId,
  }) async {
    final validation = validateQuestionDraft(draft);
    if (validation != null) {
      throw ArgumentError(validation);
    }

    final reference = questionId == null
        ? _questions.doc()
        : _questions.doc(questionId);
    final batch = _firestore.batch();
    if (questionId == null) {
      batch.set(reference, {
        ...draft.toFirestoreFields(),
        'createdBy': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      batch.update(reference, draft.toFirestoreFields());
      final oldChoices = await reference.collection('choices').get();
      for (final choice in oldChoices.docs) {
        batch.delete(choice.reference);
      }
    }

    for (var index = 0; index < draft.choices.length; index++) {
      batch.set(reference.collection('choices').doc(), {
        'text': draft.choices[index].trim(),
        'position': index,
      });
    }
    await batch.commit();
  }

  Future<void> delete(AdminQuestion question) async {
    if (!question.canEdit) {
      throw StateError('Une question publiée est immuable.');
    }
    final reference = _questions.doc(question.id);
    final choices = await reference.collection('choices').get();
    final batch = _firestore.batch();
    for (final choice in choices.docs) {
      batch.delete(choice.reference);
    }
    batch.delete(reference);
    await batch.commit();
  }
}
