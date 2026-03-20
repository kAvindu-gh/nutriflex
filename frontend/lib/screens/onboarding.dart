import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../services/api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF0A0A0A),
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'SF Pro Display',
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}

// ─── COLORS & CONSTANTS ────────────────────────────────────────────────
const kBg = Color(0xFF0A0A0A);
const kCard = Color(0xFF141414);
const kCardBorder = Color(0xFF222222);
const kGreen = Color(0xFF00E676);
const kGreenDark = Color(0xFF00C853);
const kGreenGlow = Color(0xFF00E676);
const kTextPrimary = Colors.white;
const kTextSub = Color(0xFF888888);
const kSelectedBorder = Color(0xFF00E676);

// Step field keys — must match backend schema
const List<String> kStepKeys = [
  'goal',
  'activity',
  'medical',
  'diet',
  'commitment',
];

// ─── CUSTOM PAGE ROUTE ──────────────────────────────────────────────────
class SlideUpFadeRoute extends PageRouteBuilder {
  final Widget page;
  SlideUpFadeRoute({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, __, child) {
            final slide = Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
            final fade = Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(
                parent: animation,
                curve: const Interval(0, 0.6, curve: Curves.easeOut),
              ),
            );
            return FadeTransition(
              opacity: fade,
              child: SlideTransition(position: slide, child: child),
            );
          },
        );
}

// ─── WELCOME SCREEN ─────────────────────────────────────────────────────
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _btnOpacity;
  late Animation<double> _glowPulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5, curve: Curves.elasticOut)),
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.3, curve: Curves.easeOut)),
    );
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.45, 0.75, curve: Curves.easeOut)),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.45, 0.75, curve: Curves.easeOut)),
    );
    _btnOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.65, 1.0, curve: Curves.easeOut)),
    );
    _glowPulse = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: kBg,
        body: Stack(
          children: [
            Positioned(
              top: -100,
              left: -100,
              right: -100,
              child: AnimatedBuilder(
                animation: _glowPulse,
                builder: (_, __) => Container(
                  height: 400,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        kGreen.withOpacity(0.08 * _glowPulse.value),
                        Colors.transparent,
                      ],
                      radius: 0.8,
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    AnimatedBuilder(
                      animation: _ctrl,
                      builder: (_, __) => Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: _buildLogo(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    AnimatedBuilder(
                      animation: _ctrl,
                      builder: (_, __) => Opacity(
                        opacity: _textOpacity.value,
                        child: SlideTransition(
                          position: _textSlide,
                          child: Column(
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [Colors.white, Color(0xFFCCCCCC)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ).createShader(bounds),
                                child: const Text(
                                  "Welcome to\nNutriFlex",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 38,
                                    fontWeight: FontWeight.w800,
                                    height: 1.15,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                "Let's personalize your fitness journey.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: kGreen,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                    AnimatedBuilder(
                      animation: _ctrl,
                      builder: (_, __) => Opacity(
                        opacity: _btnOpacity.value,
                        child: _GreenButton(
                          label: "Get Started",
                          onPressed: () {
                            Navigator.push(
                              context,
                              SlideUpFadeRoute(
                                page: const OnboardingScreen(step: 0),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: kGreen,
          width: 2.5,
        ),
      ),
      child: ClipOval(
        child: Image.asset(
          'lib/assets/NutriFlex_Logo_1.jpeg',
          width: 220,
          height: 220,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

// ─── ONBOARDING DATA ────────────────────────────────────────────────────
class OnboardingStep {
  final String question;
  final String subtitle;
  final List<_Option> options;

  const OnboardingStep({
    required this.question,
    required this.subtitle,
    required this.options,
  });
}

class _Option {
  final String label;
  final IconData icon;
  const _Option(this.label, this.icon);
}

final List<OnboardingStep> kSteps = [
  OnboardingStep(
    question: "What is your\nprimary goal?",
    subtitle: "This helps us personalize your meals.",
    options: [
      _Option("Build Muscle", Icons.fitness_center_rounded),
      _Option("Lose Weight", Icons.trending_down_rounded),
      _Option("Maintain Weight", Icons.monitor_weight_outlined),
      _Option("Improve Fitness", Icons.bolt_rounded),
    ],
  ),
  OnboardingStep(
    question: "How active are\nyou daily?",
    subtitle: "We'll adjust your calorie needs accordingly.",
    options: [
      _Option("Sedentary", Icons.bedtime_outlined),
      _Option("Lightly Active", Icons.directions_walk_rounded),
      _Option("Active", Icons.directions_bike_rounded),
      _Option("Very Active", Icons.local_fire_department_rounded),
    ],
  ),
  OnboardingStep(
    question: "Any medical\nconditions?",
    subtitle: "This helps us provide safe meal recommendations.",
    options: [
      _Option("Diabetes", Icons.bloodtype_outlined),
      _Option("High Blood Pressure", Icons.favorite_border_rounded),
      _Option("Cholesterol", Icons.science_outlined),
      _Option("None", Icons.check_circle_outline_rounded),
    ],
  ),
  OnboardingStep(
    question: "Do you follow a\nspecific diet?",
    subtitle: "We'll recommend suitable recipes.",
    options: [
      _Option("Non-Vegetarian", Icons.set_meal_rounded),
      _Option("Vegetarian", Icons.eco_rounded),
      _Option("Vegan", Icons.grass_rounded),
      _Option("No Preference", Icons.star_border_rounded),
    ],
  ),
  OnboardingStep(
    question: "How committed\nare you?",
    subtitle: "Your dedication level helps us guide you better.",
    options: [
      _Option("Casual", Icons.coffee_rounded),
      _Option("Moderate", Icons.trending_up_rounded),
      _Option("Serious", Icons.psychology_rounded),
      _Option("Extremely Dedicated", Icons.emoji_events_rounded),
    ],
  ),
];

// ─── ONBOARDING SCREEN ──────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  final int step;
  const OnboardingScreen({super.key, required this.step});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  int? _selected;                    // used for all steps except medical
  Set<int> _multiSelected = {};      // used only for step 2 (medical)
  bool _isLoading = false;

  bool get _isMedicalStep => widget.step == 2;
  static const int _noneIndex = 3;   // "None" is the 4th card (index 3)

  late AnimationController _entryCtrl;
  late AnimationController _btnCtrl;
  late List<AnimationController> _cardCtrls;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _btnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _cardCtrls = List.generate(
      4,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );

    _entryCtrl.forward();
    for (int i = 0; i < 4; i++) {
      Future.delayed(Duration(milliseconds: 200 + i * 80), () {
        if (mounted) _cardCtrls[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _btnCtrl.dispose();
    for (final c in _cardCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _selectOption(int index) {
    setState(() {
      if (_isMedicalStep) {
        if (index == _noneIndex) {
          // "None" tapped — clear all others, select only None
          _multiSelected = {_noneIndex};
        } else {
          // Disease tapped — remove None if it was selected, toggle disease
          _multiSelected.remove(_noneIndex);
          if (_multiSelected.contains(index)) {
            _multiSelected.remove(index);
          } else {
            _multiSelected.add(index);
          }
        }
      } else {
        _selected = index;
      }
    });
    if (!_btnCtrl.isCompleted) _btnCtrl.forward();
  }

  // ── KEY METHOD: saves to Firebase on every step ──
  Future<void> _onContinue() async {
    final hasSelection = _isMedicalStep ? _multiSelected.isNotEmpty : _selected != null;
    if (!hasSelection || _isLoading) return;

    setState(() => _isLoading = true);

    final stepKey = kStepKeys[widget.step];
    String selectedLabel;

    if (_isMedicalStep) {
      final options = kSteps[widget.step].options;
      // Join all selected labels with comma e.g. "Diabetes, Cholesterol"
      selectedLabel = (_multiSelected.toList()..sort())
          .map((i) => options[i].label)
          .join(', ');
    } else {
      selectedLabel = kSteps[widget.step].options[_selected!].label;
    }

    await ApiService.updateOnboardingStep({stepKey: selectedLabel});

    if (!mounted) return;
    setState(() => _isLoading = false);

    final isLast = widget.step == kSteps.length - 1;
    if (isLast) {
      Navigator.push(context, SlideUpFadeRoute(page: const AllDoneScreen()));
    } else {
      Navigator.push(
        context,
        SlideUpFadeRoute(page: OnboardingScreen(step: widget.step + 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepData = kSteps[widget.step];
    final progress = (widget.step + 1) / kSteps.length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: kBg,
        body: Stack(
          children: [
            Positioned(
              top: -60,
              left: 0,
              right: 0,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      kGreen.withOpacity(0.06),
                      Colors.transparent,
                    ],
                    radius: 1.0,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AnimatedEntry(
                      controller: _entryCtrl,
                      delay: 0,
                      child: _ProgressHeader(
                        step: widget.step + 1,
                        total: kSteps.length,
                        progress: progress,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _AnimatedEntry(
                      controller: _entryCtrl,
                      delay: 0.1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stepData.question,
                            style: const TextStyle(
                              color: kTextPrimary,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            stepData.subtitle,
                            style: const TextStyle(
                              color: kGreen,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.78,
                        physics: const NeverScrollableScrollPhysics(),
                        children: List.generate(4, (i) {
                          return _StaggeredCard(
                            controller: _cardCtrls[i],
                            option: stepData.options[i],
                            isSelected: _isMedicalStep
                                ? _multiSelected.contains(i)
                                : _selected == i,
                            onTap: () => _selectOption(i),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedBuilder(
                      animation: _btnCtrl,
                      builder: (_, __) {
                        return _GreenButton(
                          label: _isLoading
                              ? "Saving..."
                              : widget.step == kSteps.length - 1
                                  ? "Finish"
                                  : "Continue",
                          onPressed: (_isMedicalStep ? _multiSelected.isNotEmpty : _selected != null) && !_isLoading
                              ? _onContinue
                              : null,
                          isEnabled: (_isMedicalStep ? _multiSelected.isNotEmpty : _selected != null) && !_isLoading,
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PROGRESS HEADER ────────────────────────────────────────────────────
class _ProgressHeader extends StatelessWidget {
  final int step, total;
  final double progress;
  const _ProgressHeader({
    required this.step,
    required this.total,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "$step/$total",
          style: const TextStyle(
            color: kGreen,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TweenAnimationBuilder<double>(
            key: ValueKey(progress),
            tween: Tween(begin: progress > 0.21 ? progress - 0.2 : 0.0, end: progress),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
            builder: (_, val, __) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Container(
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: val,
                    child: Container(
                      height: 18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00C853), Color(0xFF00E676)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: kGreen.withOpacity(0.45),
                            blurRadius: 8,
                            spreadRadius: 0,
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
      ],
    );
  }
}

// ─── STAGGERED ANIMATED CARD ─────────────────────────────────────────────
class _StaggeredCard extends StatefulWidget {
  final AnimationController controller;
  final _Option option;
  final bool isSelected;
  final VoidCallback onTap;

  const _StaggeredCard({
    required this.controller,
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_StaggeredCard> createState() => _StaggeredCardState();
}

class _StaggeredCardState extends State<_StaggeredCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapCtrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entryAnim = CurvedAnimation(
      parent: widget.controller,
      curve: Curves.easeOutBack,
    );

    return AnimatedBuilder(
      animation: Listenable.merge([widget.controller, _tapCtrl]),
      builder: (_, __) {
        final entryVal = entryAnim.value;
        return Opacity(
          opacity: entryVal.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - entryVal.clamp(0.0, 1.0))),
            child: Transform.scale(
              scale: _scale.value,
              child: GestureDetector(
                onTapDown: (_) => _tapCtrl.forward(),
                onTapUp: (_) {
                  _tapCtrl.reverse();
                  widget.onTap();
                },
                onTapCancel: () => _tapCtrl.reverse(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? kGreen.withOpacity(0.12)
                        : kCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.isSelected ? kGreen : kCardBorder,
                      width: widget.isSelected ? 2.0 : 1.0,
                    ),
                    boxShadow: widget.isSelected
                        ? [
                            BoxShadow(
                              color: kGreen.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: widget.isSelected
                                    ? kGreen.withOpacity(0.15)
                                    : const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                widget.option.icon,
                                color: widget.isSelected
                                    ? kGreen
                                    : const Color(0xFF666666),
                                size: 26,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              widget.option.label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: widget.isSelected
                                    ? kGreen
                                    : const Color(0xFFBBBBBB),
                                fontSize: 13,
                                fontWeight: widget.isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.isSelected)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: kGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── ANIMATED ENTRY WRAPPER ──────────────────────────────────────────────
class _AnimatedEntry extends StatelessWidget {
  final AnimationController controller;
  final double delay;
  final Widget child;

  const _AnimatedEntry({
    required this.controller,
    required this.delay,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final start = delay;
    final end = (delay + 0.6).clamp(0.0, 1.0);
    final opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(start, end, curve: Curves.easeOut),
      ),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(start, end, curve: Curves.easeOut),
      ),
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Opacity(
        opacity: opacity.value,
        child: SlideTransition(position: slide, child: child),
      ),
    );
  }
}

// ─── ALL DONE SCREEN ─────────────────────────────────────────────────────
class AllDoneScreen extends StatefulWidget {
  const AllDoneScreen({super.key});

  @override
  State<AllDoneScreen> createState() => _AllDoneScreenState();
}

class _AllDoneScreenState extends State<AllDoneScreen>
    with TickerProviderStateMixin {
  late AnimationController _circleCtrl;
  late AnimationController _spinCtrl;
  late AnimationController _checkCtrl;
  late AnimationController _textCtrl;
  late AnimationController _dotsCtrl;
  late AnimationController _pulseCtrl;
  late List<AnimationController> _bubbleCtrls;

  @override
  void initState() {
    super.initState();

    _circleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _spinCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _checkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _dotsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);

    _bubbleCtrls = List.generate(
      3,
      (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 600)),
    );

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) _bubbleCtrls[i].repeat(reverse: true);
      });
    }

    _circleCtrl.forward().then((_) {
      _spinCtrl.forward().then((_) {
        _checkCtrl.forward().then((_) {
          _textCtrl.forward().then((_) {
            _dotsCtrl.forward();
          });
        });
      });
    });
  }

  @override
  void dispose() {
    _circleCtrl.dispose();
    _spinCtrl.dispose();
    _checkCtrl.dispose();
    _textCtrl.dispose();
    _dotsCtrl.dispose();
    _pulseCtrl.dispose();
    for (final c in _bubbleCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: kBg,
        body: Stack(
          children: [
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Center(
                child: Container(
                  width: 300 + 50 * _pulseCtrl.value,
                  height: 300 + 50 * _pulseCtrl.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        kGreen.withOpacity(0.08 * _pulseCtrl.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: Listenable.merge([_circleCtrl, _spinCtrl, _checkCtrl, _pulseCtrl]),
                    builder: (_, __) {
                      final circleScale = Tween<double>(begin: 0.0, end: 1.0)
                          .animate(CurvedAnimation(parent: _circleCtrl, curve: Curves.elasticOut))
                          .value;
                      final spinAngle = Tween<double>(begin: 0, end: 2 * math.pi)
                          .animate(CurvedAnimation(parent: _spinCtrl, curve: Curves.easeInOutCubic))
                          .value;
                      final checkOpacity = Tween<double>(begin: 0, end: 1)
                          .animate(CurvedAnimation(parent: _checkCtrl, curve: Curves.easeOut))
                          .value;
                      final checkScale = Tween<double>(begin: 0.4, end: 1.0)
                          .animate(CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut))
                          .value;

                      return Transform.scale(
                        scale: circleScale,
                        child: Transform.rotate(
                          angle: spinAngle,
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [kGreen, kGreenDark],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: kGreen.withOpacity(0.3 + 0.2 * _pulseCtrl.value),
                                  blurRadius: 40 + 20 * _pulseCtrl.value,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Transform.rotate(
                              angle: -spinAngle,
                              child: Opacity(
                                opacity: checkOpacity,
                                child: Transform.scale(
                                  scale: checkScale,
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.black,
                                    size: 65,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 48),
                  AnimatedBuilder(
                    animation: _textCtrl,
                    builder: (_, __) {
                      return Opacity(
                        opacity: _textCtrl.value,
                        child: Transform.translate(
                          offset: Offset(0, 30.0 * (1 - _textCtrl.value)),
                          child: Column(
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [Colors.white, Color(0xFFDDDDDD)],
                                ).createShader(bounds),
                                child: const Text(
                                  "All Done!",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 42,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "Your personalized fitness\njourney is ready.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: kGreen,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 44),
                  AnimatedBuilder(
                    animation: _dotsCtrl,
                    builder: (_, __) => Opacity(
                      opacity: _dotsCtrl.value,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) {
                          return AnimatedBuilder(
                            animation: _bubbleCtrls[i],
                            builder: (_, __) {
                              final bounce = Tween<double>(begin: 0, end: -14)
                                  .animate(CurvedAnimation(parent: _bubbleCtrls[i], curve: Curves.easeInOut))
                                  .value;
                              final scale = Tween<double>(begin: 0.85, end: 1.15)
                                  .animate(CurvedAnimation(parent: _bubbleCtrls[i], curve: Curves.easeInOut))
                                  .value;
                              return Transform.translate(
                                offset: Offset(0, bounce),
                                child: Transform.scale(
                                  scale: scale,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 6),
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: kGreen.withOpacity(i == 0 ? 1.0 : i == 1 ? 0.65 : 0.35),
                                      boxShadow: [
                                        BoxShadow(color: kGreen.withOpacity(0.4), blurRadius: 8),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 44),
                  AnimatedBuilder(
                    animation: _dotsCtrl,
                    builder: (_, __) => Opacity(
                      opacity: _dotsCtrl.value,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: _GreenButton(
                          label: "Start My Journey",
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/home');
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── GREEN BUTTON ────────────────────────────────────────────────────────
class _GreenButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isEnabled;

  const _GreenButton({
    required this.label,
    this.onPressed,
    this.isEnabled = true,
  });

  @override
  State<_GreenButton> createState() => _GreenButtonState();
}

class _GreenButtonState extends State<_GreenButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.isEnabled && widget.onPressed != null;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: GestureDetector(
          onTapDown: enabled ? (_) => _ctrl.forward() : null,
          onTapUp: enabled
              ? (_) {
                  _ctrl.reverse();
                  widget.onPressed?.call();
                }
              : null,
          onTapCancel: () => _ctrl.reverse(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            height: 58,
            decoration: BoxDecoration(
              gradient: enabled
                  ? const LinearGradient(
                      colors: [kGreen, kGreenDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: enabled ? null : const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: kGreen.withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: enabled ? Colors.black : const Color(0xFF444444),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}