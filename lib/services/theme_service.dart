import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// ThemeService manages the app's theme mode (Light, Dark, System)
/// with reactive updates via [themeModeNotifier] and secure persistent storage.
class ThemeService {
  ThemeService._();
  static final ThemeService instance = ThemeService._();

  static const String _storageKey = 'mymechanic_theme_mode';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  ThemeMode get themeMode => themeModeNotifier.value;
  bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  /// Load persisted theme preference on app startup
  Future<void> init() async {
    try {
      final savedMode = await _storage.read(key: _storageKey);
      if (savedMode != null) {
        switch (savedMode) {
          case 'dark':
            themeModeNotifier.value = ThemeMode.dark;
            break;
          case 'light':
            themeModeNotifier.value = ThemeMode.light;
            break;
          case 'system':
            themeModeNotifier.value = ThemeMode.system;
            break;
        }
      }
    } catch (_) {
      // Graceful fallback to default light mode if secure storage fails
    }
  }

  /// Update theme mode and save to persistent storage
  Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    try {
      final modeStr = mode == ThemeMode.dark
          ? 'dark'
          : (mode == ThemeMode.light ? 'light' : 'system');
      await _storage.write(key: _storageKey, value: modeStr);
    } catch (_) {}
  }

  /// Toggle between light and dark mode
  void toggleDarkMode() {
    if (isDarkMode) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }

  /// Reset theme mode for unit testing
  @visibleForTesting
  void resetForTesting([ThemeMode mode = ThemeMode.light]) {
    themeModeNotifier.value = mode;
  }
}
