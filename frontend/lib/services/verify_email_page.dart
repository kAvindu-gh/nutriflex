import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main_shell.dart';  // Navigate to app shell, not home_page directly

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  Timer? _timer;

  static const kGreen = Color(0xFF14D97D);
  static const kBg    = Color(0xFF000302);

  @override
  void initState() {
    super.initState();
    // Poll every 3 seconds to check if email has been verified
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _checkVerification());
  }

  Future<void> _checkVerification() async {
    await FirebaseAuth.instance.currentUser?.reload();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && user.emailVerified) {
      _timer?.cancel();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
    }
  }

  Future<void> _resendEmail() async {
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email resent')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(children: [
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
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: kGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: kGreen.withOpacity(0.3), width: 2),
                  ),
                  child: const Icon(Icons.mark_email_unread_outlined,
                      size: 60, color: kGreen),
                ),
                const SizedBox(height: 28),
                const Text('Verify your email',
                    style: TextStyle(color: Colors.white,
                        fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text(
                  'We sent a verification link to your inbox.\nClick it to activate your account.',
                  style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.6),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    onPressed: _resendEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGreen,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Resend Email',
                        style: TextStyle(color: Colors.black,
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Waiting for verification...',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 10),
                const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      color: kGreen, strokeWidth: 2),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}