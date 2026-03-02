import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/profile_api_service.dart';
import '../services/user_session.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  static const Color kGreen = Color(0xFF22C55E);
  static const Color kBg = Color(0xFF000000);
  static const Color kCard = Color(0xFF111111);

  String? _userId;
  String fullName = "";
  String mobile = "";
  String? email;
  String? birthday;
  String? gender;
  String? profilePicUrl;
  bool _isLoading = true;
  String? _error;

  // ── Animation controllers 
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _avatarController;
  late AnimationController _staggerController;

  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _avatarScaleAnim;
  late Animation<double> _avatarFadeAnim;

  // Staggered animations for each row
  late List<Animation<Offset>> _rowSlideAnims;
  late List<Animation<double>> _rowFadeAnims;

  // ── Toast overlay 
  OverlayEntry? _toastEntry;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _avatarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _avatarScaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _avatarController, curve: Curves.elasticOut),
    );
    _avatarFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _avatarController,
          curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    // 6 rows — each staggers 80ms apart
    _rowSlideAnims = List.generate(6, (i) {
      final start = i * 0.1;
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0.08, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _staggerController,
        curve: Interval(start, end, curve: Curves.easeOut),
      ));
    });

    _rowFadeAnims = List.generate(6, (i) {
      final start = i * 0.1;
      final end = (start + 0.35).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, end, curve: Curves.easeIn),
        ),
      );
    });

    _loadProfile();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _avatarController.dispose();
    _staggerController.dispose();
    _toastEntry?.remove();
    super.dispose();
  }

  // ── Load profile 
  Future<void> _loadProfile() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      _userId = "lDbTtG0CgdO7aDvFzZIl8UqXJFF3";
      final data = await ProfileApiService.getProfile(_userId!);
      _applyProfileData(data);
      _fadeController.forward();
      _slideController.forward();
      _avatarController.forward();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _staggerController.forward();
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }


  void _applyProfileData(Map<String, dynamic> data) {
    setState(() {
      fullName = data['fullName'] ?? '';
      email = data['email'];
      mobile = data['mobile'] ?? '';
      birthday = data['birthday'];
      gender = data['gender'];
      profilePicUrl = data['profile_pic_url'];
    });
  }

  Future<void> _updateField(Map<String, dynamic> fields) async {
    if (_userId == null) return;
    try {
      final data = await ProfileApiService.updateProfile(_userId!, fields);
      _applyProfileData(data);
      _showToast("Saved successfully", isSuccess: true);
    } catch (e) {
      _showToast(e.toString().replaceAll('Exception: ', ''), isSuccess: false);
    }
  }


  Future<void> _deleteField(String field) async {
    if (_userId == null) return;
    try {
      final data = await ProfileApiService.deleteField(_userId!, field);
      _applyProfileData(data);
      _showToast("${_fieldLabel(field)} removed", isSuccess: true);
    } catch (e) {
      _showToast(e.toString().replaceAll('Exception: ', ''), isSuccess: false);
    }
  }

  String _fieldLabel(String field) {
    switch (field) {
      case 'mobile': return 'Mobile';
      case 'birthday': return 'Birthday';
      case 'gender': return 'Gender';
      case 'profile_pic_url': return 'Profile picture';
      default: return field;
    }
  }

  // ── Floating toast 
  void _showToast(String message, {required bool isSuccess}) {
    _toastEntry?.remove();
    _toastEntry = null;
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        message: message,
        isSuccess: isSuccess,
        onDone: () {
          entry.remove();
          if (_toastEntry == entry) _toastEntry = null;
        },
      ),
    );
    _toastEntry = entry;
    overlay.insert(entry);
  }

  // ── Image picker 
  Future<void> _onPickImage() async {
    if (profilePicUrl != null) {
      _showImageOptions();
    } else {
      await _pickFromGallery();
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181818),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetHandle(),
            const SizedBox(height: 8),
            const Text("Profile Picture",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF1A3A26),
                child: Icon(Icons.photo_library_outlined, color: kGreen),
              ),
              title: const Text("Change photo", style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickFromGallery();
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF2A1010),
                child: Icon(Icons.delete_outline, color: Colors.redAccent),
              ),
              title: const Text("Remove photo", style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(
                  label: "profile picture",
                  onConfirm: () => _deleteField('profile_pic_url'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked == null) return;
    _showToast("Uploading...", isSuccess: true);
    try {
      final data = await ProfileApiService.uploadProfilePicture(_userId!, File(picked.path));
      _applyProfileData(data);
      _showToast("Profile picture updated", isSuccess: true);
    } catch (e) {
      _showToast(e.toString().replaceAll('Exception: ', ''), isSuccess: false);
    }
  }


  void _confirmDelete({required String label, required VoidCallback onConfirm}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181818),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetHandle(),
            const SizedBox(height: 12),
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever_outlined,
                  color: Colors.redAccent, size: 32),
            ),
            const SizedBox(height: 16),
            Text("Remove $label?",
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text("This will permanently clear your $label.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("Remove", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // UI BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFF000302),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ── Radial gradient background (103E23 → 000302 → 000503) 
          Positioned.fill(
            child: CustomPaint(painter: _RadialBgPainter()),
          ),
          // ── Main content 
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: kGreen))
              : _error != null
                  ? _buildErrorState()
                  : FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: _buildBody(),
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
      slivers: [
        // ── Transparent collapsing header 
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          stretch: true,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [StretchMode.zoomBackground],
            background: _buildHeaderBackground(),
          ),
          // Transparent frosted glass app bar when collapsed
          bottom: PreferredSize(
            preferredSize: Size.zero,
            child: Container(),
          ),
          title: _buildCollapsedTitle(),
          leading: _buildBackButton(),
        ),

        // ── Content 
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),
              _buildSectionLabel("YOUR INFORMATION"),
              const SizedBox(height: 12),
              _buildInfoCard(),
              const SizedBox(height: 36),
              _buildLogoutButton(),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  "App Version 0.1",
                  style: TextStyle(color: Colors.grey.shade800, fontSize: 12),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Transparent — radial bg from Scaffold shows through
        Container(color: Colors.transparent),

        // Subtle extra glow right behind avatar
        Positioned(
          top: 40, left: 0, right: 0,
          child: Center(
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF103E23).withOpacity(0.45),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        // Avatar + name
        Positioned(
          bottom: 20, left: 0, right: 0,
          child: Column(
            children: [
              ScaleTransition(
                scale: _avatarScaleAnim,
                child: FadeTransition(
                  opacity: _avatarFadeAnim,
                  child: GestureDetector(
                    onTap: _onPickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 110, height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1A1A1A),
                            border: Border.all(
                              color: kGreen.withOpacity(0.6),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: kGreen.withOpacity(0.15),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: profilePicUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    profilePicUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        Icons.person, color: Colors.white38, size: 50),
                                  ),
                                )
                              : const Icon(Icons.person,
                                  color: Colors.white38, size: 50),
                        ),
                        Positioned(
                          bottom: 4, right: 4,
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: kGreen,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.transparent, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FadeTransition(
                opacity: _avatarFadeAnim,
                child: Text(
                  fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FadeTransition(
                opacity: _avatarFadeAnim,
                child: Text(
                  email ?? '',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Frosted glass title shown when header is collapsed
  Widget _buildCollapsedTitle() {
    return const SizedBox.shrink(); 
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 25, top: 10),
      child: GestureDetector(
        onTap: () {
          // Navigates back to previous page (notifications or wherever this was pushed from)
          Navigator.maybePop(context);
        },
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF0D2818),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kGreen.withOpacity(0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: kGreen.withOpacity(0.15),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(Icons.arrow_back_ios_new,
              color: kGreen, size: 16),
        ),
      ),
    );
  }

  // ── Section label 
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
        ),
      ),
    );
  }

  // ── Info card with staggered rows ──────────────────────────────────────────
  Widget _buildInfoCard() {
    final rows = [
      // 0 — profile picture
      _buildRow(
        index: 0,
        icon: Icons.camera_alt_outlined,
        title: "Profile Picture",
        value: profilePicUrl != null ? "Tap to change or remove" : "Not set",
        valueColor: profilePicUrl != null ? kGreen : Colors.grey.shade700,
        trailingIcon: Icons.add_a_photo_outlined,
        onTap: _onPickImage,
        showDivider: true,
      ),
      // 1 — full name
      _buildRow(
        index: 1,
        icon: Icons.person_outline_rounded,
        title: "Full Name",
        value: fullName.isEmpty ? "Not set" : fullName,
        valueColor: fullName.isEmpty ? Colors.grey.shade700 : kGreen,
        trailingIcon: Icons.edit_outlined,
        onTap: () => _showEditSheet(
          fieldLabel: "Full Name",
          currentValue: fullName,
          canDelete: false,
          onSave: (val) => _updateField({'fullName': val}),
        ),
        showDivider: true,
      ),
      // 2 — mobile
      _buildRow(
        index: 2,
        icon: Icons.smartphone_rounded,
        title: "Mobile",
        value: mobile.isEmpty ? "Not set" : mobile,
        valueColor: mobile.isEmpty ? Colors.grey.shade700 : kGreen,
        trailingIcon: Icons.phone_outlined,
        onTap: () => _showEditSheet(
          fieldLabel: "Mobile",
          currentValue: mobile,
          hintText: "e.g. 072 222 2222",
          keyboardType: TextInputType.phone,
          canDelete: mobile.isNotEmpty,
          onSave: (val) {
            // Clean input — remove spaces and dashes
            final cleaned = val.replaceAll(RegExp(r'[\s\-()]'), '');
            // Auto-add +94 if user typed local format like 07x
            String formatted = cleaned;
            if (cleaned.startsWith('0') && cleaned.length == 10) {
              formatted = '+94${cleaned.substring(1)}';
            } else if (!cleaned.startsWith('+')) {
              formatted = '+$cleaned';
            }
            _updateField({'mobile': formatted});
          },
          onDelete: () => _confirmDelete(
            label: "mobile number",
            onConfirm: () => _deleteField('mobile'),
          ),
        ),
        showDivider: true,
      ),
      // 3 — email
      _buildRow(
        index: 3,
        icon: Icons.alternate_email_rounded,
        title: "E-mail",
        value: (email == null || email!.isEmpty) ? "Not set" : email!,
        valueColor: (email == null || email!.isEmpty) ? Colors.grey.shade700 : kGreen,
        trailingIcon: Icons.mail_outline_rounded,
        onTap: () => _showEditSheet(
          fieldLabel: "E-mail",
          currentValue: email ?? "",
          keyboardType: TextInputType.emailAddress,
          canDelete: false,
          onSave: (val) => _updateField({'email': val}),
        ),
        showDivider: true,
      ),
      // 4 — birthday
      _buildRow(
        index: 4,
        icon: Icons.cake_outlined,
        title: "Birthday",
        value: birthday ?? "Not set",
        valueColor: birthday == null ? Colors.grey.shade700 : kGreen,
        trailingIcon: Icons.edit_calendar_outlined,
        onTap: _onPickBirthday,
        showDivider: true,
        onLongPress: birthday != null
            ? () => _confirmDelete(
                  label: "birthday",
                  onConfirm: () => _deleteField('birthday'),
                )
            : null,
      ),
      // 5 — gender
      _buildRow(
        index: 5,
        icon: Icons.people_outline_rounded,
        title: "Gender",
        value: gender == null
            ? "Not set"
            : gender![0].toUpperCase() + gender!.substring(1),
        valueColor: gender == null ? Colors.grey.shade700 : kGreen,
        trailingIcon: Icons.expand_more_rounded,
        onTap: _onSelectGender,
        showDivider: false,
      ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF103E23).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: kGreen.withOpacity(0.35),
              width: 1,
            ),
          ),
          child: Column(children: rows),
        ),
      ),
    );
  }

  // ── Single animated row 
  Widget _buildRow({
    required int index,
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
    required IconData trailingIcon,
    required VoidCallback onTap,
    required bool showDivider,
    VoidCallback? onLongPress,
  }) {
    return SlideTransition(
      position: _rowSlideAnims[index],
      child: FadeTransition(
        opacity: _rowFadeAnims[index],
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                onLongPress: onLongPress,
                borderRadius: BorderRadius.circular(20),
                splashColor: kGreen.withOpacity(0.06),
                highlightColor: kGreen.withOpacity(0.03),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 17),
                  child: Row(
                    children: [
                      // Icon container
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: kGreen.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: kGreen, size: 18),
                      ),
                      const SizedBox(width: 14),
                      // Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 3),
                            Text(value,
                                style: TextStyle(
                                    color: valueColor ?? Colors.grey.shade700,
                                    fontSize: 12.5)),
                          ],
                        ),
                      ),
                      // Trailing icon
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(trailingIcon,
                            color: Colors.grey.shade700, size: 15),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (showDivider)
              Divider(
                color: Colors.white.withOpacity(0.04),
                height: 1,
                indent: 72,
                endIndent: 20,
              ),
          ],
        ),
      ),
    );
  }

  // ── Logout button 
  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _onLogout,
          style: ElevatedButton.styleFrom(
            backgroundColor: kGreen,
            shadowColor: kGreen.withOpacity(0.3),
            elevation: 4,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text(
            "Logout",
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  void _showEditSheet({
    required String fieldLabel,
    required String currentValue,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
    required bool canDelete,
    required void Function(String) onSave,
    VoidCallback? onDelete,
  }) {
    final controller = TextEditingController(text: currentValue);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181818),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHandle(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Edit $fieldLabel",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                  if (canDelete && onDelete != null)
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        onDelete();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.red.withOpacity(0.3)),
                        ),
                        child: const Text("Remove",
                            style: TextStyle(
                                color: Colors.redAccent, fontSize: 12)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                keyboardType: keyboardType,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: kGreen,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  hintText: hintText ?? "Enter $fieldLabel",
                  hintStyle: TextStyle(color: Colors.grey.shade700),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: kGreen, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    final val = controller.text.trim();
                    if (val.isEmpty && !canDelete) {
                      _showToast("$fieldLabel cannot be empty",
                          isSuccess: false);
                      return;
                    }
                    Navigator.pop(ctx);
                    onSave(val);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text("Save",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Birthday picker
  Future<void> _onPickBirthday() async {
    if (birthday != null) {
      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF181818),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),
              const Text("Birthday",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF1A3A26),
                  child: Icon(Icons.edit_calendar_outlined, color: kGreen),
                ),
                title: const Text("Change birthday",
                    style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _showDatePickerDialog();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF2A1010),
                  child: Icon(Icons.delete_outline, color: Colors.redAccent),
                ),
                title: const Text("Remove birthday",
                    style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(
                    label: "birthday",
                    onConfirm: () => _deleteField('birthday'),
                  );
                },
              ),
            ],
          ),
        ),
      );
    } else {
      await _showDatePickerDialog();
    }
  }

  Future<void> _showDatePickerDialog() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: kGreen,
            surface: Color(0xFF181818),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final formatted =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      _updateField({'birthday': formatted});
    }
  }

  // ── Gender picker
  void _onSelectGender() {
    final options = ["male", "female"];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181818),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetHandle(),
            const Text("Select Gender",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...options.map((option) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: gender == option ? kGreen : Colors.grey.shade700,
                        width: 2,
                      ),
                      color: gender == option
                          ? kGreen.withOpacity(0.2)
                          : Colors.transparent,
                    ),
                    child: gender == option
                        ? const Icon(Icons.check, color: kGreen, size: 14)
                        : null,
                  ),
                  title: Text(
                    option[0].toUpperCase() + option.substring(1),
                    style: TextStyle(
                      color: gender == option ? kGreen : Colors.white,
                      fontWeight: gender == option
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _updateField({'gender': option});
                  },
                )),
            if (gender != null) ...[
              Divider(color: Colors.white.withOpacity(0.06)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_outline,
                    color: Colors.redAccent, size: 20),
                title: const Text("Remove gender",
                    style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(
                    label: "gender",
                    onConfirm: () => _deleteField('gender'),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Logout
  void _onLogout() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181818),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetHandle(),
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded,
                  color: Colors.redAccent, size: 30),
            ),
            const SizedBox(height: 16),
            const Text("Logout",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Are you sure you want to logout?",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("Cancel",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const Center(
                          child: CircularProgressIndicator(color: kGreen),
                        ),
                      );
                      await UserSession.logout(_userId ?? '');
                      if (context.mounted) Navigator.pop(context);
                      if (context.mounted) {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("Logout",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Reusable sheet handle
  Widget _sheetHandle() {
    return Center(
      child: Container(
        width: 36, height: 4,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // ── Error state
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline,
                  color: Colors.redAccent, size: 36),
            ),
            const SizedBox(height: 20),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Radial gradient background painter
class _RadialBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Main radial gradient — centered slightly above middle (where avatar is)
    final center = Offset(size.width / 2, size.height * 0.28);
    final radius = size.width * 1.1;

    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: const [
          Color(0xFF103E23), // 0% — dark green center
          Color(0xFF000302), // 99% — near black
          Color(0xFF000503), // 100% — deep black
        ],
        stops: const [0.0, 0.72, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Animated floating toast
class _ToastWidget extends StatefulWidget {
  final String message;
  final bool isSuccess;
  final VoidCallback onDone;

  const _ToastWidget({
    required this.message,
    required this.isSuccess,
    required this.onDone,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2500), () async {
      if (mounted) {
        await _ctrl.reverse();
        widget.onDone();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 80,   // pushed right so it clears the back button
      right: 60,  // narrower width
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _opacity,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: widget.isSuccess
                    ? const Color(0xFF0D2818)
                    : const Color(0xFF2A0D0D),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.isSuccess ? const Color(0xFF22C55E) : Colors.redAccent,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (widget.isSuccess
                            ? const Color(0xFF22C55E)
                            : Colors.redAccent)
                        .withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    widget.isSuccess
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    color: widget.isSuccess
                        ? const Color(0xFF22C55E)
                        : Colors.redAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.message,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}