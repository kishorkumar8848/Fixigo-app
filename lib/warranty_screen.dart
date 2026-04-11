import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'common_widgets.dart';

class WarrantyScreen extends StatefulWidget {
  const WarrantyScreen({super.key});

  @override
  State<WarrantyScreen> createState() => _WarrantyScreenState();
}

class _WarrantyScreenState extends State<WarrantyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
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
      appBar: FixigoAppBar(
        title: 'Warranty & History',
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TabBar(
              controller: _tab,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [
                Tab(text: 'Active Warranties'),
                Tab(text: 'Repair History'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _WarrantyTab(),
                _HistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WarrantyTab extends StatelessWidget {
  final _warranties = const [
    _Warranty('AC Gas Refill & Service', 'LG 1.5 Ton Split AC', 'FIX-2024-8841',
        'Feb 10, 2024', 'May 10, 2024', 42, true),
    _Warranty('Refrigerator Compressor', 'Samsung 250L Double Door',
        'FIX-2024-7712', 'Dec 20, 2023', 'Mar 20, 2024', 8, true),
    _Warranty('Washing Machine Service', 'Whirlpool 7.5Kg Semi-Auto',
        'FIX-2023-5501', 'Oct 5, 2023', 'Jan 5, 2024', 0, false),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Summary card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Active Warranties',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    const Text('2 Warranties',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('All repairs are covered',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.verified_rounded, color: Colors.white, size: 52),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ..._warranties.map((w) => _WarrantyCard(warranty: w)),
      ],
    );
  }
}

class _Warranty {
  final String service, appliance, id, startDate, endDate;
  final int daysLeft;
  final bool active;
  const _Warranty(this.service, this.appliance, this.id, this.startDate,
      this.endDate, this.daysLeft, this.active);
}

class _WarrantyCard extends StatelessWidget {
  final _Warranty warranty;
  const _WarrantyCard({super.key, required this.warranty});

  @override
  Widget build(BuildContext context) {
    final progress = warranty.daysLeft / 90.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: warranty.active ? AppColors.border : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: warranty.active
                      ? AppColors.primarySurface
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.build_rounded,
                    color: warranty.active
                        ? AppColors.primary
                        : AppColors.textTertiary,
                    size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(warranty.service,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(warranty.appliance,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              warranty.active
                  ? StatusBadge.success('Active')
                  : StatusBadge.error('Expired'),
            ],
          ),
          const SizedBox(height: 12),
          if (warranty.active) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${warranty.daysLeft} days remaining',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
                Text('${(progress * 100).toInt()}%',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.primarySurface,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              const Icon(Icons.date_range_rounded,
                  size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text('${warranty.startDate} → ${warranty.endDate}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
              const Spacer(),
              Text(warranty.id,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final history = [
      _HistoryItem('AC Gas Refill', 'Feb 10, 2024', '₹1,299', 'Completed', 4.9),
      _HistoryItem('Refrigerator Compressor', 'Dec 20, 2023', '₹3,499',
          'Completed', 4.7),
      _HistoryItem(
          'Washing Machine Belt', 'Oct 5, 2023', '₹699', 'Completed', 5.0),
      _HistoryItem(
          'TV Screen Calibration', 'Aug 18, 2023', '₹399', 'Cancelled', null),
      _HistoryItem(
          'Microwave Magnetron', 'Jun 2, 2023', '₹1,899', 'Completed', 4.5),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ...history.map((h) => _HistoryCard(item: h)),
      ],
    );
  }
}

class _HistoryItem {
  final String service, date, amount, status;
  final double? rating;
  const _HistoryItem(
      this.service, this.date, this.amount, this.status, this.rating);
}

class _HistoryCard extends StatelessWidget {
  final _HistoryItem item;
  const _HistoryCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isCancelled = item.status == 'Cancelled';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color:
                  isCancelled ? AppColors.errorLight : AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCancelled ? Icons.cancel_rounded : Icons.build_circle_rounded,
              color: isCancelled ? AppColors.error : AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.service,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(item.date,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                if (item.rating != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ...List.generate(
                          5,
                          (i) => Icon(
                              i < item.rating!.floor()
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 12,
                              color: Colors.amber[600])),
                      const SizedBox(width: 4),
                      Text('${item.rating}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(item.amount,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              isCancelled
                  ? StatusBadge.error('Cancelled')
                  : StatusBadge.success('Done'),
            ],
          ),
        ],
      ),
    );
  }
}
