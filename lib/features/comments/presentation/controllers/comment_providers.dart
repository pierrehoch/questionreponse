import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:question_reponse/features/comments/data/firestore_comment_repository.dart';
import 'package:question_reponse/features/comments/domain/comment.dart';
import 'package:question_reponse/features/comments/domain/comment_repository.dart';

const commentsPageSize = 20;

final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => FirestoreCommentRepository(FirebaseFirestore.instance),
);

typedef CommentsQuery = ({String questionId, int limit});

final commentsProvider = StreamProvider.family<List<Comment>, CommentsQuery>(
  (ref, query) => ref
      .watch(commentRepositoryProvider)
      .watchComments(query.questionId, limit: query.limit),
);
