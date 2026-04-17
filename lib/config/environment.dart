import 'package:shared_preferences/shared_preferences.dart';

enum EnvironmentType { development, staging, production }

class Environment {
  static EnvironmentType _environment = EnvironmentType.development;
  static const String _apiUrlKey = 'api_base_url';
  static const String _defaultUrl = 'http://localhost:3000/api/v1';
  static String _cachedUrl = '';

  static void initialize() {
    _environment = EnvironmentType.development;
    _loadCachedUrl();
  }

  static Future<void> _loadCachedUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedUrl = prefs.getString(_apiUrlKey) ?? _defaultUrl;
    } catch (e) {
      _cachedUrl = _defaultUrl;
    }
  }

  static String get baseUrl => _cachedUrl.isNotEmpty ? _cachedUrl : _defaultUrl;

  static EnvironmentType get current => _environment;
  static bool get isDevelopment => _environment == EnvironmentType.development;
  static bool get isStaging => _environment == EnvironmentType.staging;
  static bool get isProduction => _environment == EnvironmentType.production;

  static Future<void> refreshBaseUrl() async {
    await _loadCachedUrl();
  }
}
