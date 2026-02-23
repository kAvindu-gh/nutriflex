import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final bool _obscurePassword = true;

  final Color primaryGreen = const Color(0xFF1ED760);
  final Color fieldFill = Colors.white.withOpacity(0.1);

  Future<void> _resetPassword() async {
  if (_emailController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enter your email first')),
    );
    return;
  }

  await FirebaseAuth.instance.sendPasswordResetEmail(
    email: _emailController.text.trim(),
  );

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Password reset email sent')),
  );
}


  Future<void> _loginUser() async {
  try {
    final userCredential =
        await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    final user = userCredential.user;

    if (user == null) return;

    // 🔄 Refresh user state
    await user.reload();
    final refreshedUser = FirebaseAuth.instance.currentUser;

    if (!refreshedUser!.emailVerified) {
      await FirebaseAuth.instance.signOut();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify your email before logging in'),
        ),
      );
      return;
    }

    // ✅ Email verified → Go to Home
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  } on FirebaseAuthException catch (e) {
    String message = 'Login failed';

    if (e.code == 'user-not-found') {
      message = 'No account found with this email';
    } else if (e.code == 'wrong-password') {
      message = 'Incorrect password';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 60),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.restaurant, size: 40),
                ),

                const SizedBox(height: 40),

                _buildTextField(
                  controller: _emailController,
                  hint: "Email",
                  icon: Icons.email_outlined,
                ),

                const SizedBox(height: 20),

                _buildTextField(
                  controller: _passwordController,
                  hint: "Password",
                  icon: Icons.password_outlined,
                  isPassword: true,
                ),

                const SizedBox(height: 30),
                // ✅ Sign In Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _loginUser();
                      }
                    },
                    child: const Text("Sign in"),
                  ),
                ),

                const SizedBox(height: 10),

                // ✅ Forgot Password Button
                TextButton(
                  onPressed: _resetPassword,
                  child: Text(
                    "Forgot Password ?",
                    style: TextStyle(color: primaryGreen),
                  ),
                ),

                ],
              ),
            ),
          ),
        ),
      );
    }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      style: const TextStyle(color: Colors.white),
      validator: (value) {
        if (value == null || value.isEmpty) return '$hint is required';
        if (hint == "Email" && !value.contains('@')) return 'Invalid email';
        if (hint == "Password" && value.length < 6) return 'Min 6 characters';
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: primaryGreen),
        filled: true,
        fillColor: fieldFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
