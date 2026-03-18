import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class _NavTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavTab({required this.icon, required this.activeIcon, required this.label});
}

const _tabs = [
  _NavTab(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
  _NavTab(icon: Icons.restaurant_menu, activeIcon: Icons.restaurant_menu, label: 'Meal Prep'),
  _NavTab(icon: Icons.calculate_outlined, activeIcon: Icons.calculate, label: 'BMI'),
  _NavTab(icon: Icons.notifications_none, activeIcon: Icons.notifications, label: 'Alerts'),
];

class _Particle {
  late Offset position;
  late Offset velocity;
  late double radius;
  late double opacity;
  late Color color;

  _Particle(Offset origin, math.Random rng) {
    final angle = rng.nextDouble() * 2 * math.pi;
    final speed = 1.5 + rng.nextDouble() * 5.5;
    position = origin;
    velocity = Offset(math.cos(angle) * speed, math.sin(angle) * speed);
    radius = 2.0 + rng.nextDouble() * 3.0;
    opacity = 1.0;
    color = Color.lerp(Colors.green, Colors.greenAccent, rng.nextDouble())!;
  }

  void update() {
    position += velocity;
    velocity *= 0.88;
    radius *= 0.94;
    opacity *= 0.88;
  }

  bool get isDead => opacity < 0.02 || radius < 0.3;
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.opacity) // Fixed Deprecation
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(p.position, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}

class AppBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> with TickerProviderStateMixin {
  late final List<AnimationController> _bubbleCtrls;
  late final List<Animation<double>> _bubbleAnims;
  final List<_Particle> _particles = [];
  final math.Random _rng = math.Random();
  late final AnimationController _particleCtrl;

  @override
  void initState() {
    super.initState();
    _bubbleCtrls = List.generate(
      _tabs.length,
      (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 300)),
    );
    _bubbleAnims = _bubbleCtrls.map((c) => TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 50),
    ]).animate(c)).toList();

    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..addListener(() {
      if (!mounted) return;
      setState(() {
        for (final p in _particles) p.update();
        _particles.removeWhere((p) => p.isDead);
      });
    })..repeat();
  }

  void _handleTap(int index, Offset globalPos) {
    HapticFeedback.lightImpact();
    _bubbleCtrls[index].forward(from: 0);
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box != null) {
      final local = box.globalToLocal(globalPos);
      for (int i = 0; i < 15; i++) _particles.add(_Particle(local, _rng));
    }
    widget.onTap(index);
  }

  @override
  void dispose() {
    for (var c in _bubbleCtrls) {
      c.dispose();
    }
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF0A1F12).withValues(alpha: 0.1), // Fixed Deprecation
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _ParticlePainter(List.from(_particles))),
                ),
                Row(
                  children: List.generate(_tabs.length, (i) {
                    final isSelected = widget.currentIndex == i;
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTapDown: (d) => _handleTap(i, d.globalPosition),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ScaleTransition(
                              scale: _bubbleAnims[i],
                              child: Icon(
                                isSelected ? _tabs[i].activeIcon : _tabs[i].icon,
                                color: isSelected ? Colors.green : Colors.white38,
                              ),
                            ),
                            Text(
                              _tabs[i].label,
                              style: TextStyle(
                                color: isSelected ? Colors.green : Colors.white38,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}