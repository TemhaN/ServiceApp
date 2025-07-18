import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeModeType { light, dark, system }

class ThemeProvider with ChangeNotifier {
  ThemeModeType _themeMode = ThemeModeType.system;
  static const String _themeKey = 'theme_mode';

  ThemeProvider() {
    _loadTheme();
  }

  ThemeModeType get themeMode => _themeMode;

  ThemeData get lightTheme => ThemeData(
    primaryColor: Color(0xFF7B3BEA),
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: MaterialColor(0xFF7B3BEA, {
        50: Color(0xFFF3EFFE),
        100: Color(0xFFE0D7FD),
        200: Color(0xFFC6B0FB),
        300: Color(0xFFA989F9),
        400: Color(0xFF956AF7),
        500: Color(0xFF7B3BEA),
        600: Color(0xFF6F33D1),
        700: Color(0xFF5E2AB2),
        800: Color(0xFF4C2292),
        900: Color(0xFF3B1A73),
      }),
    ).copyWith(
      primary: Color(0xFF7B3BEA),
      secondary: Color(0xFFF425FF),
      background: Color(0xFFF8F7FC),
      surface: Colors.white,
      onSurface: Color(0xFF1A1A1A),
      onBackground: Color(0xFF1A1A1A),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Color(0xFFF8F7FC),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF7B3BEA),
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF7B3BEA),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Color(0xFF7B3BEA)),
      ),
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(color: Color(0xFF1A1A1A)),
      bodyMedium: TextStyle(color: Color(0xFF1A1A1A)),
      bodySmall: TextStyle(color: Color(0xFFB0B0B0)),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 4,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFFF8F7FC).withOpacity(0.9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: Color(0xFF7B3BEA).withOpacity(0.3),
          width: 0.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: Color(0xFF7B3BEA),
          width: 1,
        ),
      ),
      labelStyle: TextStyle(
        fontFamily: 'Roboto',
        color: Color(0xFFB0B0B0),
      ),
    ),
  );

  ThemeData get darkTheme => ThemeData(
    primaryColor: Color(0xFF7B3BEA),
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: MaterialColor(0xFF7B3BEA, {
        50: Color(0xFFF3EFFE),
        100: Color(0xFFE0D7FD),
        200: Color(0xFFC6B0FB),
        300: Color(0xFFA989F9),
        400: Color(0xFF956AF7),
        500: Color(0xFF7B3BEA),
        600: Color(0xFF6F33D1),
        700: Color(0xFF5E2AB2),
        800: Color(0xFF4C2292),
        900: Color(0xFF3B1A73),
      }),
    ).copyWith(
      primary: Color(0xFF7B3BEA),
      secondary: Color(0xFFF425FF),
      background: Colors.grey[900]!,
      surface: Colors.grey[800]!,
      onSurface: Colors.white,
      onBackground: Colors.white70,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: Colors.grey[900],
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF7B3BEA),
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF7B3BEA),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Color(0xFFF425FF)),
      ),
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
      bodySmall: TextStyle(color: Colors.white60),
    ),
    cardTheme: CardThemeData(
      color: Colors.grey[800],
      elevation: 4,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[800]!.withOpacity(0.9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: Color(0xFFF425FF).withOpacity(0.3),
          width: 0.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: Color(0xFFF425FF),
          width: 1,
        ),
      ),
      labelStyle: TextStyle(
        fontFamily: 'Roboto',
        color: Colors.white60,
      ),
    ),
  );

  void setTheme(ThemeModeType mode) async {
    _themeMode = mode;
    print('Theme set to: $mode');
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.toString());
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey) ?? ThemeModeType.system.toString();
    _themeMode = ThemeModeType.values.firstWhere(
          (e) => e.toString() == themeString,
      orElse: () => ThemeModeType.system,
    );
    notifyListeners();
  }

  ThemeMode get systemThemeMode {
    switch (_themeMode) {
      case ThemeModeType.light:
        return ThemeMode.light;
      case ThemeModeType.dark:
        return ThemeMode.dark;
      case ThemeModeType.system:
        return ThemeMode.system;
    }
  }
}