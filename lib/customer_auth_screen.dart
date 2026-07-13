import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'common_widgets.dart';
import 'user_main_screen.dart';
import 'role_selection.dart';
import 'api.dart';
import 'session.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'location_picker_screen.dart';

class CustomerAuthScreen extends StatefulWidget {
  const CustomerAuthScreen({super.key});

  @override
  State<CustomerAuthScreen> createState() => _CustomerAuthScreenState();
}

class _CustomerAuthScreenState extends State<CustomerAuthScreen>
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
  final _signupAddressController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  bool _signupLoading = false;
  double? _latitude;
  double? _longitude;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

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
    _signupAddressController.dispose();
    _signupPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestAndFetchLocation() async {
    final result = await Navigator.push<LocationPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => const LocationPickerScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        _signupAddressController.text = result.address;
        _latitude = result.latitude;
        _longitude = result.longitude;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Auto-filled location: ${result.address}')),
      );
    }
  }

  Future<bool> _loginWithCredentials(String email, String password) async {
    setState(() => _loginLoading = true);

    try {
      final resp = await Api.post('/auth/customer/login', {
        'email': email,
        'password': password,
      });

      if (!mounted) return false;

      if (resp['status'] == 200) {
        final data = resp['data'];
        Session.token = data['token'];
        Session.role = 'customer';
        Session.userId = data['customerId'];
        Session.name = data['name'] ?? '';
        Session.email = data['email'] ?? email;
        Session.phone = data['phone'] ?? '';
        Session.address = data['address'] ?? '';
        if (_latitude != null) {
          Session.latitude = _latitude;
        }
                if (_longitude != null) {
          Session.longitude = _longitude;
        }

        await Session.saveToDisk();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UserMainScreen()),
        );
        return true;
      } else {
        final message = resp['data']['message'] ?? 'Login failed';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
        return false;
      }
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Unable to reach the login server. Please try again.')),
      );
      return false;
    } finally {
      if (mounted) setState(() => _loginLoading = false);
    }
  }

  Future<void> _handleLogin() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text.trim();
    await _loginWithCredentials(email, password);
  }

  Future<void> _handleSignup() async {
    setState(() => _signupLoading = true);
    final name = _signupNameController.text.trim();
    final email = _signupEmailController.text.trim();
    final phone = _signupPhoneController.text.trim();
    final address = _signupAddressController.text.trim();
    final password = _signupPasswordController.text.trim();

    try {
      final resp = await Api.post('/auth/customer/signup', {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'address': address,
      });

      if (!mounted) return;

      if (resp['status'] == 201) {
        // automatically log in using the same credentials
        final success = await _loginWithCredentials(email, password);
        if (!mounted) return;
        if (!success) {
          setState(() => _signupLoading = false);
        }
      } else {
        final message = resp['data']['message'] ?? 'Signup failed';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
        setState(() => _signupLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _signupLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      // Trigger the native Google Account chooser dialog
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate(scopeHint: ['email', 'profile']);
      if (googleUser != null) {
        final String email = googleUser.email;
        final String displayName = googleUser.displayName ?? googleUser.email.split('@')[0];
        
        await _executeGoogleLogin(email, displayName);
      }
    } catch (error) {
      // If native sign-in is not configured or fails, we fall back to the account entry dialog
      // so it works in debug emulators without manual Firebase config.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Native Google Sign-In failed: $error. Falling back to account selection.'),
          duration: const Duration(seconds: 4),
        ),
      );
      _showNewGoogleAccountDialog();
    }
  }

  void _showNewGoogleAccountDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const GoogleLogoWidget(size: 24),
              const SizedBox(width: 12),
              const Text('Google Account'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'John Doe',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'john.doe@gmail.com',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final email = emailController.text.trim();
                if (name.isEmpty || email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }
                if (!email.contains('@')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid email')),
                  );
                  return;
                }
                Navigator.pop(context);
                _executeGoogleLogin(email, name);
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _executeGoogleLogin(String email, String name) async {
    setState(() {
      _loginLoading = true;
      _signupLoading = true;
    });

    try {
      final resp = await Api.post('/auth/customer/google-login', {
        'email': email,
        'name': name,
      });

      if (!mounted) return;

      if (resp['status'] == 200) {
        final data = resp['data'];
        Session.token = data['token'];
        Session.role = 'customer';
        Session.userId = data['customerId'];
        Session.name = data['name'] ?? '';
        Session.email = data['email'] ?? email;
        Session.phone = data['phone'] ?? '';
                Session.address = data['address'] ?? '';

        await Session.saveToDisk();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UserMainScreen()),
        );
      } else {
        final message = resp['data']['message'] ?? 'Google login failed';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
        setState(() {
          _loginLoading = false;
          _signupLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() {
        _loginLoading = false;
        _signupLoading = false;
      });
    }
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed:
            (_loginLoading || _signupLoading) ? null : _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withOpacity(0.4), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const GoogleLogoWidget(size: 18),
            ),
            const SizedBox(width: 12),
            const Text(
              'Continue with Google',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
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
                      'Customer',
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
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
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
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                    child: Divider(
                                        color: Colors.white.withOpacity(0.3))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                    child: Divider(
                                        color: Colors.white.withOpacity(0.3))),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildGoogleButton(),
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
                              'Sign up to get started',
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
                              controller: _signupAddressController,
                              hintText: 'Address',
                              prefixIcon: Icons.location_on_outlined,
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.my_location_rounded,
                                    color: Colors.white70),
                                onPressed: _requestAndFetchLocation,
                              ),
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _signupPasswordController,
                              hintText: 'Password',
                              prefixIcon: Icons.lock_outline,
                              isPassword: true,
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
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                    child: Divider(
                                        color: Colors.white.withOpacity(0.3))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                    child: Divider(
                                        color: Colors.white.withOpacity(0.3))),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildGoogleButton(),
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

class GoogleLogoWidget extends StatelessWidget {
  final double size;
  const GoogleLogoWidget({super.key, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: GoogleLogoPainter(),
    );
  }
}

class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double radius = w / 2;
    final double strokeWidth = w * 0.24;
    final center = Offset(radius, radius);
    final rect =
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // 1. Red (top): 215° to 315°
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 3.75, 1.75, false, paint);

    // 2. Yellow (left): 135° to 215°
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.35, 1.4, false, paint);

    // 3. Green (bottom): 45° to 135°
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.78, 1.57, false, paint);

    // 4. Blue (right): -45° to 45°
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.78, 1.57, false, paint);

    // Draw horizontal bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    final barRect = Rect.fromLTWH(
      radius,
      radius - strokeWidth / 2,
      radius,
      strokeWidth,
    );
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
