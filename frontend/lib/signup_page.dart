import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final Color primaryGreen = const Color(0xFF1ED760);

  bool _loading = false;

  Future<void> _createAccount() async {
    if (_nameController.text.trim().isEmpty) {
      _showMessage("Please enter your full name");
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      _showMessage("Please enter your email address");
      return;
    }

    if (!_emailController.text.contains("@")) {
      _showMessage("Please enter a valid email address");
      return;
    }

    if (_passwordController.text.trim().isEmpty) {
      _showMessage("Please enter your password");
      return;
    }

    if (_passwordController.text.length < 6) {
      _showMessage("Password must be at least 6 characters");
      return;
    }

    setState(() => _loading = true);

    try {
      UserCredential cred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await cred.user!.sendEmailVerification();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'createdAt': Timestamp.now(),
        'emailVerified': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent. Check your inbox.'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _inputField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: primaryGreen),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              IconButton(
                icon: Icon(Icons.arrow_back, color: primaryGreen),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),

              const SizedBox(height: 10),

              const Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                "Start your premium fitness journey",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 30),

              _inputField(
                controller: _nameController,
                icon: Icons.person,
                hint: "Full Name",
              ),

              const SizedBox(height: 16),

              _inputField(
                controller: _emailController,
                icon: Icons.email,
                hint: "Email",
              ),

              const SizedBox(height: 16),

              _inputField(
                controller: _passwordController,
                icon: Icons.lock,
                hint: "Password",
                obscure: true,
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _createAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          "Create Account",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                    children: [
                      const TextSpan(
                        text: "By signing up, you agree to our ",
                      ),
                      TextSpan(
                        text: "Terms & Privacy",
                        style: TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // clickable only (no action)
                          },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

