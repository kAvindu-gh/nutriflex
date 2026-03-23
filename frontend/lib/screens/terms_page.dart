import 'package:flutter/material.dart';

class TermsPage extends StatefulWidget {
  /// If [requireAgree] is true, shows the agree checkbox + Continue button.
  /// Used from SignUpPage. If false, read-only view from login "Terms" tap.
  final bool requireAgree;
  const TermsPage({super.key, this.requireAgree = false});
  @override
  State<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage> {
  bool _agreed = false;

  static const kGreen = Color(0xFF14D97D);
  static const kBg    = Color(0xFF000302);
  static const kField = Color(0xFF111A13);

  static const _sections = [
    _TermsSection('1. Acceptance of Terms',
        'By creating an account and using NutriFlex, you agree to be bound by these Terms and Conditions. If you do not agree, please do not use the app.'),
    _TermsSection('2. User Account',
        'You are responsible for maintaining the confidentiality of your account credentials. You agree to provide accurate, current, and complete information during registration. You must be at least 13 years old to use NutriFlex.'),
    _TermsSection('3. Health Disclaimer',
        'NutriFlex provides general nutrition and fitness information for educational purposes only. The content is not intended to be a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or qualified health provider before starting any diet or exercise program.'),
    _TermsSection('4. Data Collection & Privacy',
        'We collect personal data including your name, email address, and health metrics (weight, height, age, BMI) to provide personalized nutrition planning. Your data is stored securely in Firebase and is never sold to third parties. You may request deletion of your data at any time by contacting support.'),
    _TermsSection('5. Meal Tracking & Nutrition Data',
        'NutriFlex uses USDA nutrition databases and third-party recipe APIs to provide food and nutrition data. While we strive for accuracy, we cannot guarantee that all nutritional information is complete or error-free. Calorie and macro estimates are approximations.'),
    _TermsSection('6. User-Generated Content',
        'Any meal logs, custom recipes, or notes you create within the app are your own content. You grant NutriFlex a non-exclusive license to store and process this content solely for the purpose of providing the service to you.'),
    _TermsSection('7. Prohibited Use',
        'You agree not to misuse the platform, attempt to reverse-engineer the app, scrape data, or use the service for any unlawful purpose. Accounts found in violation will be permanently suspended.'),
    _TermsSection('8. Changes to Terms',
        'NutriFlex reserves the right to update these Terms at any time. Continued use of the app after changes constitutes your acceptance of the new Terms. We will notify users of significant changes via email.'),
    _TermsSection('9. Termination',
        'You may delete your account at any time. NutriFlex reserves the right to suspend or terminate accounts that violate these Terms without prior notice.'),
    _TermsSection('10. Contact',
        'If you have any questions about these Terms, please contact us at nutriflex.contact@gmail.com'),
  ];

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
        SafeArea(
          child: Column(children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: kField,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kGreen.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.arrow_back, color: kGreen, size: 20),
                  ),
                ),
                const SizedBox(width: 16),
                const Text('Terms & Privacy',
                    style: TextStyle(color: Colors.white,
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ]),
            ),
            const SizedBox(height: 8),

            // ── Scrollable terms ──────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                itemCount: _sections.length,
                itemBuilder: (_, i) => _SectionCard(section: _sections[i]),
              ),
            ),

            // ── Agree section (only shown when requireAgree = true) ───────
            if (widget.requireAgree) ...[
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                decoration: BoxDecoration(
                  color: kField.withOpacity(0.95),
                  border: Border(
                      top: BorderSide(color: kGreen.withOpacity(0.2))),
                ),
                child: Column(children: [
                  // Agree checkbox
                  GestureDetector(
                    onTap: () => setState(() => _agreed = !_agreed),
                    child: Row(children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          color: _agreed ? kGreen : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _agreed ? kGreen : Colors.grey.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: _agreed
                            ? const Icon(Icons.check, color: Colors.black, size: 15)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'I have read and agree to the Terms & Privacy Policy',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),

                  // Continue button
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: _agreed
                          ? () => Navigator.pop(context, true) // returns true = agreed
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGreen,
                        disabledBackgroundColor: Colors.grey.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text('Continue',
                          style: TextStyle(
                            color: _agreed ? Colors.black : Colors.grey,
                            fontWeight: FontWeight.bold, fontSize: 15,
                          )),
                    ),
                  ),
                  const SizedBox(height: 8),
                ]),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _TermsSection {
  final String title, body;
  const _TermsSection(this.title, this.body);
}

class _SectionCard extends StatelessWidget {
  final _TermsSection section;
  const _SectionCard({super.key, required this.section});

  static const kGreen = Color(0xFF14D97D);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1610).withOpacity(0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(section.title,
            style: const TextStyle(
                color: kGreen, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text(section.body,
            style: const TextStyle(
                color: Colors.white70, fontSize: 13, height: 1.6)),
      ]),
    );
  }
}