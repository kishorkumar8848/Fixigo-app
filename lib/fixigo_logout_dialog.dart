import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shows the premium Fixigo logout confirmation dialog.
/// Returns `true` if the user confirms logout, otherwise `false` / `null`.
Future<bool?> showFixigoLogoutDialog(BuildContext context) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Logout',
    barrierColor: const Color(0xFF0C6BFA).withValues(alpha: 0.92),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, anim1, anim2) {
      return const SafeArea(
        child: Center(
          child: FixigoLogoutDialog(),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class FixigoLogoutDialog extends StatelessWidget {
  const FixigoLogoutDialog({super.key});

  static const Color brandBlue = Color(0xFF0C6BFA);
  static const Color logoutRed = Color(0xFFE53935);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width > 420 ? 340.0 : width * 0.86;

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: cardWidth,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // Main white card
            Container(
              width: cardWidth,
              margin: const EdgeInsets.only(top: 28),
              padding: const EdgeInsets.fromLTRB(22, 46, 22, 22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sad technician illustration
                  SizedBox(
                    height: 148,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _SadTechnicianPainter(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Taking a break?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A1A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Are you sure you want to log out of Fixigo?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF2D2D2D),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brandBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            child: Text(
                              "Wait, I'll stay",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: logoutRed,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            child: Text(
                              'Yes, Log out',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Overlapping wrench badge at top
            Positioned(
              top: 0,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: brandBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.build_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cartoon-style sad technician with toolbox — matches the Fixigo logout mock.
class _SadTechnicianPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.48;
    final blue = const Color(0xFF0C6BFA);
    final blueDark = const Color(0xFF0956D0);
    final skin = const Color(0xFFFFDBAC);
    final skinShadow = const Color(0xFFE8C49A);
    final grey = const Color(0xFF9E9E9E);
    final greyDark = const Color(0xFF757575);
    final shirt = const Color(0xFFE8E8E8);

    // Soft ground shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, size.height * 0.92),
        width: size.width * 0.55,
        height: 14,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.06),
    );

    // Toolbox
    final boxLeft = cx - 8;
    final boxTop = size.height * 0.62;
    final boxRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(boxLeft, boxTop, 70, 42),
      const Radius.circular(6),
    );
    canvas.drawRRect(boxRect, Paint()..color = grey);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(boxLeft, boxTop, 70, 12),
        const Radius.circular(6),
      ),
      Paint()..color = greyDark,
    );
    // Wrench peeking from toolbox
    final peek = Paint()
      ..color = greyDark
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(boxLeft + 48, boxTop - 10),
      Offset(boxLeft + 58, boxTop + 8),
      peek,
    );
    canvas.drawCircle(Offset(boxLeft + 46, boxTop - 12), 5, Paint()..color = greyDark);

    // Legs / overalls bottom
    final overall = Paint()..color = blue;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx - 18, size.height * 0.78),
          width: 22,
          height: 36,
        ),
        const Radius.circular(6),
      ),
      overall,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx + 6, size.height * 0.78),
          width: 22,
          height: 36,
        ),
        const Radius.circular(6),
      ),
      overall,
    );

    // Shoes
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 18, size.height * 0.90), width: 26, height: 10),
      Paint()..color = const Color(0xFF424242),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 6, size.height * 0.90), width: 26, height: 10),
      Paint()..color = const Color(0xFF424242),
    );

    // Body / overalls torso
    final torso = Path()
      ..moveTo(cx - 34, size.height * 0.42)
      ..lineTo(cx + 30, size.height * 0.42)
      ..lineTo(cx + 26, size.height * 0.68)
      ..lineTo(cx - 30, size.height * 0.68)
      ..close();
    canvas.drawPath(torso, overall);

    // Shirt panel
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 16, size.height * 0.43, 28, 22),
        const Radius.circular(4),
      ),
      Paint()..color = shirt,
    );

    // Overall straps
    final strap = Paint()
      ..color = blueDark
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - 12, size.height * 0.36),
      Offset(cx - 18, size.height * 0.48),
      strap,
    );
    canvas.drawLine(
      Offset(cx + 10, size.height * 0.36),
      Offset(cx + 14, size.height * 0.48),
      strap,
    );

    // Arms
    canvas.drawCircle(Offset(cx - 38, size.height * 0.52), 10, Paint()..color = skin);
    canvas.drawCircle(Offset(cx + 34, size.height * 0.50), 10, Paint()..color = skin);

    // Left arm holding wrench
    final armPaint = Paint()
      ..color = blue
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - 28, size.height * 0.46),
      Offset(cx - 42, size.height * 0.58),
      armPaint,
    );
    // Wrench in hand
    final wrench = Paint()
      ..color = const Color(0xFFB0BEC5)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - 52, size.height * 0.52),
      Offset(cx - 36, size.height * 0.64),
      wrench,
    );
    canvas.drawCircle(
      Offset(cx - 54, size.height * 0.50),
      7,
      Paint()..color = const Color(0xFF90A4AE),
    );

    // Right arm resting on toolbox
    canvas.drawLine(
      Offset(cx + 24, size.height * 0.46),
      Offset(cx + 38, size.height * 0.58),
      armPaint,
    );

    // Neck
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 2, size.height * 0.36), width: 16, height: 12),
        const Radius.circular(4),
      ),
      Paint()..color = skinShadow,
    );

    // Head
    final headCenter = Offset(cx - 2, size.height * 0.26);
    canvas.drawCircle(headCenter, 22, Paint()..color = skin);

    // Cap
    final capPath = Path()
      ..moveTo(cx - 24, size.height * 0.22)
      ..quadraticBezierTo(cx - 2, size.height * 0.08, cx + 20, size.height * 0.22)
      ..lineTo(cx + 22, size.height * 0.26)
      ..quadraticBezierTo(cx - 2, size.height * 0.18, cx - 26, size.height * 0.26)
      ..close();
    canvas.drawPath(capPath, Paint()..color = blue);
    // Cap brim
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + 8, size.height * 0.24),
        width: 36,
        height: 8,
      ),
      Paint()..color = blueDark,
    );

    // Sad eyes (closed / downturned)
    final eyePaint = Paint()
      ..color = const Color(0xFF333333)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    // Left eye
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx - 10, size.height * 0.26), width: 10, height: 8),
      0.2,
      2.6,
      false,
      eyePaint,
    );
    // Right eye
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx + 6, size.height * 0.26), width: 10, height: 8),
      0.2,
      2.6,
      false,
      eyePaint,
    );

    // Sad mouth
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx - 2, size.height * 0.34), width: 14, height: 10),
      3.5,
      2.4,
      false,
      eyePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
