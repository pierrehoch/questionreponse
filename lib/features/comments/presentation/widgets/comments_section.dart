import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:question_reponse/app/theme/app_theme.dart';
import 'package:question_reponse/features/auth/presentation/controllers/auth_controller.dart';
import 'package:question_reponse/features/comments/domain/comment.dart';
import 'package:question_reponse/features/comments/presentation/controllers/comment_providers.dart';
import 'package:question_reponse/features/profile/presentation/controllers/profile_controller.dart';
import 'package:question_reponse/features/questions/domain/question_choice.dart';
import 'package:question_reponse/features/responses/domain/user_response.dart';

/// Discussion reserved to participants, shown in a sheet over the results.
class CommentsSection extends ConsumerStatefulWidget {
  const CommentsSection({
    required this.questionId,
    required this.choices,
    required this.response,
    super.key,
  });

  final String questionId;
  final List<QuestionChoice> choices;
  final UserResponse response;

  @override
  ConsumerState<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<CommentsSection> {
  final _controller = TextEditingController();
  int _limit = commentsPageSize;
  bool _sending = false;
  List<Comment> _lastComments = const [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _vote => switch (widget.response.type) {
    ResponseType.choice => widget.response.choiceId ?? '',
    final type => type.name,
  };

  bool get _canSend => !_sending && _controller.text.trim().isNotEmpty;

  Future<void> _send() async {
    final user = ref.read(authStateProvider).value;
    final username = ref.read(profileProvider).value?.username;
    final text = _controller.text.trim();
    if (user == null || username == null || text.isEmpty) {
      return;
    }
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(commentRepositoryProvider)
          .add(
            questionId: widget.questionId,
            userId: user.id,
            username: username,
            vote: _vote,
            text: text,
          );
      _controller.clear();
    } on CommentFailure catch (failure) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _delete(Comment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce commentaire ?'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(commentRepositoryProvider)
          .delete(questionId: widget.questionId, commentId: comment.id);
    } on CommentFailure catch (failure) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final query = (questionId: widget.questionId, limit: _limit);
    final comments = ref.watch(commentsProvider(query));
    final list = comments.value ?? _lastComments;
    _lastComments = list;
    final userId = ref.watch(authStateProvider).value?.id;
    ref.watch(profileProvider);
    final hasMore = list.length >= _limit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Discussion', style: textTheme.titleLarge),
            if (list.isNotEmpty) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  hasMore ? '${list.length}+' : '${list.length}',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Réservée aux personnes ayant répondu.',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        _Composer(
          controller: _controller,
          sending: _sending,
          onChanged: () => setState(() {}),
          onSend: _canSend ? _send : null,
        ),
        const SizedBox(height: 8),
        if (comments.hasError && list.isEmpty)
          _Placeholder(
            icon: Icons.cloud_off_rounded,
            message: 'Impossible de charger les commentaires.',
            action: TextButton.icon(
              onPressed: () => ref.invalidate(commentsProvider(query)),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          )
        else if (comments.isLoading && list.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (list.isEmpty)
          const _Placeholder(
            icon: Icons.chat_bubble_outline_rounded,
            message:
                'Aucun commentaire pour le moment.\nLancez la discussion !',
          )
        else ...[
          for (final comment in list)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: _CommentCard(
                comment: comment,
                choices: widget.choices,
                isMine: comment.userId == userId,
                onDelete: () => _delete(comment),
              ),
            ),
          if (hasMore)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
                onPressed: () => setState(() => _limit += commentsPageSize),
                icon: const Icon(Icons.expand_more_rounded),
                label: const Text('Voir plus de commentaires'),
              ),
            ),
        ],
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onChanged,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onChanged;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 2, 6, 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium + 4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !sending,
              minLines: 1,
              maxLines: 5,
              maxLength: Comment.maxLength,
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.multiline,
              onChanged: (_) => onChanged(),
              buildCounter:
                  (
                    context, {
                    required currentLength,
                    required isFocused,
                    required maxLength,
                  }) => maxLength != null && currentLength > maxLength * 0.8
                  ? Text(
                      '${maxLength - currentLength}',
                      style: textTheme.labelSmall?.copyWith(
                        color: currentLength >= maxLength
                            ? colorScheme.error
                            : colorScheme.onSurfaceVariant,
                      ),
                    )
                  : null,
              decoration: const InputDecoration(
                hintText: 'Partagez votre point de vue…',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox.square(
            dimension: 44,
            child: sending
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton.filled(
                    tooltip: 'Publier',
                    onPressed: onSend,
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusSmall + 2,
                        ),
                      ),
                      disabledBackgroundColor:
                          colorScheme.surfaceContainerHighest,
                    ),
                    icon: const Icon(Icons.arrow_upward_rounded),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.comment,
    required this.choices,
    required this.isMine,
    required this.onDelete,
  });

  final Comment comment;
  final List<QuestionChoice> choices;
  final bool isMine;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final badge = _voteBadge(colorScheme);
    final initial = comment.username.isEmpty
        ? '?'
        : comment.username.characters.first.toUpperCase();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: badge.color.withValues(alpha: 0.16),
          foregroundColor: badge.color,
          child: Text(
            initial,
            style: textTheme.labelLarge?.copyWith(
              color: badge.color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 2,
                children: [
                  Text(comment.username, style: textTheme.titleSmall),
                  _VoteChip(badge: badge),
                  Text(
                    formatCommentAge(comment.createdAt, DateTime.now()),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(comment.text, style: textTheme.bodyMedium),
            ],
          ),
        ),
        if (isMine)
          IconButton(
            tooltip: 'Supprimer mon commentaire',
            visualDensity: VisualDensity.compact,
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  _VoteBadge _voteBadge(ColorScheme colorScheme) {
    switch (comment.vote) {
      case 'blank':
        return _VoteBadge('Blanc', colorScheme.outline);
      case 'abstention':
        return _VoteBadge('Abstention', colorScheme.outline);
    }
    final index = choices.indexWhere((choice) => choice.id == comment.vote);
    if (index < 0) {
      return _VoteBadge('?', colorScheme.outline);
    }
    return _VoteBadge(
      String.fromCharCode(0x41 + index),
      AppTheme.choiceColor(index),
    );
  }
}

class _VoteBadge {
  const _VoteBadge(this.label, this.color);

  final String label;
  final Color color;
}

class _VoteChip extends StatelessWidget {
  const _VoteChip({required this.badge});

  final _VoteBadge badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: badge.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Vote ${badge.label}',
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: badge.color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: color),
          ),
          ?action,
        ],
      ),
    );
  }
}

String formatCommentAge(DateTime? createdAt, DateTime now) {
  if (createdAt == null) {
    return 'à l’instant';
  }
  final diff = now.difference(createdAt);
  if (diff.inMinutes < 1) {
    return 'à l’instant';
  }
  if (diff.inHours < 1) {
    return 'il y a ${diff.inMinutes} min';
  }
  if (diff.inDays < 1) {
    return 'il y a ${diff.inHours} h';
  }
  if (diff.inDays < 7) {
    return 'il y a ${diff.inDays} j';
  }
  final d = createdAt.day.toString().padLeft(2, '0');
  final m = createdAt.month.toString().padLeft(2, '0');
  return '$d/$m/${createdAt.year}';
}
