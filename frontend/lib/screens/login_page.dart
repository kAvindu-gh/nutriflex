import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../main_shell.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with TickerProviderStateMixin {

  final _formKey         = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passController  = TextEditingController();

  bool _obscure       = true;
  bool _loading       = false;
  bool _googleLoading = false;

  static const kGreen = Color(0xFF14D97D);
  static const kBg    = Color(0xFF000302);
  static const kField = Color(0xFF111A13);

  // ── Page entrance animation ───────────────────────────────────────────────
  late AnimationController _pageCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  // ── Logo rock animation ───────────────────────────────────────────────────
  late AnimationController _logoCtrl;
  late Animation<double>   _logoAnim;

  // ── Toast overlay ─────────────────────────────────────────────────────────
  OverlayEntry? _toastEntry;

  @override
  void initState() {
    super.initState();

    // Page entrance
    _pageCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim  = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut));
    _pageCtrl.forward();

    // Logo rock — _logoAnim must be assigned before repeat() is called
    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000));
    _logoAnim = Tween<double>(begin: -0.06, end: 0.06)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeInOut));
    _logoCtrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _logoCtrl.dispose();
    _emailController.dispose();
    _passController.dispose();
    _toastEntry?.remove();
    super.dispose();
  }

  // ── Premium animated toast ────────────────────────────────────────────────
  void _showToast(String msg, {bool isSuccess = false}) {
    _toastEntry?.remove();
    _toastEntry = null;

    final overlay = Overlay.of(context);
    final ctrl    = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    final slide   = Tween<Offset>(
            begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic));
    final fade = CurvedAnimation(parent: ctrl, curve: Curves.easeOut);

    _toastEntry = OverlayEntry(
      builder: (_) => Positioned(
        bottom: 32, left: 20, right: 20,
        child: SlideTransition(
          position: slide,
          child: FadeTransition(
            opacity: fade,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: isSuccess
                      ? const Color(0xFF0D2818)
                      : const Color(0xFF1A0A0A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSuccess
                        ? kGreen.withOpacity(0.6)
                        : Colors.redAccent.withOpacity(0.6),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isSuccess ? kGreen : Colors.redAccent)
                          .withOpacity(0.15),
                      blurRadius: 20, spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: (isSuccess ? kGreen : Colors.redAccent)
                          .withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                      color: isSuccess ? kGreen : Colors.redAccent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(msg,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        )),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_toastEntry!);
    ctrl.forward();

    Future.delayed(const Duration(seconds: 3), () {
      ctrl.reverse().then((_) {
        _toastEntry?.remove();
        _toastEntry = null;
        ctrl.dispose();
      });
    });
  }

  // ── Email / password login ────────────────────────────────────────────────
  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email:    _emailController.text.trim(),
        password: _passController.text.trim(),
      );
      await cred.user?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || !user.emailVerified) {
        await FirebaseAuth.instance.signOut();
        _showToast('Please verify your email before logging in');
        return;
      }
      _goToShell();
    } on FirebaseAuthException catch (e) {
      _showToast(_authError(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Google sign-in ────────────────────────────────────────────────────────
  Future<void> _googleSignIn() async {
    setState(() => _googleLoading = true);
    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      _goToShell();
    } on FirebaseAuthException catch (e) {
      _showToast('Firebase: ${e.code} — ${e.message}');
    } catch (e) {
      _showToast(e.toString());
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  // ── Forgot password ───────────────────────────────────────────────────────
  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showToast('Enter a valid email address first');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showToast('Password reset email sent ✓', isSuccess: true);
    } catch (e) {
      _showToast('Could not send reset email. Try again.');
    }
  }

  void _goToShell() {
    if (!mounted) return;
    Navigator.pushReplacement(context,
        PageRouteBuilder(
          pageBuilder:        (_, a, __) => const MainShell(),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ));
  }

  String _authError(String code) {
    switch (code) {
      case 'user-not-found':          return 'No account found with this email';
      case 'wrong-password':          return 'Incorrect password';
      case 'invalid-email':           return 'Invalid email address';
      case 'user-disabled':           return 'This account has been disabled';
      case 'too-many-requests':       return 'Too many attempts. Try again later';
      case 'network-request-failed':  return 'No internet connection';
      default:                        return 'Login failed. Please try again';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(children: [
        // Gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.6, 1.0],
              colors: [Color(0xFF0D2818), Color(0xFF103E23), kBg],
            ),
          ),
        ),

        SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(children: [

                // ── Scrollable form ───────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Form(
                      key: _formKey,
                      child: Column(children: [
                        const SizedBox(height: 56),

                        // ── Rocking logo ──────────────────────────────────
                        AnimatedBuilder(
                          animation: _logoAnim,
                          builder: (_, child) => Transform.rotate(
                            angle: _logoAnim.value,
                            child: child,
                          ),
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: kGreen.withOpacity(0.4),
                                width: 1.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                'lib/assets/NutriFlex_Logo_1.jpeg',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        const Text('Welcome Back',
                            style: TextStyle(color: Colors.white,
                                fontSize: 26, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        const Text('Sign in to continue your fitness journey',
                            style: TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 36),

                        // Email field
                        _field(
                          controller: _emailController,
                          hint: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Email is required';
                            if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(v))
                              return 'Enter a valid email address';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Password field
                        _field(
                          controller: _passController,
                          hint: 'Password',
                          icon: Icons.lock_outline,
                          obscure: _obscure,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey, size: 20),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Password is required';
                            if (v.length < 6)
                              return 'Password must be at least 6 characters';
                            return null;
                          },
                        ),

                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _resetPassword,
                            child: const Text('Forgot Password ?',
                                style: TextStyle(color: kGreen, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Sign in button
                        SizedBox(
                          width: double.infinity, height: 56,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _loginUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kGreen,
                              disabledBackgroundColor: kGreen.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: _loading
                                ? const SizedBox(width: 22, height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.black, strokeWidth: 2.5))
                                : const Text('Sign in',
                                    style: TextStyle(color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Divider
                        Row(children: [
                          Expanded(child: Divider(
                              color: Colors.white.withOpacity(0.12))),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: Text('or',
                                style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ),
                          Expanded(child: Divider(
                              color: Colors.white.withOpacity(0.12))),
                        ]),
                        const SizedBox(height: 24),

                        // Social buttons — two circles
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _socialCircle(
                              onTap: _googleLoading ? null : _googleSignIn,
                              child: _googleLoading
                                  ? const SizedBox(width: 20, height: 20,
                                      child: CircularProgressIndicator(
                                          color: kGreen, strokeWidth: 2))
                                  : _GoogleColorIcon(),
                            ),
                            const SizedBox(width: 24),
                            _socialCircle(
                              onTap: () => _showToast('Apple sign-in coming soon'),
                              child: const Icon(Icons.apple,
                                  color: Colors.white, size: 26),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                      ]),
                    ),
                  ),
                ),

                // ── Fixed bottom ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?",
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, a, __) => const SignUpPage(),
                            transitionsBuilder: (_, a, __, child) {
                              final slide = Tween<Offset>(
                                begin: const Offset(1.0, 0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                  parent: a, curve: Curves.easeInOutCubic));
                              final fade = Tween<double>(begin: 0.0, end: 1.0)
                                  .animate(CurvedAnimation(
                                      parent: a, curve: const Interval(0.0, 0.6)));
                              final scale = Tween<double>(begin: 0.92, end: 1.0)
                                  .animate(CurvedAnimation(
                                      parent: a, curve: Curves.easeOutCubic));
                              return FadeTransition(
                                opacity: fade,
                                child: ScaleTransition(
                                  scale: scale,
                                  child: SlideTransition(
                                    position: slide,
                                    child: child,
                                  ),
                                ),
                              );
                            },
                            transitionDuration:
                                const Duration(milliseconds: 500),
                          ),
                        ),
                        child: const Text('Sign Up',
                            style: TextStyle(color: kGreen,
                                fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Circle social button ──────────────────────────────────────────────────
  Widget _socialCircle({required Widget child, VoidCallback? onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            color: kField,
            shape: BoxShape.circle,
            border: Border.all(color: kGreen.withOpacity(0.25), width: 1.5),
            boxShadow: [
              BoxShadow(color: kGreen.withOpacity(0.08),
                  blurRadius: 12, spreadRadius: 1),
            ],
          ),
          child: Center(child: child),
        ),
      );

  // ── Input field ───────────────────────────────────────────────────────────
  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: kGreen, size: 20),
          suffixIcon: suffixIcon,
          filled: true, fillColor: kField,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: kGreen.withOpacity(0.2))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kGreen, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      );
}

// ── Google color G icon ───────────────────────────────────────────────────────
class _GoogleColorIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(24, 24), painter: _GooglePainter());
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2;
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -1.57, 1.57, true, paint);
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        0, 1.57, true, paint);
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        1.57, 1.57, true, paint);
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        3.14, 1.57, true, paint);
    paint.color = const Color(0xFF111A13);
    canvas.drawCircle(Offset(cx, cy), r * 0.58, paint);
    paint.color = Colors.white;
    canvas.drawRect(
        Rect.fromLTWH(cx, cy - r * 0.18, r * 0.9, r * 0.36), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}