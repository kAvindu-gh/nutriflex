import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {

  late AnimationController _logoCtrl, _textCtrl, _glowCtrl, _particleCtrl, _ringCtrl, _zoomCtrl;
  late Animation<double> _logoScale, _logoOpacity, _logoGlow, _titleOpacity, _subtitleOpacity,
      _glowIntensity, _teamOpacity, _teamSlide, _ringProgress, _zoomScale;
  late Animation<Offset> _titleSlide, _subtitleSlide;

  static const _bg0 = Color(0xFF030303);
  static const _bg1 = Color(0xFF103E23);
  static const _bg2 = Color(0xFF000000);
  static const _green = Color(0xFF00E676);
  static const _greenGlow = Color(0xFF69F0AE);

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _logoScale = Tween(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)));
    _logoGlow = Tween(begin: 0.0, end: 28.0).animate(CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.5, 1.0, curve: Curves.easeOut)));

    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _titleSlide = Tween(begin: const Offset(0, 0.6), end: Offset.zero).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));
    _titleOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _textCtrl, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)));
    _subtitleSlide = Tween(begin: const Offset(0, 0.8), end: Offset.zero).animate(CurvedAnimation(parent: _textCtrl, curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)));
    _subtitleOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _textCtrl, curve: const Interval(0.3, 0.9, curve: Curves.easeIn)));
    _teamOpacity = Tween(begin: 0.0, end: 0.65).animate(CurvedAnimation(parent: _textCtrl, curve: const Interval(0.6, 1.0, curve: Curves.easeIn)));
    _teamSlide = Tween(begin: 18.0, end: 0.0).animate(CurvedAnimation(parent: _textCtrl, curve: const Interval(0.5, 1.0, curve: Curves.easeOut)));

    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat(reverse: true);
    _glowIntensity = Tween(begin: 0.35, end: 1.0).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

    _ringCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
    _ringProgress = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.linear));

    _zoomCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _zoomScale = Tween(begin: 0.88, end: 1.08).animate(CurvedAnimation(parent: _zoomCtrl, curve: Curves.easeInOut));

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 650));
    _textCtrl.forward();

    // Wait for splash to finish
    await Future.delayed(const Duration(seconds: 5));
    if (!mounted) return;

    // Check Firebase Auth — no SharedPreferences needed
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && user.emailVerified) {
      // Already logged in → go to home
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // Not logged in → go to auth gate (login page)
      Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  @override
  void dispose() {
    for (final c in [_logoCtrl, _textCtrl, _glowCtrl, _particleCtrl, _ringCtrl, _zoomCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: _bg0,
      body: Stack(fit: StackFit.expand, children: [

        // Background gradient
        Container(decoration: const BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          stops: [0.0, 0.74, 1.0], colors: [_bg0, _bg1, _bg2],
        ))),

        // Radial glow
        AnimatedBuilder(animation: _glowCtrl, builder: (_, __) => Center(child: Container(
          width: size.width * 1.3, height: size.width * 1.3,
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(
            colors: [_bg1.withOpacity(0.5 * _glowIntensity.value), Colors.transparent],
          )),
        ))),

        // Particles
        AnimatedBuilder(animation: _particleCtrl, builder: (_, __) =>
          CustomPaint(painter: _ParticlePainter(progress: _particleCtrl.value, color: _green))),

        // Main content
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Spacer(flex: 2),

          // Logo + ring
          AnimatedBuilder(
            animation: Listenable.merge([_logoCtrl, _glowCtrl, _ringCtrl, _zoomCtrl]),
            builder: (_, __) => Transform.scale(
              scale: _logoScale.value,
              child: Opacity(
                opacity: _logoOpacity.value,
                child: SizedBox(width: 180, height: 180, child: Stack(alignment: Alignment.center, children: [

                  // Snake ring
                  CustomPaint(size: const Size(180, 180), painter: _SnakeRingPainter(
                    progress: _ringProgress.value, ringColor: _green,
                    glowColor: _greenGlow, glowIntensity: _glowIntensity.value,
                  )),

                  // Logo
                  Transform.scale(scale: _zoomScale.value, child: SizedBox(
                    width: 180, height: 180,
                    child: Image.asset(
                      'lib/assets/NutriFlex_Logo_1.jpeg',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.restaurant_menu, color: _green, size: 64),
                    ),
                  )),
                ])),
              ),
            ),
          ),

          const SizedBox(height: 36),

          // Title
          AnimatedBuilder(animation: _textCtrl, builder: (_, __) =>
            FractionalTranslation(translation: _titleSlide.value, child: Opacity(opacity: _titleOpacity.value,
              child: const Text('NutriFlex', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w300, color: Colors.white, letterSpacing: 1.5))))),

          const SizedBox(height: 8),

          // Subtitle
          AnimatedBuilder(animation: _textCtrl, builder: (_, __) =>
            FractionalTranslation(translation: _subtitleSlide.value, child: Opacity(opacity: _subtitleOpacity.value,
              child: const Text('Premium Smart Meal Prep', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _green, letterSpacing: 0.8))))),

          const Spacer(flex: 2),

          // Team label
          AnimatedBuilder(animation: _textCtrl, builder: (_, __) =>
            Transform.translate(offset: Offset(0, _teamSlide.value), child: Opacity(opacity: _teamOpacity.value,
              child: const Text('Team Nutrition Navigators', style: TextStyle(fontSize: 12, color: Colors.white, letterSpacing: 0.5))))),

          const SizedBox(height: 32),
        ]),
      ]),
    );
  }
}

// Snake ring
class _SnakeRingPainter extends CustomPainter {
  final double progress, glowIntensity;
  final Color ringColor, glowColor;
  const _SnakeRingPainter({required this.progress, required this.ringColor, required this.glowColor, required this.glowIntensity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final headAngle = 2 * math.pi * progress - math.pi / 2;
    const tailSweep = math.pi * 1.67;
    const segments = 80;
    final segAngle = tailSweep / segments;

    for (int i = 0; i < segments; i++) {
      final t = i / segments;
      final segStart = headAngle - tailSweep + i * segAngle;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), segStart, segAngle + 0.01, false,
        Paint()..color = glowColor.withOpacity(t * t * 0.3 * glowIntensity)..style = PaintingStyle.stroke..strokeWidth = (1.0 + t * 3.2) + 5..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), segStart, segAngle + 0.01, false,
        Paint()..color = ringColor.withOpacity((t * t).clamp(0.0, 1.0))..style = PaintingStyle.stroke..strokeWidth = 1.0 + t * 3.2..strokeCap = StrokeCap.butt);
    }

    final head = Offset(center.dx + radius * math.cos(headAngle), center.dy + radius * math.sin(headAngle));
    canvas.drawCircle(head, 12, Paint()..color = glowColor.withOpacity(0.45 * glowIntensity)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    canvas.drawCircle(head, 7, Paint()..color = glowColor.withOpacity(0.7 * glowIntensity)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.drawCircle(head, 5, Paint()..color = ringColor);
    canvas.drawCircle(head, 2.2, Paint()..color = Colors.white.withOpacity(0.95));
  }

  @override
  bool shouldRepaint(_SnakeRingPainter old) => old.progress != progress || old.glowIntensity != glowIntensity;
}

// Floating particles
class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;
  const _ParticlePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint()..style = PaintingStyle.fill..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    for (int i = 0; i < 18; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final t = (progress * (0.3 + rng.nextDouble() * 0.7) + rng.nextDouble()) % 1.0;
      final phase = rng.nextDouble();
      paint.color = color.withOpacity((math.sin(t * math.pi)).clamp(0.0, 1.0) * 0.5);
      canvas.drawCircle(Offset(baseX + math.sin(t * math.pi * 2 + phase * 6) * 12, baseY - t * size.height * 0.6), 1.0 + rng.nextDouble() * 2.2, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}