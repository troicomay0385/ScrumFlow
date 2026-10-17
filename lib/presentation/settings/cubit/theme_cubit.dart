import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  static const String _prefThemeKey = 'scrumflow_theme_mode';

  ThemeCubit() : super(const ThemeState()) {
    loadTheme();
  }

  /// Tải trạng thái Theme từ SharedPreferences
  Future<void> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_prefThemeKey);

      if (savedMode == 'dark') {
        emit(state.copyWith(themeMode: ThemeMode.dark));
      } else if (savedMode == 'light') {
        emit(state.copyWith(themeMode: ThemeMode.light));
      } else if (savedMode == 'system') {
        emit(state.copyWith(themeMode: ThemeMode.system));
      } else {
        // Mặc định là light nếu chưa thiết lập
        emit(state.copyWith(themeMode: ThemeMode.light));
      }
    } catch (_) {
      // Fallback về default light nếu có lỗi truy cập prefs
      emit(state.copyWith(themeMode: ThemeMode.light));
    }
  }

  /// Cập nhật và lưu ThemeMode vào SharedPreferences
  Future<void> setThemeMode(ThemeMode mode) async {
    emit(state.copyWith(themeMode: mode));
    try {
      final prefs = await SharedPreferences.getInstance();
      String modeStr;
      switch (mode) {
        case ThemeMode.dark:
          modeStr = 'dark';
          break;
        case ThemeMode.light:
          modeStr = 'light';
          break;
        case ThemeMode.system:
          modeStr = 'system';
          break;
      }
      await prefs.setString(_prefThemeKey, modeStr);
    } catch (_) {}
  }

  /// Bật/tắt nhanh giữa Light và Dark
  Future<void> toggleTheme([BuildContext? context]) async {
    final currentIsDark = (context != null)
        ? state.isDark(context)
        : (state.themeMode == ThemeMode.dark);

    final nextMode = currentIsDark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(nextMode);
  }
}
