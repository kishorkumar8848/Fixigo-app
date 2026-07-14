import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'admin_main_screen.dart';
import 'app_routes.dart';
import 'session.dart';
import 'technician_main_screen.dart';

/// Premium brand-reveal splash / landing screen (RentoMojo-style).
///
/// Drop custom assets later via [logoChild]:
/// ```dart
/// FixigoLandingScreen(
///   logoChild: SvgPicture.asset('assets/images/logo.svg', width: 48, height: 48),
/// )
/// ```
class FixigoLandingScreen extends StatefulWidget {
  /// Optional custom logo widget (SVG / Image). Falls back to wrench icon.
  final Widget? logoChild;

  /// Called after the brand reveal finishes (before default route handling).
  final Future<void> Function()? onRevealComplete;

  /// How long to hold the finished reveal before navigating onward.
  final Duration holdDuration;

  /// When true (default), routes to session home / role selection after hold.
  final bool handleNavigation;

  const FixigoLandingScreen({
    super.key,
    this.logoChild,
    this.onRevealComplete,
    this.holdDuration = const Duration(milliseconds: 900),
    this.handleNavigation = true,
  });

  @override
  State<FixigoLandingScreen> createState() => _FixigoLandingScreenState();
}

class _FixigoLandingScreenState extends State<FixigoLandingScreen>
    with TickerProviderStateMixin {
  static const Color _brandBlue = Color(0xFF0C6BFA);

  late final AnimationController _logoController;
  late final AnimationController _contentController;

  late final Animation<double> _logoScale;
  late final Animation<double> _brandOpacity;
  late final Animation<Offset> _brandSlide;
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset> _taglineSlide;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: _brandBlue,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    // Phase 1 — logo pop with bounce
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    // Phase 2 — brand + tagline fade/slide (staggered, 600ms)
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _brandOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    _brandSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.28, 1.0, curve: Curves.easeOut),
      ),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.45),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.28, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _runRevealSequence();
  }

  Future<void> _runRevealSequence() async {
    await _logoController.forward();
    if (!mounted) return;
    await _contentController.forward();
    if (!mounted) return;

    await Future.delayed(widget.holdDuration);
    if (!mounted) return;

    if (widget.onRevealComplete != null) {
      await widget.onRevealComplete!();
    }

    if (!mounted || !widget.handleNavigation) return;
    await _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Session.loadFromDisk();
    if (!mounted) return;

    if (Session.token != null && Session.role != null) {
      if (Session.role == 'customer') {
        Navigator.pushReplacementNamed(context, AppRoutes.userHome);
      } else if (Session.role == 'technician') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TechnicianMainScreen()),
        );
      } else if (Session.role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminMainScreen()),
        );
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
      }
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _brandBlue,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Abstract tech accents (background layer)
          const Positioned.fill(
            child: CustomPaint(
              painter: _FixigoAccentPainter(),
            ),
          ),

          // Optional: swap for a full-bleed background asset later
          // Positioned.fill(
          //   child: Opacity(
          //     opacity: 0.08,
          //     child: Image.asset('assets/images/landing_bg.png', fit: BoxFit.cover),
          //   ),
          // ),

          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Phase 1 — logo container
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoScale.value,
                        child: child,
                      );
                    },
                    child: _LogoMark(child: widget.logoChild),
                  ),

                  const SizedBox(height: 28),

                  // Phase 2 — brand name
                  AnimatedBuilder(
                    animation: _contentController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _brandOpacity,
                        child: SlideTransition(
                          position: _brandSlide,
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      'fixigo',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1.2,
                        height: 1.0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Phase 2 (staggered) — tagline pill
                  AnimatedBuilder(
                    animation: _contentController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _taglineOpacity,
                        child: SlideTransition(
                          position: _taglineSlide,
                          child: child,
                        ),
                      );
                    },
                    child: const _TaglinePill(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  final Widget? child;

  const _LogoMark({this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24), // squircle-like
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: child ??
            const Icon(
              Icons.handyman_rounded,
              size: 48,
              color: Color(0xFF0C6BFA),
            ),
      ),
    );
  }
}

class _TaglinePill extends StatelessWidget {
  const _TaglinePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Text(
        'Repair. Resell. Relax.',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// Ultra-subtle geometric / organic accents for premium depth.
class _FixigoAccentPainter extends CustomPainter {
  const _FixigoAccentPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final soft = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: 0.045);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withValues(alpha: 0.07);

    // Soft organic blob — top-right
    final blobTop = Path()
      ..moveTo(size.width * 0.62, -size.height * 0.02)
      ..cubicTo(
        size.width * 1.05,
        size.height * 0.05,
        size.width * 1.1,
        size.height * 0.32,
        size.width * 0.78,
        size.height * 0.28,
      )
      ..cubicTo(
        size.width * 0.52,
        size.height * 0.24,
        size.width * 0.48,
        size.height * 0.02,
        size.width * 0.62,
        -size.height * 0.02,
      )
      ..close();
    canvas.drawPath(blobTop, soft);

    // Soft organic blob — bottom-left
    final blobBottom = Path()
      ..moveTo(-size.width * 0.08, size.height * 0.72)
      ..cubicTo(
        size.width * 0.1,
        size.height * 0.58,
        size.width * 0.42,
        size.height * 0.88,
        size.width * 0.28,
        size.height * 1.05,
      )
      ..cubicTo(
        size.width * 0.05,
        size.height * 1.12,
        -size.width * 0.15,
        size.height * 0.92,
        -size.width * 0.08,
        size.height * 0.72,
      )
      ..close();
    canvas.drawPath(blobBottom, soft);

    // Concentric tech rings — behind logo zone
    final center = Offset(size.width * 0.5, size.height * 0.42);
    canvas.drawCircle(center, size.width * 0.28, ring);
    canvas.drawCircle(center, size.width * 0.42, ring);

    // Thin arc accent — upper left
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.08);
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.12, size.height * 0.22),
        radius: size.width * 0.22,
      ),
      0.4,
      1.8,
      false,
      arcPaint,
    );

    // Subtle diamond / node accents
    final node = Paint()..color = Colors.white.withValues(alpha: 0.09);
    void drawDiamond(Offset c, double s) {
      final path = Path()
        ..moveTo(c.dx, c.dy - s)
        ..lineTo(c.dx + s, c.dy)
        ..lineTo(c.dx, c.dy + s)
        ..lineTo(c.dx - s, c.dy)
        ..close();
      canvas.drawPath(path, node);
    }

    drawDiamond(Offset(size.width * 0.18, size.height * 0.68), 5);
    drawDiamond(Offset(size.width * 0.86, size.height * 0.58), 4);
    drawDiamond(Offset(size.width * 0.78, size.height * 0.78), 3.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
