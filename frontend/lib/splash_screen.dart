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

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    _logoGlowRadius = Tween<double>(begin: 0.0, end: 28.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.8),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 0.9, curve: Curves.easeIn),
      ),
    );
    _teamOpacity = Tween<double>(begin: 0.0, end: 0.65).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );
    _teamSlide = Tween<double>(begin: 18.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _glowIntensity = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // Snake ring — spins continuously
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _ringProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.linear),
    );
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 650));
    _textController.forward();
    // No auto-redirect — navigation is handled externally
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _bg0,
      body: Stack(
        fit: StackFit.expand,
        children: [

          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.74, 1.0],
                colors: [_bg0, _bg1, _bg2],
              ),
            ),
          ),

          // Ambient radial glow
          AnimatedBuilder(
            animation: _glowController,
            builder: (_, __) => Center(
              child: Container(
                width: size.width * 1.3,
                height: size.width * 1.3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _bg1.withOpacity(0.5 * _glowIntensity.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Floating particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (_, __) => CustomPaint(
              painter: _ParticlePainter(
                progress: _particleController.value,
                color: _green,
              ),
            ),
          ),

          // Main column
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Logo + snake ring
              AnimatedBuilder(
                animation: Listenable.merge([
                  _logoController,
                  _pulseController,
                  _glowController,
                  _ringController,
                ]),
                builder: (_, __) => Transform.scale(
                  scale: _logoScale.value * _pulseScale.value,
                  child: Opacity(
                    opacity: _logoOpacity.value,
                    child: SizedBox(
                      width: 164,
                      height: 164,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [

                          // Snake ring
                          CustomPaint(
                            size: const Size(164, 164),
                            painter: _SnakeRingPainter(
                              progress: _ringProgress.value,
                              ringColor: _green,
                              glowColor: _greenGlow,
                              glowIntensity: _glowIntensity.value,
                            ),
                          ),

                          // Logo box
                          Container(
                            width: 114,
                            height: 114,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: Colors.black,
                              boxShadow: [
                                BoxShadow(
                                  color: _greenGlow.withOpacity(
                                    0.5 * _glowIntensity.value,
                                  ),
                                  blurRadius: _logoGlowRadius.value +
                                      18 * _glowIntensity.value,
                                  spreadRadius: 3,
                                ),
                                BoxShadow(
                                  color: _green.withOpacity(0.25),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                              border: Border.all(
                                color: _greenDim.withOpacity(0.35),
                                width: 1.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Container(color: Colors.black),
                                  Image.asset(
                                    'assets/Nutriflex_logo.jpg',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => _FallbackLogo(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // Title
              AnimatedBuilder(
                animation: _textController,
                builder: (_, __) => FractionalTranslation(
                  translation: _titleSlide.value,
                  child: Opacity(
                    opacity: _titleOpacity.value,
                    child: const Text(
                      'NutriFlex',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              AnimatedBuilder(
                animation: _textController,
                builder: (_, __) => FractionalTranslation(
                  translation: _subtitleSlide.value,
                  child: Opacity(
                    opacity: _subtitleOpacity.value,
                    child: const Text(
                      'Premium Smart Meal Prep',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _green,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Team label
              AnimatedBuilder(
                animation: _textController,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, _teamSlide.value),
                  child: Opacity(
                    opacity: _teamOpacity.value,
                    child: const Text(
                      'Team Nutrition Navigators',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Fallback logo ──────────────────────────────────────────────────────────────
class _FallbackLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.restaurant_menu, color: Color(0xFF00E676), size: 52),
    );
  }
}

// ── Snake ring painter ─────────────────────────────────────────────────────────
class _SnakeRingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color glowColor;
  final double glowIntensity;

  const _SnakeRingPainter({
    required this.progress,
    required this.ringColor,
    required this.glowColor,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    final headAngle  = 2 * math.pi * progress - math.pi / 2;
    const tailSweep  = math.pi * 1.67; // ~300° tail
    const segments   = 80;
    final segAngle   = tailSweep / segments;

    for (int i = 0; i < segments; i++) {
      final t         = i / segments;
      final opacity   = t * t;
      final thickness = 1.0 + t * 3.2;
      final segStart  = headAngle - tailSweep + i * segAngle;

      // Glow
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        segStart, segAngle + 0.01, false,
        Paint()
          ..color = glowColor.withOpacity(opacity * 0.3 * glowIntensity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = thickness + 5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      // Solid
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        segStart, segAngle + 0.01, false,
        Paint()
          ..color = ringColor.withOpacity(opacity.clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = thickness
          ..strokeCap = StrokeCap.butt,
      );
    }

    // Head — glowing dot with white eye
    final head = Offset(
      center.dx + radius * math.cos(headAngle),
      center.dy + radius * math.sin(headAngle),
    );
    canvas.drawCircle(head, 12,
      Paint()
        ..color = glowColor.withOpacity(0.45 * glowIntensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(head, 7,
      Paint()
        ..color = glowColor.withOpacity(0.7 * glowIntensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(head, 5, Paint()..color = ringColor);
    canvas.drawCircle(head, 2.2,
      Paint()..color = Colors.white.withOpacity(0.95),
    );
  }

  @override
  bool shouldRepaint(_SnakeRingPainter old) =>
      old.progress != progress || old.glowIntensity != glowIntensity;
}

// ── Floating particles ─────────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;
  static const int _count = 18;

  const _ParticlePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rng   = math.Random(42);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    for (int i = 0; i < _count; i++) {
      final baseX   = rng.nextDouble() * size.width;
      final baseY   = rng.nextDouble() * size.height;
      final speed   = 0.3 + rng.nextDouble() * 0.7;
      final phase   = rng.nextDouble();
      final r       = 1.0 + rng.nextDouble() * 2.2;
      final t       = (progress * speed + phase) % 1.0;
      final dy      = -t * size.height * 0.6;
      final dx      = math.sin(t * math.pi * 2 + phase * 6) * 12;
      final opacity = (math.sin(t * math.pi)).clamp(0.0, 1.0) * 0.5;

      paint.color = color.withOpacity(opacity);
      canvas.drawCircle(Offset(baseX + dx, baseY + dy), r, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
