import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:question_reponse/core/countries/country.dart';
import 'package:question_reponse/core/countries/country_picker.dart';

void main() {
  test('country list is complete, unique and sorted', () {
    final codes = Countries.all.map((country) => country.code).toSet();

    expect(Countries.all.length, greaterThan(240));
    expect(codes.length, Countries.all.length);
    expect(codes, containsAll(['FR', 'BE', 'CH', 'CA', 'US', 'JP']));
    for (final country in Countries.all) {
      expect(country.code, matches(RegExp(r'^[A-Z]{2}$')));
      expect(country.flag.runes.length, 2);
    }
    expect(Countries.byCode('fr')?.name, 'France');
    expect(Countries.byCode(null), isNull);
    expect(Countries.byCode('XX'), isNull);
  });

  test('search ignores case and accents and matches codes', () {
    expect(Countries.search('etats').map((c) => c.code), contains('US'));
    expect(Countries.search('ÉTATS').map((c) => c.code), contains('US'));
    expect(Countries.search('be').first.code, 'BE');
    expect(Countries.search('  ').length, Countries.all.length);
    expect(Countries.search('zzzz'), isEmpty);
  });

  testWidgets('country picker searches and returns the selection', (
    tester,
  ) async {
    Country? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async => picked = await showCountryPicker(context),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'suis');
    await tester.pumpAndSettle();

    expect(find.text('Suisse'), findsOneWidget);
    expect(find.text('France'), findsNothing);

    await tester.tap(find.text('Suisse'));
    await tester.pumpAndSettle();

    expect(picked?.code, 'CH');
  });

  testWidgets('country form field validates and opens the picker', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    Country? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: CountryFormField(
              validator: (value) => value == null ? 'Requis' : null,
              onChanged: (value) => changed = value,
            ),
          ),
        ),
      ),
    );

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Requis'), findsOneWidget);

    await tester.tap(find.byType(CountryFormField));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'belg');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Belgique'));
    await tester.pumpAndSettle();

    expect(changed?.code, 'BE');
    expect(find.text('Belgique'), findsOneWidget);
    expect(formKey.currentState!.validate(), isTrue);
  });
}
