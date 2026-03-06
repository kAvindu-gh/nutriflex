// Splash screen updating old code
import 'dart:math' as math;
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
  with TickerProviderStateMixin {
    late AnimationController _logoController;
    late AnimationController _textController;
    late AnimationController _pulseController;
    late AnimationController _glowController;
    late AnimationController _particleController;
    late AnimationController _ringController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoGlowRadius;
  late Animation<Offset>  _titleSlide;
  late Animation<double>  _titleOpacity;
  late Animation<Offset>  _subtitleSlide;
  late Animation<double>  _subtitleOpacity;
  late Animation<double>  _pulseScale;
  late Animation<double>  _glowIntensity;
  late Animation<double>  _teamOpacity;
  late Animation<double>  _teamSlide;
  late Animation<double>  _ringProgress;

  static const Color _bg0       = Color(0xFF030303);
  static const Color _bg1       = Color(0xFF103E23);
  static const Color _bg2       = Color(0xFF000000);
  static const Color _green     = Color(0xFF00E676);
  static const Color _greenDim  = Color(0xFF00C853);
  static const Color _greenGlow = Color(0xFF69F0AE);

  // Splash animation setup 
  // Splash screen animation foundation,
