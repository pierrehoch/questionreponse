import 'package:flutter/material.dart';
import 'package:question_reponse/core/countries/country.dart';
import 'package:question_reponse/core/countries/country_picker.dart';
import 'package:question_reponse/features/profile/domain/user_profile.dart';
import 'package:question_reponse/features/statistics/domain/statistics_filter.dart';

/// Opens the statistics filter sheet.
///
/// Resolves to the chosen filter, an empty [StatisticsFilter] when the user
/// resets, or null when dismissed without changes.
Future<StatisticsFilter?> showStatisticsFilterSheet(
  BuildContext context, {
  StatisticsFilter? initialFilter,
  String? userCountry,
}) {
  return showModalBottomSheet<StatisticsFilter>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => StatisticsFilterSheet(
      initialFilter: initialFilter,
      userCountry: Countries.byCode(userCountry),
    ),
  );
}

class StatisticsFilterSheet extends StatefulWidget {
  const StatisticsFilterSheet({
    this.initialFilter,
    this.userCountry,
    super.key,
  });

  final StatisticsFilter? initialFilter;

  /// Country from the user's profile, offered as a one-tap shortcut.
  final Country? userCountry;

  @override
  State<StatisticsFilterSheet> createState() => _StatisticsFilterSheetState();
}

class _StatisticsFilterSheetState extends State<StatisticsFilterSheet> {
  static const _allSexes = 'all';

  late Country? _country = Countries.byCode(widget.initialFilter?.country);
  late String _sex = widget.initialFilter?.sex ?? _allSexes;

  bool get _hasSelection => _country != null || _sex != _allSexes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final userCountry = widget.userCountry;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Filtrer les résultats', style: textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Comparez les réponses selon le profil des participants.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle(icon: Icons.wc_rounded, label: 'Sexe'),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              const ButtonSegment(value: _allSexes, label: Text('Tous')),
              for (final sex in UserSex.values)
                ButtonSegment(value: sex.value, label: Text(sex.label)),
            ],
            selected: {_sex},
            onSelectionChanged: (selection) =>
                setState(() => _sex = selection.single),
          ),
          const SizedBox(height: 24),
          _SectionTitle(icon: Icons.public_rounded, label: 'Pays'),
          const SizedBox(height: 8),
          _CountryTile(
            country: _country,
            onTap: _pickCountry,
            onClear: _country == null
                ? null
                : () => setState(() => _country = null),
          ),
          if (userCountry != null && userCountry != _country)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ActionChip(
                  avatar: Text(userCountry.flag),
                  label: Text('Mon pays · ${userCountry.name}'),
                  onPressed: () => setState(() => _country = userCountry),
                ),
              ),
            ),
          const SizedBox(height: 28),
          OverflowBar(
            alignment: MainAxisAlignment.spaceBetween,
            overflowAlignment: OverflowBarAlignment.end,
            spacing: 8,
            overflowSpacing: 8,
            children: [
              TextButton.icon(
                onPressed: _hasSelection || widget.initialFilter != null
                    ? () => Navigator.pop(context, StatisticsFilter())
                    : null,
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Réinitialiser'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  StatisticsFilter(
                    country: _country?.code,
                    sex: _sex == _allSexes ? null : _sex,
                  ),
                ),
                child: const Text('Appliquer'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickCountry() async {
    final picked = await showCountryPicker(
      context,
      selected: _country,
      title: 'Filtrer par pays',
    );
    if (picked != null && mounted) {
      setState(() => _country = picked);
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.titleSmall),
      ],
    );
  }
}

class _CountryTile extends StatelessWidget {
  const _CountryTile({
    required this.country,
    required this.onTap,
    required this.onClear,
  });

  final Country? country;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final country = this.country;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: country == null
            ? Icon(Icons.language_rounded, color: colorScheme.onSurfaceVariant)
            : Text(country.flag, style: const TextStyle(fontSize: 26)),
        title: Text(
          country?.name ?? 'Tous les pays',
          style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: country == null
            ? const Text('Touchez pour choisir un pays')
            : Text(country.code),
        trailing: onClear == null
            ? const Icon(Icons.chevron_right_rounded)
            : IconButton(
                tooltip: 'Retirer le pays',
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
              ),
      ),
    );
  }
}
