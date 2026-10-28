enum AppEnvironment {
  development,
  production;

  static AppEnvironment fromCompileTime() {
    const value = String.fromEnvironment('APP_ENV', defaultValue: 'dev');

    return switch (value) {
      'dev' => AppEnvironment.development,
      'prod' => AppEnvironment.production,
      _ => throw ArgumentError.value(
        value,
        'APP_ENV',
        'Valeurs acceptées : dev, prod.',
      ),
    };
  }

  bool get isDevelopment => this == AppEnvironment.development;
}
