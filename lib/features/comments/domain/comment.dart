class Comment {
  const Comment({
    required this.id,
    required this.userId,
    required this.username,
    required this.vote,
    required this.text,
    required this.createdAt,
  });

  static const maxLength = 500;

  final String id;
  final String userId;
  final String username;

  /// Choice id of the author's answer, or `blank` / `abstention`.
  final String vote;
  final String text;

  /// Null while the server timestamp of a fresh comment is pending.
  final DateTime? createdAt;
}

class CommentFailure implements Exception {
  const CommentFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
