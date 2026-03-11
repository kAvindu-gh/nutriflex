import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'firebase_options.dart';
//import 'screens/login_page.dart';
import 'main_shell.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Force portrait mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Edge to edge + transparent bars
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

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
      routes: {
        '/home': (context) => const _AuthGate(),
      },
    );
  }
}

// ── Auth gate — after splash, decides where to send the user ─────────────────
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        final user = snapshot.data;

        // Logged in + email verified → go to home
        if (user != null && user.emailVerified) {
          return const MainShell();
        }

        // Not logged in → show login
        return const LoginPage();
      },
    );
  }
}

// ── Brief loading screen while auth state is checked ─────────────────────────
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D2818),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF14D97D),
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}