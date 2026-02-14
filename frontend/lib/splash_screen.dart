import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Optional: make status bar look nicer on splash
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0A1F1C), // very dark green/teal black
        fontFamily: 'Roboto', // or your custom font
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // You can add navigation after 3–4 seconds here
    // Example:
    // Future.delayed(const Duration(seconds: 4), () {
    //   Navigator.of(context).pushReplacement(
    //     MaterialPageRoute(builder: (_) => const HomeScreen()),
    //   );
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF1A3C36), // slightly lighter dark bg for logo
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.25),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.restaurant_menu, // You should replace with your real logo
                size: 70,
                color: Color(0xFF39FF14), // bright neon green
              ),
            ),

            const SizedBox(height: 40),

            // App name
            const Text(
              'NutriFlex',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 8),

            // Tagline
            const Text(
              'Premium Smart Meal Prep',
              style: TextStyle(
                fontSize: 20,
                color: Color(0xFF90FFA6), // light mint-green
                fontWeight: FontWeight.w500,
                letterSpacing: 0.8,
              ),
            ),

            const SizedBox(height: 60),

            // Loading indicator
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF39FF14)),
                strokeWidth: 3.5,
              ),
            ),

            const SizedBox(height: 100),

            // Team / footer text (small & subtle)
            const Text(
              '~ Team Nutrition Navigators',
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF5C8C7A),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

