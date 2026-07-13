import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'technician_dashboard_screen.dart';
import 'job_request_screen.dart';
import 'active_job_screen.dart';
import 'tech_earning_screen.dart';
import 'tech_profile.dart';
import 'api.dart';

class TechnicianMainScreen extends StatefulWidget {
  const TechnicianMainScreen({super.key});

  static final ValueNotifier<int> newJobsCount = ValueNotifier<int>(0);

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

  Future<void> _refreshCount() async {
    try {
      final resp = await Api.get('/technician/jobs');
      if (resp['status'] == 200 && resp['data'] is List) {
        final List<dynamic> jobs = resp['data'];
        final count = jobs.where((j) => j['status'] == 'assigned').length;
        TechnicianMainScreen.newJobsCount.value = count;
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: TechnicianMainScreen.newJobsCount,
        builder: (context, count, _) {
          return _TechBottomNav(
            currentIndex: _currentIndex,
            newJobsCount: count,
            onTap: (i) {
              setState(() => _currentIndex = i);
              _refreshCount();
            },
          );
        },
      ),
    );
  }
}

class _TechBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int newJobsCount;

  const _TechBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.newJobsCount,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _TechNavItem(Icons.dashboard_rounded, 'Dashboard'),
      _TechNavItem(
        Icons.work_rounded,
        'Jobs',
        badge: newJobsCount > 0 ? '$newJobsCount' : null,
      ),
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
