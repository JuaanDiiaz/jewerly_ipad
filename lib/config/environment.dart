import 'package:flutter_dotenv/flutter_dotenv.dart';

enum EnvironmentType { development, staging, production }

class Environment {
  static EnvironmentType _environment = EnvironmentType.development;
  static String _baseUrl = '';

  static void initialize() {
    final envValue = dotenv.env['ENVIRONMENT'] ?? 'development';
    _environment = EnvironmentType.values.firstWhere(
      (e) => e.name == envValue,
      orElse: () => EnvironmentType.development,
    );
    _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api/v1';
  }

  static EnvironmentType get current => _environment;

  static String get baseUrl => _baseUrl;

  static bool get isDevelopment => _environment == EnvironmentType.development;
  static bool get isStaging => _environment == EnvironmentType.staging;
  static bool get isProduction => _environment == EnvironmentType.production;
}
