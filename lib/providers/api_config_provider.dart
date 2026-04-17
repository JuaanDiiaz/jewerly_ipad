import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:p_a_jewerly/config/environment.dart';

class ApiConfigProvider extends ChangeNotifier {
  static const String _apiUrlKey = 'api_base_url';
  static const String _defaultUrl = 'http://localhost:3000/api/v1';

  String _apiUrl = _defaultUrl;
  bool _isInitialized = false;

  String get apiUrl => _apiUrl;
  bool get isInitialized => _isInitialized;

  ApiConfigProvider() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _apiUrl = prefs.getString(_apiUrlKey) ?? _defaultUrl;
      // Also update the Environment's cached URL
      await Environment.refreshBaseUrl();
    } catch (e) {
      _apiUrl = _defaultUrl;
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> setApiUrl(String url) async {
    if (url.isEmpty) return false;

    final trimmed = url.trim();
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_apiUrlKey, trimmed);
      _apiUrl = trimmed;
      // Also update the Environment's cached URL
      await Environment.refreshBaseUrl();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> resetToDefault() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_apiUrlKey);
      _apiUrl = _defaultUrl;
      await Environment.refreshBaseUrl();
      notifyListeners();
    } catch (e) {
      // ignore
    }
  }

  String get baseUrl => _apiUrl;
}
