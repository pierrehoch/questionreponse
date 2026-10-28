import 'package:question_reponse/core/countries/country.dart';

class StatisticsFilter {
  StatisticsFilter({String? country, this.sex})
    : country = _normalizeCountry(country);

  /// ISO 3166-1 alpha-2 code, upper case.
  final String? country;
  final String? sex;

  bool get isEmpty => country == null && sex == null;

  /// Human readable country, falling back to the raw code.
  String? get countryLabel => switch (country) {
    null => null,
    final code => Countries.byCode(code)?.name ?? code,
  };

  String? get sexLabel => switch (sex) {
    null => null,
    final value => _sexLabel(value),
  };

  String get label {
    final parts = [
      if (countryLabel case final value?) 'Pays : $value',
      if (sexLabel case final value?) 'Sexe : $value',
    ];
    return parts.join(' · ');
  }

  StatisticsFilter copyWith({
    String? Function()? country,
    String? Function()? sex,
  }) {
    return StatisticsFilter(
      country: country == null ? this.country : country(),
      sex: sex == null ? this.sex : sex(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StatisticsFilter &&
        other.country == country &&
        other.sex == sex;
  }

  @override
  int get hashCode => Object.hash(country, sex);
}

String? _normalizeCountry(String? value) {
  final country = value?.trim().toUpperCase();
  return country == null || country.isEmpty ? null : country;
}

String _sexLabel(String value) {
  return switch (value) {
    'male' => 'Homme',
    'female' => 'Femme',
    _ => 'Autre',
  };
}
