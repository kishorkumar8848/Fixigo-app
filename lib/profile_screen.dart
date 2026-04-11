import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'common_widgets.dart';
import 'role_selection.dart';
import 'session.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: FixigoAppBar(
        title: 'My Profile',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            _ProfileHeader(),
            const SizedBox(height: 16),
            // Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                      child: StatCard(
                          label: 'Total Repairs',
                          value: '14',
                          icon: Icons.build_rounded,
                          color: AppColors.primary,
                          bgColor: AppColors.primarySurface)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: StatCard(
                          label: 'Active Warranties',
                          value: '2',
                          icon: Icons.verified_rounded,
                          color: AppColors.success,
                          bgColor: AppColors.successLight)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: StatCard(
                          label: 'Appliances Sold',
                          value: '3',
                          icon: Icons.sell_rounded,
                          color: AppColors.secondary,
                          bgColor: AppColors.secondarySurface)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Menu groups
            _MenuGroup(
              title: 'Account',
              items: [
                _MenuItem(Icons.person_rounded, 'Personal Information',
                    onTap: () {}),
                _MenuItem(Icons.location_on_rounded, 'Saved Addresses',
                    badge: '2', onTap: () {}),
                _MenuItem(Icons.payment_rounded, 'Payment Methods',
                    onTap: () {}),
              ],
            ),
            const SizedBox(height: 12),
            _MenuGroup(
              title: 'Services',
              items: [
                _MenuItem(Icons.history_rounded, 'Repair History',
                    onTap: () {}),
                _MenuItem(Icons.verified_rounded, 'My Warranties',
                    onTap: () {}),
                _MenuItem(Icons.sell_rounded, 'My Listings (Resell)',
                    badge: '1', onTap: () {}),
              ],
            ),
            const SizedBox(height: 12),
            _MenuGroup(
              title: 'Support & Legal',
              items: [
                _MenuItem(Icons.headset_mic_rounded, 'Customer Support',
                    onTap: () {}),
                _MenuItem(Icons.star_rounded, 'Rate the App', onTap: () {}),
                _MenuItem(Icons.share_rounded, 'Refer & Earn ₹200',
                    isHighlight: true, onTap: () {}),
                _MenuItem(Icons.privacy_tip_rounded, 'Privacy Policy',
                    onTap: () {}),
                _MenuItem(Icons.description_rounded, 'Terms of Service',
                    onTap: () {}),
              ],
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RoleSelectionScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Logout'),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Version 1.0.0 • Fixigo',
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      color: AppColors.surface,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    // extract initials from name
                    Session.name != null && Session.name!.isNotEmpty
                        ? Session.name!.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
                        : 'U',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.edit_rounded,
                      color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(Session.name ?? 'User',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(Session.email ?? '',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          // You could also store phone in session if available
          const SizedBox(height: 0),
          const SizedBox(height: 10),
          StatusBadge.success('Verified Customer'),
        ],
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _MenuGroup({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Text(title.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary,
                  letterSpacing: 1)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: List.generate(items.length, (i) {
              final item = items[i];
              return Column(
                children: [
                  ListTile(
                    onTap: item.onTap,
                    leading: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: item.isHighlight
                            ? AppColors.accentLight
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(item.icon,
                          size: 18,
                          color: item.isHighlight
                              ? AppColors.accent
                              : AppColors.primary),
                    ),
                    title: Text(item.label,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: item.isHighlight
                                ? AppColors.accent
                                : AppColors.textPrimary)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.badge != null)
                          Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(item.badge!,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            size: 14, color: AppColors.textTertiary),
                      ],
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  ),
                  if (i < items.length - 1)
                    const Padding(
                      padding: EdgeInsets.only(left: 56),
                      child: Divider(height: 1),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String? badge;
  final bool isHighlight;
  final VoidCallback? onTap;

  const _MenuItem(this.icon, this.label,
      {this.badge, this.isHighlight = false, this.onTap});
}
