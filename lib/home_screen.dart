import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'common_widgets.dart';
import 'track_repair_screen.dart';
import 'session.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _HomeHeader()),
          // ── Search ─────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _SearchBar(),
            ),
          ),
          // ── Active booking banner ───────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _ActiveBookingBanner(context),
            ),
          ),
          // ── Categories ─────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.only(top: 24),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  const SectionHeader(
                      title: 'Our Services', actionText: 'View all'),
                  const SizedBox(height: 16),
                  _ServiceCategories(),
                ],
              ),
            ),
          ),
          // ── Quick Booking ───────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.only(top: 28),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  const SectionHeader(title: 'Popular Repairs'),
                  const SizedBox(height: 16),
                  _PopularRepairs(),
                ],
              ),
            ),
          ),
          // ── Promo Banner ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            sliver: SliverToBoxAdapter(child: _PromoBanner()),
          ),
          // ── How it works ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.only(top: 28),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  const SectionHeader(title: 'How It Works'),
                  const SizedBox(height: 16),
                  _HowItWorks(),
                ],
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }

  Widget _ActiveBookingBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const TrackRepairScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00897B), Color(0xFF00ACC1)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00897B).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.engineering_rounded,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Technician On the Way!',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('Rajesh Kumar • ETA 15 mins',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w400)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Track',
                  style: TextStyle(
                      color: Color(0xFF00897B),
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero Header ───────────────────────────────────────────────────────────────
class _HomeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Bengaluru, KA',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded,
                            color: Colors.white70, size: 18),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hello, ${Session.name ?? 'User'}! 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'What needs fixing today?',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.75), fontSize: 13),
                    ),
                  ],
                ),
              ),
              Stack(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.notifications_rounded,
                        color: Colors.white, size: 22),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF6F00),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Search Bar ────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.search_rounded, color: AppColors.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Search services, appliances...',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Filter',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Service Categories ────────────────────────────────────────────────────────
class _ServiceCategories extends StatelessWidget {
  final _cats = const [
    _Cat('AC Repair', Icons.ac_unit_rounded, Color(0xFF1565C0)),
    _Cat('Washing\nMachine', Icons.local_laundry_service_rounded,
        Color(0xFF00897B)),
    _Cat('Refrigerator', Icons.kitchen_rounded, Color(0xFF6A1B9A)),
    _Cat('Microwave', Icons.microwave_rounded, Color(0xFFE65100)),
    _Cat('TV Repair', Icons.tv_rounded, Color(0xFF0277BD)),
    _Cat('Water\nPurifier', Icons.water_drop_rounded, Color(0xFF2E7D32)),
    _Cat('Geyser', Icons.water_rounded, Color(0xFFC62828)),
    _Cat('More', Icons.grid_view_rounded, Color(0xFF546E7A)),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) {
          final cat = _cats[i];
          return Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: cat.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cat.color.withOpacity(0.2)),
                ),
                child: Icon(cat.icon, color: cat.color, size: 28),
              ),
              const SizedBox(height: 6),
              Text(
                cat.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Cat {
  final String label;
  final IconData icon;
  final Color color;
  const _Cat(this.label, this.icon, this.color);
}

// ── Popular Repairs ───────────────────────────────────────────────────────────
class _PopularRepairs extends StatelessWidget {
  final _repairs = const [
    _Repair('AC Gas Refill', 'AC & Air Coolers', '₹499', Icons.ac_unit_rounded,
        Color(0xFF1565C0), '45 min', 4.8),
    _Repair('Washing Machine\nService', 'Washing Machines', '₹349',
        Icons.local_laundry_service_rounded, Color(0xFF00897B), '60 min', 4.7),
    _Repair('Refrigerator\nCooling Fix', 'Refrigerators', '₹599',
        Icons.kitchen_rounded, Color(0xFF6A1B9A), '90 min', 4.9),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _repairs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (ctx, i) {
          final r = _repairs[i];
          return Container(
            width: 180,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: r.color.withOpacity(0.1),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(15)),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Icon(r.icon, color: r.color, size: 36),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12, top: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.successLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Starts ${r.price}',
                                  style: const TextStyle(
                                    color: AppColors.success,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          )),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.star_rounded,
                              size: 14, color: Colors.amber[600]),
                          const SizedBox(width: 3),
                          Text(
                            '${r.rating}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.schedule_rounded,
                              size: 13, color: AppColors.textTertiary),
                          const SizedBox(width: 3),
                          Text(r.duration,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Repair {
  final String name, category, price, duration;
  final IconData icon;
  final Color color;
  final double rating;
  const _Repair(this.name, this.category, this.price, this.icon, this.color,
      this.duration, this.rating);
}

// ── Promo Banner ──────────────────────────────────────────────────────────────
class _PromoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6F00), Color(0xFFFFA000)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('LIMITED OFFER',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1)),
                ),
                const SizedBox(height: 8),
                const Text('First repair\nat ₹99 only!',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.2)),
                const SizedBox(height: 4),
                Text('Use code: FIXNOW',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.85), fontSize: 12)),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Book Now',
                      style: TextStyle(
                          color: Color(0xFFFF6F00),
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ),
              ],
            ),
          ),
          const Icon(Icons.local_offer_rounded, color: Colors.white, size: 72),
        ],
      ),
    );
  }
}

// ── How It Works ──────────────────────────────────────────────────────────────
class _HowItWorks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final steps = [
      _Step(Icons.search_rounded, 'Choose\nService', AppColors.primary),
      _Step(Icons.calendar_today_rounded, 'Book\nSlot', AppColors.secondary),
      _Step(Icons.engineering_rounded, 'Expert\nVisits', Color(0xFF6A1B9A)),
      _Step(Icons.star_rounded, 'Rate &\nReview', Color(0xFFFF6F00)),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: Container(
                height: 2,
                color: AppColors.border,
                margin: const EdgeInsets.only(bottom: 28),
              ),
            );
          }
          final step = steps[i ~/ 2];
          return Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: step.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: step.color.withOpacity(0.3)),
                ),
                child: Icon(step.icon, color: step.color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                step.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _Step {
  final IconData icon;
  final String label;
  final Color color;
  const _Step(this.icon, this.label, this.color);
}
