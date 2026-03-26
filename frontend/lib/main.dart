import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'services/firebase_options.dart';
import 'services/calorie_provider_service.dart';
import 'services/cart_provider.dart';
import 'screens/login_page.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding.dart';
import 'main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CalorieProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'NutriFlex',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF000302),
          fontFamily: 'Roboto',
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.dark,
            primary: const Color(0xFF00E676),
            secondary: const Color(0xFF69F0AE),
            surface: const Color(0xFF103E23),
          ),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
        routes: {
          '/auth':       (context) => const LoginPage(),
          '/onboarding': (context) => const WelcomeScreen(),
          '/home':       (context) => const MainShell(),
        },
      ),
    );
  }
}