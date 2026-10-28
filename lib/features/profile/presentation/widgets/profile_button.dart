import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:question_reponse/features/profile/presentation/controllers/profile_controller.dart';
import 'package:question_reponse/features/profile/presentation/profile_page.dart';

class ProfileButton extends ConsumerWidget {
  const ProfileButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    final username = profile?.username.trim() ?? '';
    final photoUrl = profile?.photoUrl;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        tooltip: 'Mon profil',
        onPressed: () => context.push(ProfilePage.routePath),
        icon: CircleAvatar(
          radius: 18,
          foregroundImage: photoUrl == null ? null : NetworkImage(photoUrl),
          child: Text(
            username.isEmpty ? '?' : username.substring(0, 1).toUpperCase(),
          ),
        ),
      ),
    );
  }
}
