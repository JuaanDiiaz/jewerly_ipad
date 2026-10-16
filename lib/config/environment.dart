import 'package:shared_preferences/shared_preferences.dart';

enum EnvironmentType { development, staging, production }

class Environment {
  static EnvironmentType _environment = EnvironmentType.development;
  static const String _apiUrlKey = 'api_base_url';

  /// Shared default base URL (matches the ASP.NET backend running locally,
  /// i.e. .env's API_BASE_URL). Public so display-only consumers — e.g.
  /// ApiConfigProvider's Settings screen — show the same value requests use.
  static const String defaultApiUrl = 'http://localhost:5259/api';
  static String _cachedUrl = '';

  static void initialize() {
    _environment = EnvironmentType.development;
    _loadCachedUrl();
  }

  static Future<void> _loadCachedUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedUrl = prefs.getString(_apiUrlKey) ?? defaultApiUrl;
    } catch (e) {
      _cachedUrl = defaultApiUrl;
    }
  }

  static String get baseUrl => _cachedUrl.isNotEmpty ? _cachedUrl : defaultApiUrl;

  static EnvironmentType get current => _environment;
  static bool get isDevelopment => _environment == EnvironmentType.development;
  static bool get isStaging => _environment == EnvironmentType.staging;
  static bool get isProduction => _environment == EnvironmentType.production;

  static Future<void> refreshBaseUrl() async {
    await _loadCachedUrl();
  }
}
