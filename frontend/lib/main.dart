import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Edge to edge + transparent bars
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const NutriFlexApp());
}

class NutriFlexApp extends StatelessWidget {
  const NutriFlexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriFlex',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000302),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
          primary: const Color(0xFF00E676),
          secondary: const Color(0xFF69F0AE),
          surface: const Color(0xFF103E23),
        ),
        useMaterial3: true,
      ),
      // Splash is always the entry point
      home: const SplashScreen(),

      // Routes navigated to after splash
      routes: {
        '/onboarding': (context) => const Scaffold(
              body: Center(
                child: Text(
                  'Onboarding Screen',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
        '/login': (context) => const Scaffold(
              body: Center(
                child: Text(
                  'Login Screen',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
        '/home': (context) => const MainShell(),
      },
    );
  }
}