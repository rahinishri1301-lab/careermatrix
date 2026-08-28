import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'data/app_state.dart';
import 'screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Restore the persisted dark-mode preference before the first frame so
  // the app opens in the theme the user last chose (see AppState.themeMode).
  await AppState.instance.loadThemePreference();
  runApp(const CareerMatrixApp());
}

class CareerMatrixApp extends StatelessWidget {
  const CareerMatrixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppState.instance.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Career Matrix',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
