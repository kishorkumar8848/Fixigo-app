import 'package:flutter/material.dart';

import 'fixigo_landing_screen.dart';

/// App entry splash — delegates to the premium [FixigoLandingScreen] brand reveal.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FixigoLandingScreen();
  }
}
