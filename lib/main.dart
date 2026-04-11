import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_theme.dart';
import 'splash_screen.dart';
import 'role_selection.dart';
import 'customer_auth_screen.dart';
import 'technician_auth_screen.dart';
import 'admin_login_screen.dart';
import 'user_main_screen.dart';
import 'technician_login_screen.dart';
import 'app_routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const FixigoApp());
}

class FixigoApp extends StatelessWidget {
  const FixigoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fixigo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.roleSelection: (_) => const RoleSelectionScreen(),
        AppRoutes.customerAuth: (_) => const CustomerAuthScreen(),
        AppRoutes.technicianAuth: (_) => const TechnicianAuthScreen(),
        AppRoutes.adminLogin: (_) => const AdminLoginScreen(),
        AppRoutes.userHome: (_) => const UserMainScreen(),
        AppRoutes.techLogin: (_) => const TechnicianLoginScreen(),
      },
    );
  }
}
