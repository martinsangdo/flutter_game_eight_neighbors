// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/game_models.dart';
import 'screens/loading_splash_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/game_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const EightNeighborsApp());
}

class EightNeighborsApp extends StatelessWidget {
  const EightNeighborsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eight Neighbors',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF000033),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6B46C1),
          secondary: Color(0xFF3B82F6),
        ),
      ),
      home: const _AppNavigator(),
    );
  }
}

class _AppNavigator extends StatefulWidget {
  const _AppNavigator();

  @override
  State<_AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<_AppNavigator> {
  bool _loading = true;
  AppScreen _screen = AppScreen.splash;
  GameSettings _settings = GameSettings();

  void _goToGame() => setState(() => _screen = AppScreen.playing);
  void _goToSplash() => setState(() => _screen = AppScreen.splash);
  void _goToSettings() => setState(() => _screen = AppScreen.settings);

  void _saveSettings(GameSettings s) => setState(() => _settings = s);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return LoadingSplashScreen(
        key: const ValueKey('loading'),
        onDone: () => setState(() => _loading = false),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: switch (_screen) {
        AppScreen.splash => SplashScreen(
            key: const ValueKey('splash'),
            onStartGame: _goToGame,
            onSettings: _goToSettings,
          ),
        AppScreen.settings => SettingsScreen(
            key: const ValueKey('settings'),
            settings: _settings,
            onSave: _saveSettings,
            onBack: _goToSplash,
          ),
        AppScreen.playing => GameScreen(
            key: const ValueKey('game'),
            settings: _settings,
            onExitToMenu: _goToSplash,
            onUpdateSettings: _saveSettings,
          ),
      },
    );
  }
}

