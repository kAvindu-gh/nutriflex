import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'terms_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

// TickerProviderStateMixin (not Single) — allows multiple AnimationControllers
class _SignUpPageState extends State<SignUpPage>
    with TickerProviderStateMixin {

  final _formKey         = GlobalKey<FormState>();
  final _nameController  = TextEditingController();
  final _emailController = TextEditingController();
  final _passController  = TextEditingController();

  bool _obscure     = true;
  bool _loading     = false;
  bool _termsAgreed = false;

  static const kGreen = Color(0xFF14D97D);
  static const kBg    = Color(0xFF000302);
  static const kField = Color(0xFF111A13);

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  OverlayEntry? _toastEntry;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(1.0, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _toastEntry?.remove();
    super.dispose();
  }

  // ── Toast — uses TickerProviderStateMixin so multiple controllers are fine ─
  void _showToast(String msg, {bool isSuccess = false}) {
    _toastEntry?.remove();
    _toastEntry = null;

    final overlay = Overlay.of(context);
    final ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    final slide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic));
    final fade = CurvedAnimation(parent: ctrl, curve: Curves.easeOut);

    _toastEntry = OverlayEntry(
      builder: (_) => Positioned(
        bottom: 40, left: 20, right: 20,
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
                        ? kGreen.withOpacity(0.7)
                        : Colors.redAccent.withOpacity(0.7),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isSuccess ? kGreen : Colors.redAccent)
                          .withOpacity(0.2),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: (isSuccess ? kGreen : Colors.redAccent)
                          .withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSuccess
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      color: isSuccess ? kGreen : Colors.redAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      msg,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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

    Future.delayed(const Duration(seconds: 4), () {
      ctrl.reverse().then((_) {
        _toastEntry?.remove();
        _toastEntry = null;
        ctrl.dispose();
      });
    });
  }

  // ── Open Terms (read-only) ─────────────────────────────────────────────────
  Future<void> _openTerms() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const TermsPage(requireAgree: false),
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeInOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  // ── Validators ────────────────────────────────────────────────────────────
  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Full name is required';
    if (v.trim().length < 2) return 'Name is too short';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(v))
      return 'Enter a valid email address';
    return null;
  }

  String? _validatePass(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    if (!RegExp(r'[A-Z]').hasMatch(v))
      return 'Include at least one uppercase letter';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Include at least one number';
    return null;
  }

  // ── Create account ────────────────────────────────────────────────────────
  Future<void> _createAccount() async {
    // 1. Validate all fields first
    final formValid = _formKey.currentState!.validate();
    if (!formValid) return;

    // 2. Check terms checkbox
    if (!_termsAgreed) {
      _showToast('Please agree to the Terms & Privacy Policy to continue');
      return;
    }

    // 3. Call Firebase
    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email:    _emailController.text.trim(),
        password: _passController.text.trim(),
      );

      await cred.user?.updateDisplayName(_nameController.text.trim());
      await cred.user?.sendEmailVerification();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'uid':           cred.user!.uid,
        'fullName':      _nameController.text.trim(),
        'email':         _emailController.text.trim(),
        'createdAt':     Timestamp.now(),
        'emailVerified': false,
        'termsAgreed':   true,
      });

      // Show success toast THEN go back after delay
      _showToast(
        'Verification email sent to ${_emailController.text.trim()}. Check your inbox!',
        isSuccess: true,
      );
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      _showToast(_authError(e.code));
    } catch (e) {
      _showToast('Unexpected error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _authError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists with this email address';
      case 'invalid-email':
        return 'Invalid email address format';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters';
      case 'network-request-failed':
        return 'No internet connection. Check your network';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'operation-not-allowed':
        return 'Email sign-up is disabled. Contact support';
      default:
        return 'Sign up failed: $code';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(children: [

        // Background gradient
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
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),

                          // Back button
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(
                                color: kField,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: kGreen.withOpacity(0.3)),
                              ),
                              child: const Icon(Icons.arrow_back,
                                  color: kGreen, size: 20),
                            ),
                          ),
                          const SizedBox(height: 24),

                          const Text('Create Account',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          const Text('Start your premium fitness journey',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14)),
                          const SizedBox(height: 30),

                          // Full Name
                          _field(
                            controller: _nameController,
                            hint: 'Full Name',
                            icon: Icons.person_outline,
                            validator: _validateName,
                          ),
                          const SizedBox(height: 14),

                          // Email
                          _field(
                            controller: _emailController,
                            hint: 'Email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 14),

                          // Password
                          _field(
                            controller: _passController,
                            hint: 'Password',
                            icon: Icons.lock_outline,
                            obscure: _obscure,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                            validator: _validatePass,
                          ),
                          const SizedBox(height: 8),

                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Text(
                              'Min 6 characters, one uppercase & one number',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ── Checkbox ──────────────────────────────────────
                          GestureDetector(
                            onTap: () =>
                                setState(() => _termsAgreed = !_termsAgreed),
                            child: Row(children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: _termsAgreed
                                      ? kGreen
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _termsAgreed
                                        ? kGreen
                                        : Colors.grey.withOpacity(0.5),
                                    width: 1.5,
                                  ),
                                ),
                                child: _termsAgreed
                                    ? const Icon(Icons.check,
                                        color: Colors.black, size: 15)
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 13),
                                    children: [
                                      const TextSpan(text: 'I agree to the '),
                                      const TextSpan(
                                        text: 'Terms & Privacy Policy',
                                        style: TextStyle(
                                          color: kGreen,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 28),

                          // Create Account button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _createAccount,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kGreen,
                                disabledBackgroundColor:
                                    kGreen.withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.black,
                                          strokeWidth: 2.5))
                                  : const Text('Create Account',
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Fixed bottom — Terms link ─────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: GestureDetector(
                    onTap: _openTerms,
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12),
                        children: [
                          const TextSpan(text: 'View our '),
                          TextSpan(
                            text: 'Terms & Privacy Policy',
                            style: TextStyle(
                              color: kGreen,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: kGreen.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

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
          filled: true,
          fillColor: kField,
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
              borderSide:
                  const BorderSide(color: Colors.redAccent, width: 1)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Colors.redAccent, width: 1.5)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      );
}