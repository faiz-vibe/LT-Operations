import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

// App ki theme mode (Light/Dark)
enum AppThemeMode { light, dark }

// App ka UI size
enum AppUiSize { small, medium, large }

class PreferencesService {
  static final ValueNotifier<AppThemeMode> themeMode = ValueNotifier(AppThemeMode.light);
  static final ValueNotifier<AppUiSize> uiSize = ValueNotifier(AppUiSize.medium);
  static final ValueNotifier<bool> desktopMode = ValueNotifier(false);

  // Hive se settings load karo
  static Future<void> init() async {
    await Hive.openBox('preferences');
    final box = Hive.box('preferences');
    themeMode.value = AppThemeMode.values[box.get('themeMode', defaultValue: 0)];
    uiSize.value = AppUiSize.values[box.get('uiSize', defaultValue: 1)];
    desktopMode.value = box.get('desktopMode', defaultValue: false);
  }

  // Theme save karo
  static void setThemeMode(AppThemeMode mode) {
    themeMode.value = mode;
    Hive.box('preferences').put('themeMode', mode.index);
  }

  // UI Size save karo
  static void setUiSize(AppUiSize size) {
    uiSize.value = size;
    Hive.box('preferences').put('uiSize', size.index);
  }

  // Desktop mode save karo
  static void setDesktopMode(bool value) {
    desktopMode.value = value;
    Hive.box('preferences').put('desktopMode', value);
  }

  // Font size UI size ke hisaab se return karo
  static double get scaleFactor {
    switch (uiSize.value) {
      case AppUiSize.small: return 0.85;
      case AppUiSize.medium: return 1.0;
      case AppUiSize.large: return 1.15;
    }
  }
}