// ENHANCED: Theme provider with better state management and customization
import 'package:flutter/material.dart';
import '../services/theme_service.dart';

class ThemeProvider with ChangeNotifier {
  final ThemeService _themeService = ThemeService();
  bool _isDarkMode = false;
  bool _isInitialized = false;
  Color _accentColor = Colors.indigo;

  ThemeProvider() {
    _loadTheme();
  }

  // Getters
  bool get isDarkMode => _isDarkMode;
  bool get isInitialized => _isInitialized;
  Color get accentColor => _accentColor;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  ThemeData get lightTheme => _themeService.getLightTheme(_accentColor);
  ThemeData get darkTheme => _themeService.getDarkTheme(_accentColor);

  // Load saved theme preference and accent color
  Future<void> _loadTheme() async {
    try {
      _isDarkMode = await _themeService.isDarkMode();
      _accentColor = await _themeService.getAccentColor();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error loading theme: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Toggle between light and dark theme
  Future<void> toggleTheme() async {
    try {
      _isDarkMode = !_isDarkMode;
      await _themeService.setDarkMode(_isDarkMode);
      notifyListeners();
    } catch (e) {
      print('Error toggling theme: $e');
      // Revert the change if saving failed
      _isDarkMode = !_isDarkMode;
      notifyListeners();
    }
  }

  // Set dark mode explicitly
  Future<void> setDarkMode(bool isDark) async {
    if (_isDarkMode == isDark) return;

    try {
      _isDarkMode = isDark;
      await _themeService.setDarkMode(_isDarkMode);
      notifyListeners();
    } catch (e) {
      print('Error setting dark mode: $e');
      // Revert the change if saving failed
      _isDarkMode = !isDark;
      notifyListeners();
    }
  }

  // Set accent color
  Future<void> setAccentColor(Color color) async {
    if (_accentColor == color) return;

    try {
      _accentColor = color;
      await _themeService.setAccentColor(_accentColor);
      notifyListeners();
    } catch (e) {
      print('Error setting accent color: $e');
      // Revert the change if saving failed
      _accentColor = Colors.indigo;
      notifyListeners();
    }
  }

  // Apply theme preset
  Future<void> applyThemePreset(ThemePreset preset) async {
    try {
      _accentColor = preset.color;
      await _themeService.setAccentColor(_accentColor);
      notifyListeners();
    } catch (e) {
      print('Error applying theme preset: $e');
    }
  }

  // Get current theme data
  ThemeData getCurrentTheme() {
    return _isDarkMode ? darkTheme : lightTheme;
  }

  // Reset to default theme
  Future<void> resetToDefault() async {
    try {
      _isDarkMode = false;
      _accentColor = Colors.indigo;
      await _themeService.setDarkMode(_isDarkMode);
      await _themeService.setAccentColor(_accentColor);
      notifyListeners();
    } catch (e) {
      print('Error resetting theme: $e');
    }
  }

  // Get available accent colors
  List<Color> getAvailableAccentColors() {
    return ThemeService.getAccentColors();
  }

  // Get theme presets
  List<ThemePreset> getThemePresets() {
    return ThemeService.getThemePresets();
  }

  // Check if current theme is using a preset
  ThemePreset? getCurrentPreset() {
    final presets = getThemePresets();
    return presets.firstWhere(
      (preset) => preset.color.value == _accentColor.value,
      orElse: () => ThemePreset('Custom', _accentColor, 'Custom color theme'),
    );
  }

  // Get theme brightness description
  String get brightnessDescription => _isDarkMode ? 'Dark' : 'Light';

  // Get accent color name
  String get accentColorName {
    final colors = {
      Colors.indigo.value: 'Indigo',
      Colors.blue.value: 'Blue',
      Colors.purple.value: 'Purple',
      Colors.teal.value: 'Teal',
      Colors.green.value: 'Green',
      Colors.orange.value: 'Orange',
      Colors.red.value: 'Red',
      Colors.pink.value: 'Pink',
      Colors.cyan.value: 'Cyan',
      Colors.amber.value: 'Amber',
    };
    return colors[_accentColor.value] ?? 'Custom';
  }

  // Animate theme change (for UI feedback)
  bool _isChangingTheme = false;
  bool get isChangingTheme => _isChangingTheme;

  Future<void> animatedToggleTheme() async {
    _isChangingTheme = true;
    notifyListeners();

    await toggleTheme();

    // Add a small delay for animation
    await Future.delayed(Duration(milliseconds: 300));

    _isChangingTheme = false;
    notifyListeners();
  }
}
