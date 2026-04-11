import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'common_widgets.dart';

class TechEarningsScreen extends StatefulWidget {
  const TechEarningsScreen({super.key});

  @override
  State<TechEarningsScreen> createState() => _TechEarningsScreenState();
}

class _TechEarningsScreenState extends State<TechEarningsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  int _period = 0;

  final _periods = ['Daily', 'Weekly', 'Monthly'];
  final _dailyData = [
    _EarningBar('Mon', 1200, 3),
    _EarningBar('Tue', 1840, 4),
    _EarningBar('Wed', 900, 2),
    _EarningBar('Thu', 2100, 5),
    _EarningBar('Fri', 1650, 4),
    _EarningBar('Sat', 2800, 6),
    _EarningBar('Sun', 600, 1),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() => _period = _tab.index));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const FixigoAppBar(title: 'My Earnings'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Period tabs
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TabBar(
                controller: _tab,
                labelColor: AppColors.secondary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.secondary,
                tabs: _periods.map((p) => Tab(text: p)).toList(),
              ),
            ),
            // Summary
            Padding(
              padding: const EdgeInsets.all(20),
              child: _EarningsSummary(period: _periods[_period]),
            ),
            // Bar chart
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _BarChart(data: _dailyData),
            ),
            const SizedBox(height: 24),
            // Stats row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                      child: StatCard(
                    label: 'Jobs Done',
                    value: '25',
                    icon: Icons.task_alt_rounded,
                    color: AppColors.secondary,
                    bgColor: AppColors.secondarySurface,
                  )),
                  const SizedBox(width: 12),
                  Expanded(
                      child: StatCard(
                    label: 'Avg/Job',
                    value: '₹462',
                    icon: Icons.trending_up_rounded,
                    color: AppColors.success,
                    bgColor: AppColors.successLight,
                  )),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Payout history
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payout History',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  ..._payouts.map((p) => _PayoutCard(payout: p)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Withdraw
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GradientButton(
                text: 'Withdraw Earnings (₹11,540)',
                onTap: () {},
                gradient: const LinearGradient(
                    colors: [Color(0xFF00897B), Color(0xFF26C6DA)]),
                icon: const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  final _payouts = const [
    _Payout('Weekly Payout', 'Feb 10 – Feb 16, 2024', '₹11,540', 'Processed'),
    _Payout('Weekly Payout', 'Feb 3 – Feb 9, 2024', '₹9,820', 'Processed'),
    _Payout('Weekly Payout', 'Jan 27 – Feb 2, 2024', '₹12,100', 'Processed'),
  ];
}

class _EarningsSummary extends StatelessWidget {
  final String period;
  const _EarningsSummary({required this.period});

  @override
  Widget build(BuildContext context) {
    final data = {
      'Daily': ('₹1,840', 'Today'),
      'Weekly': ('₹11,540', 'This Week'),
      'Monthly': ('₹42,800', 'This Month'),
    };
    final (amount, label) = data[period]!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text('$label\'s Earnings',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.8), fontSize: 13)),
          const SizedBox(height: 6),
          Text(amount,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.trending_up_rounded,
                  color: Colors.greenAccent, size: 18),
              const SizedBox(width: 4),
              Text('+12.5% vs last $period'.toLowerCase(),
                  style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _EarningBar {
  final String day;
  final int amount;
  final int jobs;
  const _EarningBar(this.day, this.amount, this.jobs);
}

class _BarChart extends StatelessWidget {
  final List<_EarningBar> data;
  const _BarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.map((d) => d.amount).reduce((a, b) => a > b ? a : b);
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
          const Text('Daily Breakdown',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: data.map((d) {
                final barH = (d.amount / maxVal) * 100;
                final isToday = d.day == 'Tue';
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('₹${(d.amount / 1000).toStringAsFixed(1)}K',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isToday
                                ? AppColors.secondary
                                : AppColors.textTertiary)),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      width: 28,
                      height: barH,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isToday
                              ? [
                                  const Color(0xFF00897B),
                                  const Color(0xFF26C6DA)
                                ]
                              : [AppColors.primarySurface, AppColors.border],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(d.day,
                        style: TextStyle(
                            fontSize: 10,
                            color: isToday
                                ? AppColors.secondary
                                : AppColors.textSecondary,
                            fontWeight:
                                isToday ? FontWeight.w700 : FontWeight.w400)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Payout {
  final String label, period, amount, status;
  const _Payout(this.label, this.period, this.amount, this.status);
}

class _PayoutCard extends StatelessWidget {
  final _Payout payout;
  const _PayoutCard({super.key, required this.payout});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.account_balance_rounded,
                color: AppColors.success, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payout.label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text(payout.period,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(payout.amount,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              StatusBadge.success(payout.status),
            ],
          ),
        ],
      ),
    );
  }
}
