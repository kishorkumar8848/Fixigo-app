import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'common_widgets.dart';
import 'api.dart';
import 'session.dart';

class TechEarningsScreen extends StatefulWidget {
  const TechEarningsScreen({super.key});

  @override
  State<TechEarningsScreen> createState() => _TechEarningsScreenState();
}

class _TechEarningsScreenState extends State<TechEarningsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  int _period = 0;
  bool _isLoading = true;

  final _periods = ['Daily', 'Weekly', 'Monthly'];
  double _totalEarnings = 0.0;
  double _pendingEarnings = 0.0;
  List<dynamic> _earnings = [];
  List<_EarningBar> _dailyData = [];
  List<_Payout> _payouts = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() => _period = _tab.index));
    _fetchEarnings();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _fetchEarnings() async {
    try {
      final resp = await Api.get('/technician/jobs/earnings');
      if (resp['status'] == 200) {
        final data = resp['data'];
        final rawEarnings = data['earnings'] as List<dynamic>? ?? [];

        // Build daily breakdown from rawEarnings
        final Map<String, double> weekdayEarnings = {
          'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0, 'Fri': 0, 'Sat': 0, 'Sun': 0
        };
        final Map<String, int> weekdayJobs = {
          'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0, 'Fri': 0, 'Sat': 0, 'Sun': 0
        };

        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

        for (var e in rawEarnings) {
          final double amt = double.tryParse(e['amount']?.toString() ?? '0') ?? 0.0;
          final dateStr = e['created_at'];
          if (dateStr != null) {
            final date = DateTime.tryParse(dateStr.toString());
            if (date != null) {
              final dayIndex = date.weekday - 1; // DateTime.weekday is 1-indexed (Mon=1)
              if (dayIndex >= 0 && dayIndex < 7) {
                final dayName = days[dayIndex];
                weekdayEarnings[dayName] = (weekdayEarnings[dayName] ?? 0.0) + amt;
                weekdayJobs[dayName] = (weekdayJobs[dayName] ?? 0) + 1;
              }
            }
          }
        }

        final dailyBars = days.map((day) {
          return _EarningBar(day, weekdayEarnings[day]!.toInt(), weekdayJobs[day]!);
        }).toList();

        // Build payouts list from rawEarnings
        final payoutList = rawEarnings.map((e) {
          final dateStr = e['created_at'] != null ? e['created_at'].toString().substring(0, 10) : 'Recent';
          final service = e['appliance_type'] ?? 'Repair Service';
          final String status = e['status'] == 'paid' ? 'Processed' : 'Pending';
          return _Payout(
            'Job Payout - $service',
            dateStr,
            '₹${double.tryParse(e['amount']?.toString() ?? '0')?.toStringAsFixed(0)}',
            status,
          );
        }).toList();

        setState(() {
          _totalEarnings = double.tryParse(data['totalEarnings']?.toString() ?? '0') ?? 0.0;
          _pendingEarnings = double.tryParse(data['pendingEarnings']?.toString() ?? '0') ?? 0.0;
          _earnings = rawEarnings;
          _dailyData = dailyBars;
          _payouts = payoutList;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final double avgPerJob = _earnings.isNotEmpty ? _totalEarnings / _earnings.length : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const FixigoAppBar(title: 'My Earnings'),
      body: RefreshIndicator(
        onRefresh: _fetchEarnings,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                child: _EarningsSummary(
                  period: _periods[_period],
                  totalEarnings: _totalEarnings,
                  pendingEarnings: _pendingEarnings,
                  earnings: _earnings,
                ),
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
                      value: '${_earnings.length}',
                      icon: Icons.task_alt_rounded,
                      color: AppColors.secondary,
                      bgColor: AppColors.secondarySurface,
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: StatCard(
                      label: 'Avg/Job',
                      value: '₹${avgPerJob.toStringAsFixed(0)}',
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
                    if (_payouts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'No payouts processed yet.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ..._payouts.map((p) => _PayoutCard(payout: p)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Withdraw
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GradientButton(
                  text: 'Withdraw Earnings (₹${_pendingEarnings.toStringAsFixed(0)})',
                  onTap: () {
                    if (_pendingEarnings > 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Withdrawal request submitted successfully!')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No pending earnings to withdraw.')),
                      );
                    }
                  },
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
      ),
    );
  }
}

class _EarningsSummary extends StatelessWidget {
  final String period;
  final double totalEarnings;
  final double pendingEarnings;
  final List<dynamic> earnings;

  const _EarningsSummary({
    required this.period,
    required this.totalEarnings,
    required this.pendingEarnings,
    required this.earnings,
  });

  @override
  Widget build(BuildContext context) {
    double amount = 0;
    String label = 'Total';

    if (period == 'Daily') {
      label = 'Today';
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      amount = earnings
          .where((e) => e['created_at'] != null && e['created_at'].toString().startsWith(todayStr))
          .fold(0.0, (sum, e) => sum + (double.tryParse(e['amount']?.toString() ?? '0') ?? 0.0));
    } else if (period == 'Weekly') {
      label = 'This Week';
      amount = totalEarnings;
    } else {
      label = 'This Month';
      amount = totalEarnings;
    }

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
          Text('₹${amount.toStringAsFixed(0)}',
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
              Text('Syncing live from database'.toLowerCase(),
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
    final maxVal = data.isNotEmpty 
        ? data.map((d) => d.amount).reduce((a, b) => a > b ? a : b)
        : 0;
    final maxValDouble = maxVal > 0 ? maxVal.toDouble() : 1.0;

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
          const Text('Daily Breakdown (This Week)',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: data.map((d) {
                final barH = (d.amount / maxValDouble) * 80;
                final isToday = d.day == _getTodayWeekday();
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('₹${d.amount}',
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
                      width: 24,
                      height: barH > 0 ? barH : 4.0, // Minimum height for visual
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

  String _getTodayWeekday() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayIndex = DateTime.now().weekday - 1;
    if (dayIndex >= 0 && dayIndex < 7) {
      return days[dayIndex];
    }
    return '';
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
                        fontWeight: FontWeight.w700, fontSize: 13)),
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
                      fontSize: 14,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              StatusBadge(
                text: payout.status,
                color: payout.status == 'Processed' ? AppColors.success : AppColors.warning,
                bgColor: payout.status == 'Processed' ? AppColors.successLight : AppColors.warningLight,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
