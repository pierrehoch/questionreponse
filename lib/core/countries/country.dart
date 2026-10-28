/// ISO 3166-1 alpha-2 country with its French name.
class Country {
  const Country._(this.code, this.name);

  /// Two-letter uppercase ISO code, the value persisted in Firestore.
  final String code;
  final String name;

  /// Flag emoji built from the regional indicator symbols of [code].
  String get flag => String.fromCharCodes([
    for (final unit in code.codeUnits) 0x1F1E6 + unit - 0x41,
  ]);

  @override
  bool operator ==(Object other) => other is Country && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => '$flag $name';
}

/// Predefined list of every ISO 3166-1 country, sorted by French name.
abstract final class Countries {
  static final List<Country> all = List.unmodifiable(
    [..._entries]
      ..sort((a, b) => foldForSearch(a.name).compareTo(foldForSearch(b.name))),
  );

  static final _byCode = {
    for (final country in _entries) country.code: country,
  };

  /// Returns the country for an ISO code (case-insensitive), or null.
  static Country? byCode(String? code) =>
      code == null ? null : _byCode[code.trim().toUpperCase()];

  /// Countries whose name or code matches [query], ignoring case and accents.
  static List<Country> search(String query) {
    final needle = foldForSearch(query);
    if (needle.isEmpty) {
      return all;
    }
    return [
      for (final country in all)
        if (foldForSearch(country.name).contains(needle) ||
            country.code.toLowerCase().startsWith(needle))
          country,
    ];
  }

  /// Lowercases and strips accents so searches match "etats" to "États".
  static String foldForSearch(String value) {
    final buffer = StringBuffer();
    for (final rune in value.trim().toLowerCase().runes) {
      buffer.write(_accents[rune] ?? String.fromCharCode(rune));
    }
    return buffer.toString();
  }

  static const _accents = <int, String>{
    0xE0: 'a', 0xE1: 'a', 0xE2: 'a', 0xE4: 'a', 0xE5: 'a', // àáâäå
    0xE7: 'c', // ç
    0xE8: 'e', 0xE9: 'e', 0xEA: 'e', 0xEB: 'e', // èéêë
    0xEC: 'i', 0xED: 'i', 0xEE: 'i', 0xEF: 'i', // ìíîï
    0xF1: 'n', // ñ
    0xF2: 'o', 0xF3: 'o', 0xF4: 'o', 0xF6: 'o', // òóôö
    0xF9: 'u', 0xFA: 'u', 0xFB: 'u', 0xFC: 'u', // ùúûü
    0xFF: 'y', // ÿ
    0x153: 'oe', // œ
    0x2019: '\'', // ’
  };

  static const _entries = <Country>[
    Country._('AD', 'Andorre'),
    Country._('AE', 'Émirats arabes unis'),
    Country._('AF', 'Afghanistan'),
    Country._('AG', 'Antigua-et-Barbuda'),
    Country._('AI', 'Anguilla'),
    Country._('AL', 'Albanie'),
    Country._('AM', 'Arménie'),
    Country._('AO', 'Angola'),
    Country._('AQ', 'Antarctique'),
    Country._('AR', 'Argentine'),
    Country._('AS', 'Samoa américaines'),
    Country._('AT', 'Autriche'),
    Country._('AU', 'Australie'),
    Country._('AW', 'Aruba'),
    Country._('AX', 'Îles Åland'),
    Country._('AZ', 'Azerbaïdjan'),
    Country._('BA', 'Bosnie-Herzégovine'),
    Country._('BB', 'Barbade'),
    Country._('BD', 'Bangladesh'),
    Country._('BE', 'Belgique'),
    Country._('BF', 'Burkina Faso'),
    Country._('BG', 'Bulgarie'),
    Country._('BH', 'Bahreïn'),
    Country._('BI', 'Burundi'),
    Country._('BJ', 'Bénin'),
    Country._('BL', 'Saint-Barthélemy'),
    Country._('BM', 'Bermudes'),
    Country._('BN', 'Brunei'),
    Country._('BO', 'Bolivie'),
    Country._('BQ', 'Bonaire, Saint-Eustache et Saba'),
    Country._('BR', 'Brésil'),
    Country._('BS', 'Bahamas'),
    Country._('BT', 'Bhoutan'),
    Country._('BV', 'Île Bouvet'),
    Country._('BW', 'Botswana'),
    Country._('BY', 'Biélorussie'),
    Country._('BZ', 'Belize'),
    Country._('CA', 'Canada'),
    Country._('CC', 'Îles Cocos'),
    Country._('CD', 'République démocratique du Congo'),
    Country._('CF', 'République centrafricaine'),
    Country._('CG', 'Congo'),
    Country._('CH', 'Suisse'),
    Country._('CI', 'Côte d’Ivoire'),
    Country._('CK', 'Îles Cook'),
    Country._('CL', 'Chili'),
    Country._('CM', 'Cameroun'),
    Country._('CN', 'Chine'),
    Country._('CO', 'Colombie'),
    Country._('CR', 'Costa Rica'),
    Country._('CU', 'Cuba'),
    Country._('CV', 'Cap-Vert'),
    Country._('CW', 'Curaçao'),
    Country._('CX', 'Île Christmas'),
    Country._('CY', 'Chypre'),
    Country._('CZ', 'Tchéquie'),
    Country._('DE', 'Allemagne'),
    Country._('DJ', 'Djibouti'),
    Country._('DK', 'Danemark'),
    Country._('DM', 'Dominique'),
    Country._('DO', 'République dominicaine'),
    Country._('DZ', 'Algérie'),
    Country._('EC', 'Équateur'),
    Country._('EE', 'Estonie'),
    Country._('EG', 'Égypte'),
    Country._('EH', 'Sahara occidental'),
    Country._('ER', 'Érythrée'),
    Country._('ES', 'Espagne'),
    Country._('ET', 'Éthiopie'),
    Country._('FI', 'Finlande'),
    Country._('FJ', 'Fidji'),
    Country._('FK', 'Îles Malouines'),
    Country._('FM', 'Micronésie'),
    Country._('FO', 'Îles Féroé'),
    Country._('FR', 'France'),
    Country._('GA', 'Gabon'),
    Country._('GB', 'Royaume-Uni'),
    Country._('GD', 'Grenade'),
    Country._('GE', 'Géorgie'),
    Country._('GF', 'Guyane française'),
    Country._('GG', 'Guernesey'),
    Country._('GH', 'Ghana'),
    Country._('GI', 'Gibraltar'),
    Country._('GL', 'Groenland'),
    Country._('GM', 'Gambie'),
    Country._('GN', 'Guinée'),
    Country._('GP', 'Guadeloupe'),
    Country._('GQ', 'Guinée équatoriale'),
    Country._('GR', 'Grèce'),
    Country._('GS', 'Géorgie du Sud-et-les Îles Sandwich du Sud'),
    Country._('GT', 'Guatemala'),
    Country._('GU', 'Guam'),
    Country._('GW', 'Guinée-Bissau'),
    Country._('GY', 'Guyana'),
    Country._('HK', 'Hong Kong'),
    Country._('HM', 'Îles Heard-et-MacDonald'),
    Country._('HN', 'Honduras'),
    Country._('HR', 'Croatie'),
    Country._('HT', 'Haïti'),
    Country._('HU', 'Hongrie'),
    Country._('ID', 'Indonésie'),
    Country._('IE', 'Irlande'),
    Country._('IL', 'Israël'),
    Country._('IM', 'Île de Man'),
    Country._('IN', 'Inde'),
    Country._('IO', 'Territoire britannique de l’océan Indien'),
    Country._('IQ', 'Irak'),
    Country._('IR', 'Iran'),
    Country._('IS', 'Islande'),
    Country._('IT', 'Italie'),
    Country._('JE', 'Jersey'),
    Country._('JM', 'Jamaïque'),
    Country._('JO', 'Jordanie'),
    Country._('JP', 'Japon'),
    Country._('KE', 'Kenya'),
    Country._('KG', 'Kirghizistan'),
    Country._('KH', 'Cambodge'),
    Country._('KI', 'Kiribati'),
    Country._('KM', 'Comores'),
    Country._('KN', 'Saint-Christophe-et-Niévès'),
    Country._('KP', 'Corée du Nord'),
    Country._('KR', 'Corée du Sud'),
    Country._('KW', 'Koweït'),
    Country._('KY', 'Îles Caïmans'),
    Country._('KZ', 'Kazakhstan'),
    Country._('LA', 'Laos'),
    Country._('LB', 'Liban'),
    Country._('LC', 'Sainte-Lucie'),
    Country._('LI', 'Liechtenstein'),
    Country._('LK', 'Sri Lanka'),
    Country._('LR', 'Liberia'),
    Country._('LS', 'Lesotho'),
    Country._('LT', 'Lituanie'),
    Country._('LU', 'Luxembourg'),
    Country._('LV', 'Lettonie'),
    Country._('LY', 'Libye'),
    Country._('MA', 'Maroc'),
    Country._('MC', 'Monaco'),
    Country._('MD', 'Moldavie'),
    Country._('ME', 'Monténégro'),
    Country._('MF', 'Saint-Martin (partie française)'),
    Country._('MG', 'Madagascar'),
    Country._('MH', 'Îles Marshall'),
    Country._('MK', 'Macédoine du Nord'),
    Country._('ML', 'Mali'),
    Country._('MM', 'Myanmar (Birmanie)'),
    Country._('MN', 'Mongolie'),
    Country._('MO', 'Macao'),
    Country._('MP', 'Îles Mariannes du Nord'),
    Country._('MQ', 'Martinique'),
    Country._('MR', 'Mauritanie'),
    Country._('MS', 'Montserrat'),
    Country._('MT', 'Malte'),
    Country._('MU', 'Maurice'),
    Country._('MV', 'Maldives'),
    Country._('MW', 'Malawi'),
    Country._('MX', 'Mexique'),
    Country._('MY', 'Malaisie'),
    Country._('MZ', 'Mozambique'),
    Country._('NA', 'Namibie'),
    Country._('NC', 'Nouvelle-Calédonie'),
    Country._('NE', 'Niger'),
    Country._('NF', 'Île Norfolk'),
    Country._('NG', 'Nigeria'),
    Country._('NI', 'Nicaragua'),
    Country._('NL', 'Pays-Bas'),
    Country._('NO', 'Norvège'),
    Country._('NP', 'Népal'),
    Country._('NR', 'Nauru'),
    Country._('NU', 'Niue'),
    Country._('NZ', 'Nouvelle-Zélande'),
    Country._('OM', 'Oman'),
    Country._('PA', 'Panama'),
    Country._('PE', 'Pérou'),
    Country._('PF', 'Polynésie française'),
    Country._('PG', 'Papouasie-Nouvelle-Guinée'),
    Country._('PH', 'Philippines'),
    Country._('PK', 'Pakistan'),
    Country._('PL', 'Pologne'),
    Country._('PM', 'Saint-Pierre-et-Miquelon'),
    Country._('PN', 'Îles Pitcairn'),
    Country._('PR', 'Porto Rico'),
    Country._('PS', 'Palestine'),
    Country._('PT', 'Portugal'),
    Country._('PW', 'Palaos'),
    Country._('PY', 'Paraguay'),
    Country._('QA', 'Qatar'),
    Country._('RE', 'La Réunion'),
    Country._('RO', 'Roumanie'),
    Country._('RS', 'Serbie'),
    Country._('RU', 'Russie'),
    Country._('RW', 'Rwanda'),
    Country._('SA', 'Arabie saoudite'),
    Country._('SB', 'Îles Salomon'),
    Country._('SC', 'Seychelles'),
    Country._('SD', 'Soudan'),
    Country._('SE', 'Suède'),
    Country._('SG', 'Singapour'),
    Country._('SH', 'Sainte-Hélène, Ascension et Tristan da Cunha'),
    Country._('SI', 'Slovénie'),
    Country._('SJ', 'Svalbard et Jan Mayen'),
    Country._('SK', 'Slovaquie'),
    Country._('SL', 'Sierra Leone'),
    Country._('SM', 'Saint-Marin'),
    Country._('SN', 'Sénégal'),
    Country._('SO', 'Somalie'),
    Country._('SR', 'Suriname'),
    Country._('SS', 'Soudan du Sud'),
    Country._('ST', 'Sao Tomé-et-Principe'),
    Country._('SV', 'Salvador'),
    Country._('SX', 'Saint-Martin (partie néerlandaise)'),
    Country._('SY', 'Syrie'),
    Country._('SZ', 'Eswatini'),
    Country._('TC', 'Îles Turques-et-Caïques'),
    Country._('TD', 'Tchad'),
    Country._('TF', 'Terres australes françaises'),
    Country._('TG', 'Togo'),
    Country._('TH', 'Thaïlande'),
    Country._('TJ', 'Tadjikistan'),
    Country._('TK', 'Tokelau'),
    Country._('TL', 'Timor oriental'),
    Country._('TM', 'Turkménistan'),
    Country._('TN', 'Tunisie'),
    Country._('TO', 'Tonga'),
    Country._('TR', 'Turquie'),
    Country._('TT', 'Trinité-et-Tobago'),
    Country._('TV', 'Tuvalu'),
    Country._('TW', 'Taïwan'),
    Country._('TZ', 'Tanzanie'),
    Country._('UA', 'Ukraine'),
    Country._('UG', 'Ouganda'),
    Country._('UM', 'Îles mineures éloignées des États-Unis'),
    Country._('US', 'États-Unis'),
    Country._('UY', 'Uruguay'),
    Country._('UZ', 'Ouzbékistan'),
    Country._('VA', 'Vatican'),
    Country._('VC', 'Saint-Vincent-et-les-Grenadines'),
    Country._('VE', 'Venezuela'),
    Country._('VG', 'Îles Vierges britanniques'),
    Country._('VI', 'Îles Vierges des États-Unis'),
    Country._('VN', 'Viêt Nam'),
    Country._('VU', 'Vanuatu'),
    Country._('WF', 'Wallis-et-Futuna'),
    Country._('WS', 'Samoa'),
    Country._('YE', 'Yémen'),
    Country._('YT', 'Mayotte'),
    Country._('ZA', 'Afrique du Sud'),
    Country._('ZM', 'Zambie'),
    Country._('ZW', 'Zimbabwe'),
  ];
}
