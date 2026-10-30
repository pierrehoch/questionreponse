import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:question_reponse/app/theme/app_theme.dart';
import 'package:question_reponse/app/widgets/loading_button.dart';
import 'package:question_reponse/app/widgets/notice_banner.dart';
import 'package:question_reponse/app/widgets/section_label.dart';
import 'package:question_reponse/app/widgets/segmented_control.dart';
import 'package:question_reponse/core/countries/country.dart';
import 'package:question_reponse/core/countries/country_picker.dart';
import 'package:question_reponse/features/auth/presentation/controllers/auth_controller.dart';
import 'package:question_reponse/features/profile/domain/profile_failure.dart';
import 'package:question_reponse/features/profile/domain/user_profile.dart';
import 'package:question_reponse/features/profile/presentation/controllers/profile_controller.dart';
import 'package:question_reponse/features/questions/presentation/question_page.dart';
import 'package:question_reponse/features/questions/presentation/widgets/question_message.dart';

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
  DateTime? _birthDate;
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
    final email = ref.watch(authStateProvider).value?.email;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    _initializeForm(profile);

    return Scaffold(
      appBar: AppBar(
        title: Text(profile == null ? 'Compléter mon profil' : 'Mon profil'),
      ),
      body: SafeArea(
        child: profileState.hasError
            ? QuestionMessage(
                icon: Icons.cloud_off_rounded,
                message: 'Impossible de charger votre profil.',
                onRetry: () => ref.invalidate(profileProvider),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.pagePadding,
                  8,
                  AppTheme.pagePadding,
                  24,
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
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
                            child: _AvatarPicker(
                              image: _profileImage(profile),
                              label: _avatarLabel(profile),
                              onPressed: action.isLoading ? null : _pickPhoto,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (profile != null)
                            Text(
                              profile.username,
                              textAlign: TextAlign.center,
                              style: textTheme.titleLarge,
                            ),
                          if (email != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              email,
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if (profile == null) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Ces informations permettent de comparer les '
                              'résultats par pays, sexe et âge. Votre date de '
                              'naissance reste privée ; seules des tranches '
                              'd’âge sont utilisées dans les statistiques.',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
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
                              prefixIcon: Icon(Icons.alternate_email_rounded),
                            ),
                            validator: _validateUsername,
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
                          const SizedBox(height: 24),
                          FormField<DateTime>(
                            key: ValueKey(
                              'birth-${_initializedProfileId ?? 'new'}',
                            ),
                            initialValue: _birthDate,
                            validator: (value) => value == null
                                ? 'Renseignez votre date de naissance.'
                                : null,
                            builder: (field) => InkWell(
                              onTap: action.isLoading
                                  ? null
                                  : () async {
                                      final now = DateUtils.dateOnly(
                                        DateTime.now(),
                                      );
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate:
                                            field.value ??
                                            DateTime(
                                              now.year - 18,
                                              now.month,
                                              now.day,
                                            ),
                                        firstDate: DateTime(1900),
                                        lastDate: now,
                                        helpText: 'Date de naissance',
                                        cancelText: 'Annuler',
                                        confirmText: 'Valider',
                                      );
                                      if (date != null && mounted) {
                                        _birthDate = date;
                                        field.didChange(date);
                                      }
                                    },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Date de naissance',
                                  prefixIcon: const Icon(Icons.cake_outlined),
                                  errorText: field.errorText,
                                  enabled: !action.isLoading,
                                ),
                                child: Text(
                                  field.value == null
                                      ? 'Choisir une date'
                                      : '${field.value!.day.toString().padLeft(2, '0')}/'
                                            '${field.value!.month.toString().padLeft(2, '0')}/'
                                            '${field.value!.year}',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const SectionLabel('Sexe'),
                          const SizedBox(height: 8),
                          SegmentedControlFormField<UserSex>(
                            key: ValueKey(
                              'sex-${_initializedProfileId ?? 'new'}',
                            ),
                            initialValue: _sex,
                            enabled: !action.isLoading,
                            segments: [
                              for (final sex in UserSex.values)
                                Segment(value: sex, label: sex.label),
                            ],
                            onChanged: (value) => _sex = value,
                            validator: (value) => value == null
                                ? 'Sélectionnez une valeur.'
                                : null,
                          ),
                          if (action case AsyncError(:final error)) ...[
                            const SizedBox(height: 20),
                            NoticeBanner(
                              message: error is ProfileFailure
                                  ? error.message
                                  : 'Une erreur inattendue est survenue.',
                            ),
                          ],
                          const SizedBox(height: 32),
                          LoadingButton(
                            label: profile == null
                                ? 'Créer mon profil'
                                : 'Enregistrer',
                            loading: action.isLoading,
                            onPressed: _save,
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: action.isLoading
                                ? null
                                : ref
                                      .read(authControllerProvider.notifier)
                                      .signOut,
                            style: TextButton.styleFrom(
                              foregroundColor: colorScheme.error,
                              minimumSize: const Size.fromHeight(48),
                            ),
                            icon: const Icon(Icons.logout_rounded, size: 20),
                            label: const Text('Se déconnecter'),
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
    _birthDate = profile.birthDate;
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
        birthDate: _birthDate!,
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

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.image,
    required this.label,
    required this.onPressed,
  });

  final ImageProvider<Object>? image;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Tooltip(
      message: 'Choisir une photo',
      child: Semantics(
        button: true,
        label: 'Choisir une photo',
        child: GestureDetector(
          onTap: onPressed,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: colorScheme.primaryContainer,
                foregroundImage: image,
                child: Text(
                  label,
                  style: textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colorScheme.inverseSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.surface, width: 3),
                  ),
                  child: Icon(
                    Icons.photo_camera_rounded,
                    size: 16,
                    color: colorScheme.onInverseSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
