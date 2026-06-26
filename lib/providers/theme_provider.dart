import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(_storedMode());

  static const _boxName = 'app_preferences';
  static const _key = 'theme_mode';

  static ThemeMode _storedMode() {
    if (!Hive.isBoxOpen(_boxName)) return ThemeMode.system;
    final value = Hive.box<dynamic>(_boxName).get(_key) as String?;
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    if (Hive.isBoxOpen(_boxName)) {
      await Hive.box<dynamic>(_boxName).put(_key, mode.name);
    }
  }

  Future<void> toggle(Brightness brightness) {
    return setMode(
      brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (_) => ThemeModeNotifier(),
);
