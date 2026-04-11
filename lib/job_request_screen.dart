import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'common_widgets.dart';

class JobRequestsScreen extends StatefulWidget {
  const JobRequestsScreen({super.key});

  @override
  State<JobRequestsScreen> createState() => _JobRequestsScreenState();
}

class _JobRequestsScreenState extends State<JobRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final List<bool> _accepted = [false, false, false];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  final _newJobs = const [
    _JobReq('AC Gas Refill', 'Priya Sharma', 'Indiranagar, Bengaluru', '₹799',
        '2.1 km', 'URGENT', Icons.ac_unit_rounded, Color(0xFF1565C0)),
    _JobReq(
        'Washing Machine Repair',
        'Karan Mehta',
        'Koramangala, Bengaluru',
        '₹499',
        '3.8 km',
        'NORMAL',
        Icons.local_laundry_service_rounded,
        Color(0xFF00897B)),
    _JobReq('Refrigerator Not Cooling', 'Meena Gupta', 'HSR Layout, Bengaluru',
        '₹649', '5.2 km', 'NORMAL', Icons.kitchen_rounded, Color(0xFF6A1B9A)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: FixigoAppBar(
        title: 'Job Requests',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('3 New',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: TabBar(
              controller: _tab,
              labelColor: AppColors.secondary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.secondary,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [
                Tab(text: 'New (3)'),
                Tab(text: 'Accepted'),
                Tab(text: 'Rejected'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _NewJobsList(
                    jobs: _newJobs,
                    accepted: _accepted,
                    onAccept: (i) {
                      setState(() => _accepted[i] = true);
                      _tab.animateTo(1);
                    },
                    onReject: (i) {
                      _tab.animateTo(2);
                    }),
                _AcceptedList(),
                _RejectedList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JobReq {
  final String service, customer, address, payout, distance, urgency;
  final IconData icon;
  final Color color;
  const _JobReq(this.service, this.customer, this.address, this.payout,
      this.distance, this.urgency, this.icon, this.color);
}

class _NewJobsList extends StatelessWidget {
  final List<_JobReq> jobs;
  final List<bool> accepted;
  final ValueChanged<int> onAccept, onReject;

  const _NewJobsList({
    required this.jobs,
    required this.accepted,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: jobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) => _JobRequestCard(
        job: jobs[i],
        onAccept: () => onAccept(i),
        onReject: () => onReject(i),
      ),
    );
  }
}

class _JobRequestCard extends StatelessWidget {
  final _JobReq job;
  final VoidCallback onAccept, onReject;

  const _JobRequestCard({
    super.key,
    required this.job,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: job.urgency == 'URGENT'
                ? AppColors.error.withOpacity(0.3)
                : AppColors.border),
        boxShadow: [
          BoxShadow(
            color: job.urgency == 'URGENT'
                ? AppColors.error.withOpacity(0.08)
                : Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: job.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(job.icon, color: job.color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(job.service,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                          Text(job.customer,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    if (job.urgency == 'URGENT')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('URGENT',
                            style: TextStyle(
                                color: AppColors.error,
                                fontSize: 10,
                                fontWeight: FontWeight.w800)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _InfoChip(Icons.location_on_rounded, job.address),
                    const Spacer(),
                    _InfoChip(Icons.directions_rounded, job.distance),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Payout: ${job.payout}',
                          style: const TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ),
                    const Spacer(),
                    const Icon(Icons.schedule_rounded,
                        size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    const Text('Expires in 5:00',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          // Action buttons
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: GradientButton(
                    text: 'Accept Job',
                    onTap: onAccept,
                    gradient: const LinearGradient(
                        colors: [Color(0xFF00897B), Color(0xFF26C6DA)]),
                    icon: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textTertiary),
        const SizedBox(width: 3),
        Text(text,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _AcceptedList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SimpleJobCard('Microwave Repair', 'Suresh Nair', 'Today 4:00 PM',
            'Accepted', AppColors.success),
      ],
    );
  }
}

class _RejectedList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.do_not_disturb_rounded,
      title: 'No Rejected Jobs',
      subtitle: "You haven't declined any jobs recently",
    );
  }
}

class _SimpleJobCard extends StatelessWidget {
  final String service, customer, time, status;
  final Color color;

  const _SimpleJobCard(
      this.service, this.customer, this.time, this.status, this.color);

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
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.build_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text('$customer • $time',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          StatusBadge.success(status),
        ],
      ),
    );
  }
}
