import 'package:flutter/material.dart';
import 'home_page.dart';
// import 'signup_page.dart'; // uncomment if signup exists

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nutriflex',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomePage(),
      // OR if signup should come first:
      // home: const SignUpPage(),
    );
  }
}
