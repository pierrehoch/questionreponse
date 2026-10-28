import 'package:question_reponse/features/comments/domain/comment.dart';

abstract interface class CommentRepository {
  Stream<List<Comment>> watchComments(String questionId, {required int limit});

  Future<void> add({
    required String questionId,
    required String userId,
    required String username,
    required String vote,
    required String text,
  });

  Future<void> delete({required String questionId, required String commentId});
}
