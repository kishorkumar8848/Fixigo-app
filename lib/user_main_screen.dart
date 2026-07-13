import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'home_screen.dart';
import 'book_service_screen.dart';
import 'resell_screen.dart';
import 'warranty_screen.dart';
import 'profile_screen.dart';

class UserMainScreen extends StatefulWidget {
  const UserMainScreen({super.key});

  @override
  State<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State<UserMainScreen> {
  int _currentIndex = 0;
  String? _preselectedCategory;
  String? _prefilledIssue;

  void _switchTab(int index, {String? category, String? issue}) {
    setState(() {
      _currentIndex = index;
      _preselectedCategory = category;
      _prefilledIssue = issue;
    });
  }

  List<Widget> get _screens => [
        HomeScreen(
          onCategorySelected: (cat) => _switchTab(1, category: cat),
          onPopularSelected: (cat, issue) => _switchTab(1, category: cat, issue: issue),
        ),
        BookServiceScreen(
          initialCategory: _preselectedCategory,
          initialIssue: _prefilledIssue,
          onBookingCompleted: () {
            setState(() {
              _preselectedCategory = null;
              _prefilledIssue = null;
            });
          },
        ),
        const ResellScreen(),
        const WarrantyScreen(),
        const ProfileScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _FixigoBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() {
          _currentIndex = i;
          // Clear preselected categories when manually tapping bottom navigation
          _preselectedCategory = null;
          _prefilledIssue = null;
        }),
      ),
    );
  }
}

class _FixigoBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FixigoBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(icon: Icons.home_rounded, label: 'Home'),
      _NavItem(icon: Icons.calendar_today_rounded, label: 'Bookings'),
      _NavItem(icon: Icons.sell_rounded, label: 'Resell'),
      _NavItem(icon: Icons.verified_rounded, label: 'Warranty'),
      _NavItem(icon: Icons.person_rounded, label: 'Profile'),
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final isSelected = i == currentIndex;
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primarySurface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        items[i].icon,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textTertiary,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i].label,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textTertiary,
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w400,
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

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem({required this.icon, required this.label});
}
