import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:service_app/providers/auth_provider.dart';
import 'package:service_app/providers/theme_provider.dart';
import 'package:service_app/screens/root_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Service App',
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.systemThemeMode,
          home: RootScreen(),
        );
      },
    );
  }
}