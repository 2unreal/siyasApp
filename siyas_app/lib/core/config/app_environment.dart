enum AppEnvironment {
  dev,
  prod,
}

class AppConfig {
  final AppEnvironment environment;
  final String appTitle;
  final String projectId;
  final String storageBucket;

  const AppConfig({
    required this.environment,
    required this.appTitle,
    required this.projectId,
    required this.storageBucket,
  });

  bool get isDev => environment == AppEnvironment.dev;
  bool get isProd => environment == AppEnvironment.prod;

  static AppConfig? _current;
  static AppConfig get current => _current ?? _defaultConfig;

  static const AppConfig _defaultConfig = AppConfig(
    environment: AppEnvironment.dev,
    appTitle: "House of SIYA's [DEV]",
    projectId: 'siyasapp-dev-509309',
    storageBucket: 'siyasapp-dev-509309.firebasestorage.app',
  );

  static void initialize(AppEnvironment env) {
    switch (env) {
      case AppEnvironment.dev:
        _current = const AppConfig(
          environment: AppEnvironment.dev,
          appTitle: "House of SIYA's [DEV]",
          projectId: 'siyasapp-dev-509309',
          storageBucket: 'siyasapp-dev-509309.firebasestorage.app',
        );
        break;
      case AppEnvironment.prod:
        _current = const AppConfig(
          environment: AppEnvironment.prod,
          appTitle: "House of SIYA's",
          projectId: 'siyasapp-509309',
          storageBucket: 'siyasapp-509309.firebasestorage.app',
        );
        break;
    }
  }
}
