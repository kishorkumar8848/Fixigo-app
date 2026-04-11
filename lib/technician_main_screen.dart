import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'common_widgets.dart';
import 'technician_dashboard_screen.dart';
import 'job_request_screen.dart';
import 'active_job_screen.dart';
import 'tech_earning_screen.dart';
import 'tech_profile.dart';

class TechnicianMainScreen extends StatefulWidget {
  const TechnicianMainScreen({super.key});

  @override
  State<TechnicianMainScreen> createState() => _TechnicianMainScreenState();
}

class _TechnicianMainScreenState extends State<TechnicianMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TechnicianDashboardScreen(),
    JobRequestsScreen(),
    ActiveJobScreen(),
    TechEarningsScreen(),
    TechProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _TechBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _TechBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _TechBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      _TechNavItem(Icons.dashboard_rounded, 'Dashboard'),
      _TechNavItem(Icons.work_rounded, 'Jobs', badge: '3'),
      _TechNavItem(Icons.build_rounded, 'Active'),
      _TechNavItem(Icons.account_balance_wallet_rounded, 'Earnings'),
      _TechNavItem(Icons.person_rounded, 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: List.generate(items.length, (i) {
              final isSelected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.secondary.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              items[i].icon,
                              color: isSelected
                                  ? AppColors.secondary
                                  : AppColors.textTertiary,
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              items[i].label,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.secondary
                                    : AppColors.textTertiary,
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (items[i].badge != null)
                        Positioned(
                          top: 4,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              items[i].badge!,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _TechNavItem {
  final IconData icon;
  final String label;
  final String? badge;
  _TechNavItem(this.icon, this.label, {this.badge});
}
