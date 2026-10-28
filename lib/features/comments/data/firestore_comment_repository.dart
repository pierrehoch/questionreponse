import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:question_reponse/features/comments/domain/comment.dart';
import 'package:question_reponse/features/comments/domain/comment_repository.dart';

class FirestoreCommentRepository implements CommentRepository {
  FirestoreCommentRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _comments(String questionId) =>
      _firestore.collection('questions').doc(questionId).collection('comments');

  @override
  Stream<List<Comment>> watchComments(String questionId, {required int limit}) {
    return _comments(questionId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => [for (final doc in snapshot.docs) ?_parse(doc)]);
  }

  Comment? _parse(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final userId = data['userId'];
    final username = data['username'];
    final vote = data['vote'];
    final text = data['text'];
    if (userId is! String ||
        username is! String ||
        vote is! String ||
        text is! String) {
      return null;
    }
    return Comment(
      id: doc.id,
      userId: userId,
      username: username,
      vote: vote,
      text: text,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  @override
  Future<void> add({
    required String questionId,
    required String userId,
    required String username,
    required String vote,
    required String text,
  }) async {
    try {
      await _comments(questionId).add({
        'userId': userId,
        'username': username,
        'vote': vote,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      throw CommentFailure(
        error.code == 'permission-denied'
            ? 'Vous devez avoir répondu à la question pour commenter.'
            : 'Impossible de publier votre commentaire pour le moment.',
      );
    }
  }

  @override
  Future<void> delete({
    required String questionId,
    required String commentId,
  }) async {
    try {
      await _comments(questionId).doc(commentId).delete();
    } on FirebaseException {
      throw const CommentFailure('Impossible de supprimer ce commentaire.');
    }
  }
}
