import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeService {
  ThemeService(this._storage) {
    _isDarkMode.value = _storage.read<bool>(_key) ?? false; // Default to Light Mode
  }

  final GetStorage _storage;
  static const _key = 'is_dark_mode';

  final _isDarkMode = true.obs;

  /// Get the active theme mode from storage
  ThemeMode get theme => _isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  /// Check if the active theme is Dark Mode
  bool get isDarkMode => _isDarkMode.value;

  /// Save the theme mode preference
  Future<void> _saveTheme(bool isDark) async {
    await _storage.write(_key, isDark);
    _isDarkMode.value = isDark;
  }

  /// Toggle and switch theme dynamically
  Future<void> toggleTheme() async {
    final newIsDark = !_isDarkMode.value;
    Get.changeThemeMode(newIsDark ? ThemeMode.dark : ThemeMode.light);
    await _saveTheme(newIsDark);
  }
}
