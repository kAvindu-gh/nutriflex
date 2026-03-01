import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String fullName = "John Bonfield";
  String phone = "+94 76 807 6464";
  String? email;
  DateTime? birthday;
  String? gender;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13), // Bg Color
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(
                'https://example.com/monkey-avatar.jpg', // ← replace with real URL or Asset
              ),
              backgroundColor: Colors.grey,
            ),
            SizedBox(width: 12),
            Text(
              'Senuja Rasmina',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Your Information',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // profile
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey,
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white54,
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFF22C55E),
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, size: 18),
                            color: Colors.white,
                            onPressed: () {
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Add profile picture",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Fname
            _buildFieldTile(
              icon: Icons.person_outline,
              title: "Full Name",
              value: fullName,
              onTap: () {
              },
            ),

            // Mobile
            _buildFieldTile(
              icon: Icons.phone_android_outlined,
              title: "Mobile",
              value: phone,
              onTap: () {
              },
            ),

            // E-mail
            _buildFieldTile(
              icon: Icons.mail_outline,
              title: "E-mail",
              value: email ?? 'Add your e-mail',
              valueColor: email == null ? Colors.grey : null,
              onTap: () {
              },
            ),

            // Birthday.
            _buildFieldTile(
              icon: Icons.cake_outlined,
              title: 'Birthday',
              value: birthday == null
                  ? 'Add your birthday'
                  : "${birthday!.day}/${birthday!.month}/${birthday!.year}",
              valueColor: birthday == null ? Colors.grey : null,
              onTap: () async {
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldTile({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF22C55E)),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white70,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
