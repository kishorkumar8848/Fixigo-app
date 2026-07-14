import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'session.dart';
import 'role_selection.dart';
import 'admin_dashboard_screen.dart';
import 'admin_technicians_screen.dart';
import 'admin_customers_screen.dart';
import 'admin_bookings_screen.dart';
import 'admin_services_screen.dart';
import 'admin_resell_requests_screen.dart';
import 'fixigo_logout_dialog.dart';

// placeholders for other UI blocks
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(title, style: const TextStyle(fontSize: 24)));
  }
}

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AdminDashboardScreen(),
    const AdminTechniciansScreen(),
    const AdminCustomersScreen(),
    const AdminBookingsScreen(),
    const AdminResellRequestsScreen(),
    const AdminServicesScreen(),
  ];

  final List<String> _titles = [
    'Dashboard Overview',
    'Technician Management',
    'Customer Management',
    'Booking Management',
    'Resale Management',
    'Services & Categories',
  ];

  void _handleLogout() async {
    final confirm = await showFixigoLogoutDialog(context);

    if (confirm == true) {
      await Session.clear();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            color: AppColors.error,
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.engineering_outlined),
              activeIcon: Icon(Icons.engineering),
              label: 'Techs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sell_outlined),
              activeIcon: Icon(Icons.sell),
              label: 'Resell',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.miscellaneous_services_outlined),
              activeIcon: Icon(Icons.miscellaneous_services),
              label: 'Services',
            ),
          ],
        ),
      ),
    );
  }
}
