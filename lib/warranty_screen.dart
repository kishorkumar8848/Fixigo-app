import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'common_widgets.dart';
import 'session.dart';
import 'api.dart';

class WarrantyScreen extends StatefulWidget {
  final int initialIndex;
  const WarrantyScreen({super.key, this.initialIndex = 0});

  @override
  State<WarrantyScreen> createState() => _WarrantyScreenState();
}

class _WarrantyScreenState extends State<WarrantyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<dynamic> _history = [];
  List<dynamic> _warranties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this, initialIndex: widget.initialIndex);
    _fetchWarrantyAndHistory();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _fetchWarrantyAndHistory() async {
    if (Session.userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final resp = await Api.get('/bookings/history/${Session.userId}');
      if (resp['status'] == 200 && resp['data'] is List) {
        final List completed = resp['data'];
        final warrantiesList = <Map<String, dynamic>>[];

        for (var b in completed) {
          final updatedAtStr = b['updated_at'];
          if (updatedAtStr == null) continue;

          final updatedAt = DateTime.parse(updatedAtStr);
          final diff = DateTime.now().difference(updatedAt).inDays;
          final daysLeft = 90 - diff;

          if (daysLeft >= 0) {
            final w = Map<String, dynamic>.from(b);
            w['daysLeft'] = daysLeft;
            warrantiesList.add(w);
          }
        }

        if (mounted) {
          setState(() {
            _history = completed;
            _warranties = warrantiesList;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRatingDialog(Map<String, dynamic> booking) {
    int rating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Rate Your Repair', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How was your repair service for ${booking['appliance_type']}?',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => GestureDetector(
                    onTap: () => setStateDialog(() => rating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 36,
                        color: Colors.amber[600],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share your feedback...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.all(12),
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final comment = commentController.text.trim();
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                
                setState(() => _isLoading = true);
                try {
                  final resp = await Api.post('/bookings/${booking['id']}/review', {
                    'rating': rating,
                    'comment': comment,
                  });
                  
                  if (resp['status'] == 200) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('Thank you for your feedback!')),
                    );
                    _fetchWarrantyAndHistory();
                  } else {
                    final msg = resp['data']['message'] ?? 'Failed to submit review';
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text(msg)),
                    );
                    if (mounted) setState(() => _isLoading = false);
                  }
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Downloading report...')),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
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
                      _WarrantyTab(
                        warranties: _warranties,
                        onRefresh: _fetchWarrantyAndHistory,
                      ),
                       _HistoryTab(
                        history: _history,
                        onRefresh: _fetchWarrantyAndHistory,
                        onRate: (booking) => _showRatingDialog(booking),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _WarrantyTab extends StatelessWidget {
  final List<dynamic> warranties;
  final VoidCallback onRefresh;

  const _WarrantyTab({
    required this.warranties,
    required this.onRefresh,
  });

  String _getMonthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    if (month >= 1 && month <= 12) return months[month];
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (warranties.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: const EmptyState(
              icon: Icons.verified_rounded,
              title: 'No Active Warranties',
              subtitle:
                  'Warranties will appear here once your service jobs are completed.',
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
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
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('${warranties.length} Warranties',
                          style: const TextStyle(
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
                        child: const Text('All completed repairs are covered',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.verified_rounded,
                    color: Colors.white, size: 52),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...warranties.map((w) {
            final completionDate = DateTime.parse(w['updated_at']);
            final endDate = completionDate.add(const Duration(days: 90));
            final startDateStr =
                "${completionDate.day} ${_getMonthName(completionDate.month)}, ${completionDate.year}";
            final endDateStr =
                "${endDate.day} ${_getMonthName(endDate.month)}, ${endDate.year}";
            final daysLeft = w['daysLeft'] as int;

            return _WarrantyCard(
              service: w['appliance_type'] ?? 'General Repair',
              appliance: w['issue_description'] ?? '',
              id: 'FIX-${w['id']}',
              startDate: startDateStr,
              endDate: endDateStr,
              daysLeft: daysLeft,
            );
          }),
        ],
      ),
    );
  }
}

class _WarrantyCard extends StatelessWidget {
  final String service, appliance, id, startDate, endDate;
  final int daysLeft;

  const _WarrantyCard({
    required this.service,
    required this.appliance,
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.daysLeft,
  });

  @override
  Widget build(BuildContext context) {
    final progress = daysLeft / 90.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.build_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(appliance,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              StatusBadge.success('Active'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$daysLeft days remaining',
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
          Row(
            children: [
              const Icon(Icons.date_range_rounded,
                  size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text('$startDate → $endDate',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
              const Spacer(),
              Text(id,
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
  final List<dynamic> history;
  final VoidCallback onRefresh;
  final Function(Map<String, dynamic>) onRate;

  const _HistoryTab({
    required this.history,
    required this.onRefresh,
    required this.onRate,
  });

  String _getMonthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    if (month >= 1 && month <= 12) return months[month];
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: const EmptyState(
              icon: Icons.history_rounded,
              title: 'No Repair History',
              subtitle: 'Your repair records will be listed here after completion.',
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ...history.map((h) {
            final completionDate = DateTime.parse(h['updated_at']);
            final dateStr =
                "${_getMonthName(completionDate.month)} ${completionDate.day}, ${completionDate.year}";

            final rawPrice = h['job_price'];
            final priceStr = rawPrice != null ? "₹$rawPrice" : "₹399";

            return _HistoryCard(
              booking: h,
              service: h['appliance_type'] ?? 'General Repair',
              date: dateStr,
              amount: priceStr,
              status: h['status'] ?? 'completed',
              rating: h['booking_review_rating'] != null
                  ? double.tryParse(h['booking_review_rating'].toString())
                  : null,
              onRateTap: h['booking_review_rating'] == null && h['technician_id'] != null
                  ? () => onRate(h)
                  : null,
            );
          }),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final String service, date, amount, status;
  final double? rating;
  final VoidCallback? onRateTap;

  const _HistoryCard({
    required this.booking,
    required this.service,
    required this.date,
    required this.amount,
    required this.status,
    this.rating,
    this.onRateTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCancelled = status == 'cancelled';
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
                Text(service,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(date,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                if (rating != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ...List.generate(
                          5,
                          (i) => Icon(
                              i < rating!.floor()
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 12,
                              color: Colors.amber[600])),
                      const SizedBox(width: 4),
                      Text('$rating',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ] else if (status == 'completed' && onRateTap != null) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: onRateTap,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_outline_rounded,
                            size: 14, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text(
                          'Rate Repair',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount,
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
