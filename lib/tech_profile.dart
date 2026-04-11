import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'common_widgets.dart';
import 'role_selection.dart';

class TechProfileScreen extends StatelessWidget {
  const TechProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: FixigoAppBar(
        title: 'My Profile',
        actions: [
          IconButton(icon: const Icon(Icons.share_rounded), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _TechProfileHeader(),
            const SizedBox(height: 16),
            // Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                      child: StatCard(
                          label: 'Total Jobs',
                          value: '312',
                          icon: Icons.work_rounded,
                          color: AppColors.secondary,
                          bgColor: AppColors.secondarySurface)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: StatCard(
                          label: 'Rating',
                          value: '4.8',
                          icon: Icons.star_rounded,
                          color: Color(0xFFFF6F00),
                          bgColor: Color(0xFFFFF8E1))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: StatCard(
                          label: 'Earnings',
                          value: '₹1.2L',
                          icon: Icons.currency_rupee_rounded,
                          color: AppColors.success,
                          bgColor: AppColors.successLight)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Skills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SkillsCard(),
            ),
            const SizedBox(height: 16),
            // Verification
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _VerificationCard(),
            ),
            const SizedBox(height: 16),
            // Reviews
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _ReviewsCard(),
            ),
            const SizedBox(height: 16),
            // Menu
            _MenuGroup(
              title: 'Account',
              items: const [
                ('Personal Details', Icons.person_rounded),
                ('Bank Account', Icons.account_balance_rounded),
                ('Work Schedule', Icons.calendar_today_rounded),
              ],
            ),
            const SizedBox(height: 12),
            _MenuGroup(
              title: 'Support',
              items: const [
                ('Help & Support', Icons.help_rounded),
                ('Report an Issue', Icons.flag_rounded),
                ('Terms & Conditions', Icons.description_rounded),
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _TechProfileHeader extends StatelessWidget {
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00695C), Color(0xFF00897B)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('RK',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Rajesh Kumar',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('AC & Refrigeration Specialist',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StatusBadge.success('Verified'),
              const SizedBox(width: 8),
              StatusBadge.info('Senior Tech'),
              const SizedBox(width: 8),
              StatusBadge(
                text: '6 yrs exp',
                color: AppColors.warning,
                bgColor: AppColors.warningLight,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
                5,
                (i) => Icon(
                    i < 4 ? Icons.star_rounded : Icons.star_half_rounded,
                    color: Colors.amber[600],
                    size: 20)),
          ),
          const Text('4.8 out of 5 (127 reviews)',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _SkillsCard extends StatelessWidget {
  final _skills = const [
    'AC Service',
    'Gas Refill',
    'Refrigerator',
    'Washing Machine',
    'Geyser',
    'Split AC',
    'Window AC',
    'Copper Coil',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Skills & Expertise',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _skills
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.secondarySurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.secondary.withOpacity(0.3)),
                      ),
                      child: Text(s,
                          style: const TextStyle(
                              color: AppColors.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final docs = [
      ('Aadhar Card', true),
      ('PAN Card', true),
      ('Police Verification', true),
      ('Skill Certificate', true),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Verification Status',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              StatusBadge.success('Fully Verified'),
            ],
          ),
          const SizedBox(height: 12),
          ...docs.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      d.$2 ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: d.$2 ? AppColors.success : AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(d.$1, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _ReviewsCard extends StatelessWidget {
  final _reviews = const [
    (
      'Priya Sharma',
      '5.0',
      'Excellent service! Rajesh was very professional and fixed the AC perfectly.'
    ),
    ('Karan Mehta', '4.5', 'Good work, came on time. Would recommend.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Reviews',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const Text('View all',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          ..._reviews.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              shape: BoxShape.circle),
                          child: Center(
                              child: Text(r.$1[0],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary))),
                        ),
                        const SizedBox(width: 10),
                        Text(r.$1,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        const Spacer(),
                        Icon(Icons.star_rounded,
                            color: Colors.amber[600], size: 14),
                        const SizedBox(width: 2),
                        Text(r.$2,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(r.$3,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  final String title;
  final List<(String, IconData)> items;

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
                    leading: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.secondarySurface,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child:
                          Icon(item.$2, size: 18, color: AppColors.secondary),
                    ),
                    title: Text(item.$1,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: AppColors.textTertiary),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    onTap: () {},
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
