class AppConstants {
  AppConstants._();

  static const String appName = 'GlicoBolus';
  static const String appSubtitle = 'Calculadora Pessoal de Bolus de Insulina';
  static const String appVersion = '1.0.0';

  // Configurações padrão
  static const String defaultGlucoseUnit = 'mg/dL';
  static const double defaultTargetMin = 80.0;
  static const double defaultTargetMax = 120.0;
  static const double defaultInsulinSensitivity = 50.0;
  static const double defaultCarbohydrateRatio = 12.0;
  static const double defaultInsulinIncrement = 0.1;
  static const double defaultMaxBolus = 10.0;
}
