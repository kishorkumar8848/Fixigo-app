import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'common_widgets.dart';

class TechnicianDashboardScreen extends StatelessWidget {
  const TechnicianDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _TechHeader()),
          // Stats grid
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: const [
                  StatCard(
                    label: "Today's Jobs",
                    value: '4',
                    icon: Icons.work_rounded,
                    color: AppColors.primary,
                    bgColor: AppColors.primarySurface,
                  ),
                  StatCard(
                    label: "Today's Earnings",
                    value: '₹1,840',
                    icon: Icons.currency_rupee_rounded,
                    color: AppColors.success,
                    bgColor: AppColors.successLight,
                  ),
                  StatCard(
                    label: 'Pending Jobs',
                    value: '3',
                    icon: Icons.pending_rounded,
                    color: AppColors.warning,
                    bgColor: AppColors.warningLight,
                  ),
                  StatCard(
                    label: 'Rating',
                    value: '4.8 ⭐',
                    icon: Icons.star_rounded,
                    color: Color(0xFFFF6F00),
                    bgColor: Color(0xFFFFF8E1),
                  ),
                ],
              ),
            ),
          ),
          // Availability toggle
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(child: _AvailabilityToggle()),
          ),
          // Today's jobs
          SliverPadding(
            padding: const EdgeInsets.only(top: 24),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  const SectionHeader(
                      title: "Today's Jobs", actionText: 'View all'),
                  const SizedBox(height: 14),
                  _TodayJobsList(),
                ],
              ),
            ),
          ),
          // Performance
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            sliver: SliverToBoxAdapter(child: _PerformanceCard()),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }
}

class _TechHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF00897B), Color(0xFF26A69A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 28,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.5)),
            ),
            child: const Center(
              child: Text('RK',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Good Morning! 🔧',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const Text('Rajesh Kumar',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 14),
                    const SizedBox(width: 3),
                    const Text('4.8 Rating',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('AC Specialist',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.notifications_rounded,
                color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityToggle extends StatefulWidget {
  @override
  State<_AvailabilityToggle> createState() => _AvailabilityToggleState();
}

class _AvailabilityToggleState extends State<_AvailabilityToggle> {
  bool _online = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _online ? AppColors.successLight : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: _online
                ? AppColors.success.withOpacity(0.4)
                : AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _online
                  ? AppColors.success.withOpacity(0.15)
                  : AppColors.border,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _online ? Icons.wifi_rounded : Icons.wifi_off_rounded,
              color: _online ? AppColors.success : AppColors.textTertiary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _online ? 'You\'re Online' : 'You\'re Offline',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color:
                        _online ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
                Text(
                  _online
                      ? 'Accepting new job requests'
                      : 'Not receiving new jobs',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: _online,
            onChanged: (v) => setState(() => _online = v),
            activeColor: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _TodayJobsList extends StatelessWidget {
  final _jobs = const [
    _TodayJob('AC Service', 'Priya Sharma', '11:00 AM', 'Indiranagar',
        'In Progress', Color(0xFF00897B)),
    _TodayJob('Washing Machine', 'Karan Mehta', '2:00 PM', 'Koramangala',
        'Upcoming', Color(0xFF1565C0)),
    _TodayJob('Refrigerator', 'Anita Roy', '5:00 PM', 'HSR Layout', 'Upcoming',
        Color(0xFF6A1B9A)),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _jobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _TodayJobCard(job: _jobs[i]),
    );
  }
}

class _TodayJob {
  final String service, customer, time, location, status;
  final Color color;
  const _TodayJob(this.service, this.customer, this.time, this.location,
      this.status, this.color);
}

class _TodayJobCard extends StatelessWidget {
  final _TodayJob job;
  const _TodayJobCard({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: job.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.build_rounded, color: job.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.service,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(job.customer,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        size: 12, color: AppColors.textTertiary),
                    const SizedBox(width: 3),
                    Text(job.time,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(width: 8),
                    const Icon(Icons.location_on_rounded,
                        size: 12, color: AppColors.textTertiary),
                    const SizedBox(width: 3),
                    Text(job.location,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          job.status == 'In Progress'
              ? StatusBadge.warning('Active')
              : StatusBadge.info('Soon'),
        ],
      ),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('This Week\'s Performance',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 16),
          _PerfBar('Jobs Completed', 0.85, '17/20', AppColors.primary),
          const SizedBox(height: 12),
          _PerfBar('Customer Rating', 0.96, '4.8/5.0', AppColors.success),
          const SizedBox(height: 12),
          _PerfBar('On-time Arrival', 0.78, '78%', AppColors.warning),
        ],
      ),
    );
  }

  Widget _PerfBar(String label, double value, String text, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            Text(text,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
