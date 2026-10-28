import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:question_reponse/core/countries/country.dart';
import 'package:question_reponse/core/countries/country_picker.dart';
import 'package:question_reponse/features/auth/presentation/controllers/auth_controller.dart';
import 'package:question_reponse/features/profile/domain/profile_failure.dart';
import 'package:question_reponse/features/profile/domain/user_profile.dart';
import 'package:question_reponse/features/profile/presentation/controllers/profile_controller.dart';
import 'package:question_reponse/features/questions/presentation/question_page.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  static const routePath = '/profil';

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  Country? _country;
  UserSex? _sex;
  String? _initializedProfileId;
  Uint8List? _selectedPhoto;
  String? _selectedPhotoContentType;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final action = ref.watch(profileControllerProvider);
    final profile = profileState.value;
    _initializeForm(profile);

    return Scaffold(
      appBar: AppBar(
        title: Text(profile == null ? 'Compléter mon profil' : 'Mon profil'),
        actions: [
          IconButton(
            onPressed: action.isLoading
                ? null
                : ref.read(authControllerProvider.notifier).signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
          ),
        ],
      ),
      body: SafeArea(
        child: profileState.hasError
            ? _ProfileLoadError(onRetry: () => ref.invalidate(profileProvider))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Form(
                      key: _formKey,
                      onChanged: ref
                          .read(profileControllerProvider.notifier)
                          .clearError,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  radius: 44,
                                  foregroundImage: _profileImage(profile),
                                  child: Text(
                                    _avatarLabel(profile),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium,
                                  ),
                                ),
                                Positioned(
                                  right: -8,
                                  bottom: -8,
                                  child: IconButton.filledTonal(
                                    tooltip: 'Choisir une photo',
                                    onPressed: action.isLoading
                                        ? null
                                        : _pickPhoto,
                                    icon: const Icon(Icons.photo_camera),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          TextFormField(
                            controller: _usernameController,
                            enabled: !action.isLoading,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp('[A-Za-z0-9_]'),
                              ),
                              LengthLimitingTextInputFormatter(24),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Pseudo',
                              helperText:
                                  '3 à 24 lettres, chiffres ou caractères _',
                              prefixIcon: Icon(Icons.alternate_email),
                            ),
                            validator: _validateUsername,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: ref
                                .watch(authStateProvider)
                                .value
                                ?.email,
                            enabled: false,
                            decoration: const InputDecoration(
                              labelText: 'Adresse e-mail',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),
                          CountryFormField(
                            key: ValueKey(
                              'country-${_initializedProfileId ?? 'new'}',
                            ),
                            initialValue: _country,
                            enabled: !action.isLoading,
                            onChanged: (country) => _country = country,
                            validator: (country) => country == null
                                ? 'Sélectionnez votre pays dans la liste.'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<UserSex>(
                            initialValue: _sex,
                            decoration: const InputDecoration(
                              labelText: 'Sexe',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            items: [
                              for (final sex in UserSex.values)
                                DropdownMenuItem(
                                  value: sex,
                                  child: Text(sex.label),
                                ),
                            ],
                            onChanged: action.isLoading
                                ? null
                                : (value) => setState(() => _sex = value),
                            validator: (value) => value == null
                                ? 'Sélectionnez une valeur.'
                                : null,
                          ),
                          if (action case AsyncError(:final error)) ...[
                            const SizedBox(height: 16),
                            _ProfileError(error: error),
                          ],
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: action.isLoading ? null : _save,
                            child: action.isLoading
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    profile == null
                                        ? 'Créer mon profil'
                                        : 'Enregistrer',
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  void _initializeForm(UserProfile? profile) {
    if (profile == null || _initializedProfileId == profile.id) {
      return;
    }
    _initializedProfileId = profile.id;
    _usernameController.text = profile.username;
    _country = Countries.byCode(profile.country);
    _sex = profile.sex;
  }

  String _avatarLabel(UserProfile? profile) {
    final username = profile?.username.trim();
    return username == null || username.isEmpty
        ? '?'
        : username.substring(0, 1).toUpperCase();
  }

  ImageProvider<Object>? _profileImage(UserProfile? profile) {
    if (_selectedPhoto case final bytes?) {
      return MemoryImage(bytes);
    }
    if (profile?.photoUrl case final url?) {
      return NetworkImage(url);
    }
    return null;
  }

  Future<void> _pickPhoto() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (image == null) {
      return;
    }
    final bytes = await image.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La photo ne doit pas dépasser 5 Mo.')),
        );
      }
      return;
    }
    setState(() {
      _selectedPhoto = bytes;
      _selectedPhotoContentType = image.mimeType ?? 'image/jpeg';
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller = ref.read(profileControllerProvider.notifier);
    var photoUrl = ref.read(profileProvider).value?.photoUrl;
    if (_selectedPhoto case final bytes?) {
      photoUrl = await controller.uploadPhoto(
        bytes: bytes,
        contentType: _selectedPhotoContentType!,
      );
      if (photoUrl == null) {
        return;
      }
    }

    final saved = await controller.save(
      ProfileInput(
        username: _usernameController.text,
        country: _country!.code,
        sex: _sex!,
        photoUrl: photoUrl,
      ),
    );
    if (!saved || !mounted) {
      return;
    }
    setState(() {
      _selectedPhoto = null;
      _selectedPhotoContentType = null;
    });
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(QuestionPage.homePath);
    }
  }
}

String? _validateUsername(String? value) {
  final username = value?.trim() ?? '';
  if (!RegExp(r'^[A-Za-z0-9_]{3,24}$').hasMatch(username)) {
    return 'Utilisez entre 3 et 24 caractères autorisés.';
  }
  return null;
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final message = error is ProfileFailure
        ? (error as ProfileFailure).message
        : 'Une erreur inattendue est survenue.';
    return Text(
      message,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );
  }
}

class _ProfileLoadError extends StatelessWidget {
  const _ProfileLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Impossible de charger votre profil.'),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}
