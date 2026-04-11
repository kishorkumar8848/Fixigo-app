import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'common_widgets.dart';
import 'technician_main_screen.dart';
import 'role_selection.dart';

class TechnicianLoginScreen extends StatefulWidget {
  const TechnicianLoginScreen({super.key});

  @override
  State<TechnicianLoginScreen> createState() => _TechnicianLoginScreenState();
}

class _TechnicianLoginScreenState extends State<TechnicianLoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
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
    _animController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _sendOtp() {
    setState(() {
      _loading = true;
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _otpSent = true;
          _loading = false;
        });
      }
    });
  }

  void _login() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TechnicianMainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RoleSelectionScreen())),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Technician Portal',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18)),
                  ],
                ),
              ),
              // Hero section
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.4)),
                      ),
                      child: const Icon(Icons.engineering_rounded,
                          color: Colors.white, size: 34),
                    ),
                    const SizedBox(height: 20),
                    const Text('Welcome Back,\nExpert! 👷',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.2)),
                    const SizedBox(height: 8),
                    Text(
                        'Login to access your jobs, earnings\nand performance dashboard',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 13,
                            height: 1.5)),
                  ],
                ),
              ),
              const Spacer(),
              // Login card
              SlideTransition(
                position: _slideAnim,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 40,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Login with Mobile',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      const Text('Enter your registered mobile number',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 20),
                      // Phone field
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        enabled: !_otpSent,
                        decoration: const InputDecoration(
                          prefixText: '+91 ',
                          prefixIcon: Icon(Icons.phone_rounded),
                          hintText: '9876543210',
                          labelText: 'Mobile Number',
                        ),
                      ),
                      if (_otpSent) ...[
                        const SizedBox(height: 14),
                        TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_rounded),
                            hintText: '------',
                            labelText: 'Enter OTP',
                            counterText: '',
                            suffixIcon: TextButton(
                              onPressed: () {},
                              child: const Text('Resend'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text('OTP sent to +91 •••• •• 3210',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.success)),
                      ],
                      const SizedBox(height: 20),
                      _loading
                          ? const Center(child: CircularProgressIndicator())
                          : GradientButton(
                              text: _otpSent ? 'Verify & Login' : 'Send OTP',
                              onTap: _otpSent ? _login : _sendOtp,
                              icon: Icon(
                                _otpSent
                                    ? Icons.check_rounded
                                    : Icons.send_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                      if (!_otpSent) ...[
                        const SizedBox(height: 16),
                        const Center(
                          child: Text('New technician? Contact Fixigo admin',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ),
                      ],
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
