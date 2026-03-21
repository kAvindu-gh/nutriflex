//bottom_nav.dart

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Tab data ─────────────────────────────────────────────────────────────────

class _NavTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavTab({required this.icon, required this.activeIcon, required this.label});
}

const _tabs = [
  _NavTab(icon: Icons.home_outlined,       activeIcon: Icons.home,          label: 'Home'),
  _NavTab(icon: Icons.restaurant_menu,     activeIcon: Icons.restaurant_menu,    label: 'Meal Prep'),
  _NavTab(icon: Icons.calculate_outlined,  activeIcon: Icons.calculate,     label: 'BMI'),
  _NavTab(icon: Icons.notifications_none,  activeIcon: Icons.notifications, label: 'Alerts'),
];

// ── Particle model ────────────────────────────────────────────────────────────

class _Particle {
  late Offset position;
  late Offset velocity;
  late double radius;
  late double opacity;
  late Color color;

  _Particle(Offset origin, math.Random rng) {
    final angle = rng.nextDouble() * 2 * math.pi;
    final speed = 1.5 + rng.nextDouble() * 3.5;
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

// ── Particle painter ──────────────────────────────────────────────────────────

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withOpacity(p.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(p.position, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}

// ── Main widget ───────────────────────────────────────────────────────────────
class AppBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav>
    with TickerProviderStateMixin {

  // Bubble press animation per tab
  late final List<AnimationController> _bubbleCtrls;
  late final List<Animation<double>> _bubbleAnims;

  // Particle system
  final List<_Particle> _particles = [];
  final math.Random _rng = math.Random();
  late final AnimationController _particleCtrl;

  // Sliding indicator
  late final AnimationController _slideCtrl;
  late Animation<double> _slideAnim;
  int _prevIndex = 0;

  @override
  void initState() {
    super.initState();
    _prevIndex = widget.currentIndex;

    // One bubble controller per tab
    _bubbleCtrls = List.generate(
      _tabs.length,
      (_) => AnimationController(
          vsync: this, duration: const Duration(milliseconds: 300)),
    );
    _bubbleAnims = _bubbleCtrls
        .map((c) => TweenSequence([
              TweenSequenceItem(
                  tween: Tween(begin: 1.0, end: 1.35)
                      .chain(CurveTween(curve: Curves.easeOut)),
                  weight: 40),
              TweenSequenceItem(
                  tween: Tween(begin: 1.35, end: 1.0)
                      .chain(CurveTween(curve: Curves.elasticOut)),
                  weight: 60),
            ]).animate(c))
        .toList();

    // Particle ticker
    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 60))
      ..addListener(_tickParticles)
      ..repeat();

    // Slide indicator
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnim = Tween<double>(
            begin: widget.currentIndex.toDouble(),
            end: widget.currentIndex.toDouble())
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutBack));
  }

  @override
  void didUpdateWidget(AppBottomNav old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _slideAnim = Tween<double>(
              begin: _prevIndex.toDouble(),
              end: widget.currentIndex.toDouble())
          .animate(
              CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutBack));
      _slideCtrl.forward(from: 0);
      _prevIndex = widget.currentIndex;
    }
  }

  void _tickParticles() {
    if (!mounted) return;
    setState(() {
      for (final p in _particles) {
        p.update();
      }
      _particles.removeWhere((p) => p.isDead);
    });
  }

  void _handleTap(int index, Offset globalPos) {
    HapticFeedback.lightImpact();

    // Bubble pop
    _bubbleCtrls[index].forward(from: 0);

    // Spawn particles at tap location
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box != null) {
      final local = box.globalToLocal(globalPos);
      for (int i = 0; i < 22; i++) {
        _particles.add(_Particle(local, _rng));
      }
    }

    widget.onTap(index);
  }

  @override
  void dispose() {
    for (final c in _bubbleCtrls) {
      c.dispose();
    }
    _particleCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 75,
            decoration: BoxDecoration(
              color: const Color(0xFF0A1F12).withOpacity(0.08),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.green.withOpacity(0.18),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Particle layer
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: CustomPaint(
                      painter: _ParticlePainter(List.from(_particles)),
                    ),
                  ),
                ),

                // Tab buttons
                Row(
                  children: List.generate(_tabs.length, (i) {
                    final tab = _tabs[i];
                    final isSelected = widget.currentIndex == i;

                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTapDown: (d) => _handleTap(i, d.globalPosition),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Icon bubble
                            AnimatedBuilder(
                              animation: _bubbleAnims[i],
                              builder: (_, child) => Transform.scale(
                                scale: _bubbleAnims[i].value,
                                child: child,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                                width: isSelected ? 52 : 40,
                                height: isSelected ? 38 : 30,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.green.withOpacity(0.18)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                  border: isSelected
                                      ? Border.all(
                                          color: Colors.green.withOpacity(0.35),
                                          width: 1)
                                      : null,
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Colors.green.withOpacity(0.2),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          )
                                        ]
                                      : [],
                                ),
                                child: Center(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 250),
                                    transitionBuilder: (child, anim) =>
                                        ScaleTransition(
                                            scale: anim, child: child),
                                    child: Icon(
                                      isSelected ? tab.activeIcon : tab.icon,
                                      key: ValueKey(isSelected),
                                      color: isSelected
                                          ? Colors.green
                                          : Colors.grey.shade500,
                                      size: isSelected ? 22 : 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 2),

                            // Label
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 250),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.green
                                    : Colors.grey.shade500,
                                fontSize: isSelected ? 10 : 9,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              child: Text(tab.label),
                            ),

                            const SizedBox(height: 2),

                            // Green dot — only visible on selected tab
                            AnimatedOpacity(
                              opacity: isSelected ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.7),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
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