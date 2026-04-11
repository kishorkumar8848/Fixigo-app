import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'app_theme.dart';
import 'common_widgets.dart';
import 'technician_main_screen.dart';
import 'role_selection.dart';
import 'api.dart';
import 'session.dart';

class TechnicianAuthScreen extends StatefulWidget {
  const TechnicianAuthScreen({super.key});

  @override
  State<TechnicianAuthScreen> createState() => _TechnicianAuthScreenState();
}

class _TechnicianAuthScreenState extends State<TechnicianAuthScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;

  // Login fields
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _loginLoading = false;

  // Signup fields
  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPhoneController = TextEditingController();
  final _signupSkillsController = TextEditingController();
  final _signupExperienceController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  bool _signupLoading = false;
  File? _idProofImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _idProofImage = File(pickedFile.path);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPhoneController.dispose();
    _signupSkillsController.dispose();
    _signupExperienceController.dispose();
    _signupPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _loginLoading = true);
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text.trim();

    try {
      final resp = await Api.post('/auth/technician/login', {
        'email': email,
        'password': password,
      });

      if (!mounted) return;

      if (resp['status'] == 200) {
        final data = resp['data'];
        Session.token = data['token'];
        Session.role = 'technician';
        Session.userId = data['technicianId'];
        Session.name = data['name'] ?? '';
        Session.email = data['email'] ?? email;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TechnicianMainScreen()),
        );
      } else {
        final message = resp['data']['message'] ?? 'Login failed';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
        setState(() => _loginLoading = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _loginLoading = false);
    }
  }

  Future<void> _handleSignup() async {
    setState(() => _signupLoading = true);
    final name = _signupNameController.text.trim();
    final email = _signupEmailController.text.trim();
    final phone = _signupPhoneController.text.trim();
    final skills = _signupSkillsController.text.trim();
    final experience = _signupExperienceController.text.trim();
    final password = _signupPasswordController.text.trim();

    if (_idProofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an ID Proof image')),
      );
      setState(() => _signupLoading = false);
      return;
    }

    try {
      final fields = {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'skills': skills,
        'experience': experience,
      };

      final resp = await Api.multipartPost('/auth/technician/signup', fields, 'id_proof', _idProofImage!.path);

      if (!mounted) return;

      if (resp['status'] == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signup submitted! Awaiting admin verification before login.'),
            duration: Duration(seconds: 3),
          ),
        );
        _tabController.animateTo(0);
        setState(() {
          _idProofImage = null; // clear image
          _signupLoading = false;
        });
      } else {
        final message = resp['data']['message'] ?? 'Signup failed';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
        setState(() => _signupLoading = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _signupLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar with back button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RoleSelectionScreen()),
                      ),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Technician',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Tab bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorPadding: const EdgeInsets.all(4),
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Colors.white.withOpacity(0.7),
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    tabs: const [
                      Tab(text: 'Login'),
                      Tab(text: 'Sign Up'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Tab content
              Expanded(
                child: SlideTransition(
                  position: _slideAnim,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Login Tab
                      SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome Back',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Log in to your account',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 32),
                            CustomTextField(
                              controller: _loginEmailController,
                              hintText: 'Email Address',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _loginPasswordController,
                              hintText: 'Password',
                              prefixIcon: Icons.lock_outline,
                              isPassword: true,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _loginLoading ? null : _handleLogin,
                                child: _loginLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Login',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        )),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Signup Tab
                      SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sign up to start earning',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 32),
                            CustomTextField(
                              controller: _signupNameController,
                              hintText: 'Full Name',
                              prefixIcon: Icons.person_outline,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _signupEmailController,
                              hintText: 'Email Address',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _signupPhoneController,
                              hintText: 'Phone Number',
                              prefixIcon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _signupSkillsController,
                              hintText: 'Skills (e.g., AC, Refrigerator)',
                              prefixIcon: Icons.build_circle_outlined,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _signupExperienceController,
                              hintText: 'Years of Experience',
                              prefixIcon: Icons.trending_up,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _signupPasswordController,
                              hintText: 'Password',
                              prefixIcon: Icons.lock_outline,
                              isPassword: true,
                            ),
                            const SizedBox(height: 24),
                            // ID Proof Upload UI
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                                ),
                                child: _idProofImage == null
                                  ? const Column(
                                      children: [
                                        Icon(Icons.upload_file, color: Colors.white, size: 32),
                                        SizedBox(height: 8),
                                        Text('Upload ID Proof', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.green),
                                        const SizedBox(width: 8),
                                        Text('ID Proof Selected', style: TextStyle(color: Colors.green.shade300, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '⏳ Your account will be verified by admin before first login.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.8),
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed:
                                    _signupLoading ? null : _handleSignup,
                                child: _signupLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Sign Up',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        )),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
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
