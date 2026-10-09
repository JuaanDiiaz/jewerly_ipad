import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:p_a_jewerly/theme/app_theme.dart';

/// Persists the app's appearance mode (System / Light / Dark) and keeps
/// [AppTheme.isDark] in sync so the adaptive color getters follow.
class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';

  ThemeMode _mode = ThemeMode.system;
  bool _isInitialized = false;
  bool _platformIsDark = false;

  ThemeMode get mode => _mode;
  bool get isInitialized => _isInitialized;

  ThemeProvider() {
    _platformIsDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    _loadFromStorage();
  }

  /// Called from [WidgetsBindingObserver.didChangePlatformBrightness] flows —
  /// only relevant while in System mode.
  void updatePlatformBrightness(Brightness brightness) {
    _platformIsDark = brightness == Brightness.dark;
    _syncAppTheme();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_themeModeKey);
      if (stored != null) {
        _mode = ThemeMode.values.firstWhere(
          (m) => m.name == stored,
          orElse: () => ThemeMode.system,
        );
      }
    } catch (e) {
      _mode = ThemeMode.system;
    }
    _syncAppTheme();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode newMode) async {
    if (_mode == newMode) return;
    _mode = newMode;
    _syncAppTheme();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, newMode.name);
    } catch (_) {
      // Persistence failure is non-fatal: the mode still applies this run.
    }
  }

  void _syncAppTheme() {
    final effectiveDark = switch (_mode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => _platformIsDark,
    };
    AppTheme.setDarkMode(effectiveDark);
  }
}