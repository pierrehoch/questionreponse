import 'package:flutter/material.dart';
import 'package:question_reponse/core/countries/country.dart';

/// Lets the user pick a country from the predefined ISO list.
///
/// Returns the chosen country, or null when dismissed.
Future<Country?> showCountryPicker(
  BuildContext context, {
  Country? selected,
  String title = 'Choisir un pays',
}) {
  return showModalBottomSheet<Country>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _CountryPickerSheet(selected: selected, title: title),
  );
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({required this.selected, required this.title});

  final Country? selected;
  final String title;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchController = TextEditingController();
  List<Country> _results = Countries.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(String query) =>
      setState(() => _results = Countries.search(query));

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.title, style: textTheme.titleLarge),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: _search,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un pays',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: ListenableBuilder(
                      listenable: _searchController,
                      builder: (context, _) => _searchController.text.isEmpty
                          ? const SizedBox.shrink()
                          : IconButton(
                              tooltip: 'Effacer',
                              onPressed: () {
                                _searchController.clear();
                                _search('');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Text(
                      'Aucun pays ne correspond.',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final country = _results[index];
                      final selected = country == widget.selected;
                      return ListTile(
                        selected: selected,
                        leading: Text(
                          country.flag,
                          style: const TextStyle(fontSize: 26),
                        ),
                        title: Text(country.name),
                        trailing: selected
                            ? const Icon(Icons.check_rounded)
                            : Text(
                                country.code,
                                style: textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                        onTap: () => Navigator.pop(context, country),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Form field displaying the selected country and opening the picker on tap.
class CountryFormField extends FormField<Country> {
  CountryFormField({
    super.key,
    super.initialValue,
    super.validator,
    super.enabled,
    this.onChanged,
    String labelText = 'Pays',
  }) : super(
         autovalidateMode: AutovalidateMode.disabled,
         builder: (state) {
           final country = state.value;
           final theme = Theme.of(state.context);
           return InkWell(
             borderRadius: BorderRadius.circular(14),
             onTap: enabled
                 ? () async {
                     final picked = await showCountryPicker(
                       state.context,
                       selected: country,
                     );
                     if (picked != null) {
                       state.didChange(picked);
                       (state.widget as CountryFormField).onChanged?.call(
                         picked,
                       );
                     }
                   }
                 : null,
             child: InputDecorator(
               decoration: InputDecoration(
                 labelText: labelText,
                 hintText: 'Choisir dans la liste',
                 prefixIcon: country == null
                     ? const Icon(Icons.public)
                     : Padding(
                         padding: const EdgeInsets.symmetric(horizontal: 12),
                         child: Text(
                           country.flag,
                           style: const TextStyle(fontSize: 22),
                         ),
                       ),
                 prefixIconConstraints: const BoxConstraints(
                   minWidth: 48,
                   minHeight: 48,
                 ),
                 suffixIcon: const Icon(Icons.expand_more_rounded),
                 errorText: state.errorText,
                 enabled: enabled,
               ),
               isEmpty: country == null,
               child: Text(
                 country?.name ?? '',
                 style: theme.textTheme.bodyLarge?.copyWith(
                   color: enabled
                       ? theme.colorScheme.onSurface
                       : theme.disabledColor,
                 ),
               ),
             ),
           );
         },
       );

  final ValueChanged<Country>? onChanged;
}
