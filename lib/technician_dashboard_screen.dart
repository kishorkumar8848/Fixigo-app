import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'common_widgets.dart';
import 'api.dart';
import 'session.dart';
import 'location_picker_screen.dart';

class TechnicianDashboardScreen extends StatefulWidget {
  const TechnicianDashboardScreen({super.key});

  @override
  State<TechnicianDashboardScreen> createState() => _TechnicianDashboardScreenState();
}

class _TechnicianDashboardScreenState extends State<TechnicianDashboardScreen> {
  bool _isLoading = true;
  String _techName = '';
  double _rating = 0.0;
  String _skills = '';
  int _todayJobsCount = 0;
  double _todayEarnings = 0.0;
  int _pendingJobsCount = 0;
  int _completionRate = 100;
  List<dynamic> _todayJobs = [];
  String _verificationStatus = 'pending';
  String _aadharVerificationStatus = 'unuploaded';
  String _panVerificationStatus = 'unuploaded';

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final resp = await Api.get('/auth/technician/dashboard/${Session.userId}');
      if (resp['status'] == 200) {
        final data = resp['data'];
        setState(() {
          _techName = data['name'] ?? '';
          _rating = double.tryParse(data['rating']?.toString() ?? '0') ?? 0.0;
          _skills = data['skills'] ?? '';
          
          final stats = data['stats'] ?? {};
          _todayJobsCount = int.tryParse(stats['todayJobsCount']?.toString() ?? '0') ?? 0;
          _todayEarnings = double.tryParse(stats['todayEarnings']?.toString() ?? '0') ?? 0.0;
          _pendingJobsCount = int.tryParse(stats['pendingJobsCount']?.toString() ?? '0') ?? 0;
          _completionRate = int.tryParse(stats['completionRate']?.toString() ?? '100') ?? 100;
          
          _verificationStatus = data['verificationStatus'] ?? 'pending';
          _aadharVerificationStatus = data['aadharVerificationStatus'] ?? 'unuploaded';
          _panVerificationStatus = data['panVerificationStatus'] ?? 'unuploaded';
          
          _todayJobs = data['todayJobs'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changeLocation() async {
    final result = await Navigator.push<LocationPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLatitude: Session.latitude,
          initialLongitude: Session.longitude,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        Session.address = result.address;
        Session.latitude = result.latitude;
        Session.longitude = result.longitude;
      });

      try {
        await Api.put('/auth/technician/profile/${Session.userId}', {
          'name': _techName,
          'email': Session.email ?? '',
          'phone': Session.phone ?? '',
          'address': result.address,
        });
      } catch (_) {}
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _TechHeader(
                name: _techName,
                rating: _rating,
                skills: _skills,
                onChangeLocation: _changeLocation,
              ),
            ),
            if (_verificationStatus != 'verified')
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _aadharVerificationStatus != 'verified' || _panVerificationStatus != 'verified'
                                ? 'Action required: Please upload and complete verification for both Aadhaar Card and PAN Card in your Profile section to accept jobs.'
                                : 'Awaiting verification: Admin is verifying your uploaded ID proofs. You can accept jobs once approved.',
                            style: TextStyle(color: Colors.red.shade900, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
                  childAspectRatio: 1.25, // Adjusted to prevent layout overflow
                  children: [
                    StatCard(
                      label: "Today's Jobs",
                      value: '$_todayJobsCount',
                      icon: Icons.work_rounded,
                      color: AppColors.primary,
                      bgColor: AppColors.primarySurface,
                    ),
                    StatCard(
                      label: "Today's Earnings",
                      value: '₹${_todayEarnings.toStringAsFixed(0)}',
                      icon: Icons.currency_rupee_rounded,
                      color: AppColors.success,
                      bgColor: AppColors.successLight,
                    ),
                    StatCard(
                      label: 'Pending Jobs',
                      value: '$_pendingJobsCount',
                      icon: Icons.pending_rounded,
                      color: AppColors.warning,
                      bgColor: AppColors.warningLight,
                    ),
                    StatCard(
                      label: 'Rating',
                      value: '${_rating.toStringAsFixed(1)} ⭐',
                      icon: Icons.star_rounded,
                      color: const Color(0xFFFF6F00),
                      bgColor: const Color(0xFFFFF8E1),
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
                      title: "Today's Jobs",
                    ),
                    const SizedBox(height: 14),
                    _TodayJobsList(jobs: _todayJobs),
                  ],
                ),
              ),
            ),
            // Performance
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _PerformanceCard(
                  rating: _rating,
                  completionRate: _completionRate,
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }
}

class _TechHeader extends StatelessWidget {
  final String name;
  final double rating;
  final String skills;
  final VoidCallback onChangeLocation;

  const _TechHeader({
    required this.name,
    required this.rating,
    required this.skills,
    required this.onChangeLocation,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty
        ? name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'Tech';
    final primarySkill = skills.isNotEmpty
        ? skills.split(',').first.trim()
        : 'Technician';

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
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: onChangeLocation,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          (Session.address != null && Session.address!.isNotEmpty)
                              ? (Session.address!.length > 25 ? '${Session.address!.substring(0, 22)}...' : Session.address!)
                              : 'Select Location KA',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.white70, size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 14),
                    const SizedBox(width: 3),
                    Text(
                      '${rating.toStringAsFixed(1)} Rating',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        primarySkill,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
  final List<dynamic> jobs;
  const _TodayJobsList({required this.jobs});

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No active jobs for today.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: jobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _TodayJobCard(job: jobs[i]),
    );
  }
}

class _TodayJobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  const _TodayJobCard({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final service = job['appliance_type'] ?? 'Repair Service';
    final customer = job['customer_name'] ?? 'Customer';
    final location = job['location'] ?? 'Location';
    final status = job['status'] ?? 'assigned';

    Widget statusBadge;
    if (status == 'in_progress') {
      statusBadge = StatusBadge.warning('Active');
    } else if (status == 'accepted') {
      statusBadge = StatusBadge.info('Accepted');
    } else if (status == 'completed') {
      statusBadge = StatusBadge.success('Done');
    } else {
      statusBadge = StatusBadge.info('Soon');
    }

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
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.build_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  customer,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        size: 12, color: AppColors.textTertiary),
                    const SizedBox(width: 3),
                    const Text('Today',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(width: 8),
                    const Icon(Icons.location_on_rounded,
                        size: 12, color: AppColors.textTertiary),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          statusBadge,
        ],
      ),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  final double rating;
  final int completionRate;

  const _PerformanceCard({
    required this.rating,
    required this.completionRate,
  });

  @override
  Widget build(BuildContext context) {
    final double completionVal = completionRate / 100.0;
    final double ratingVal = (rating > 0 && rating <= 5) ? rating / 5.0 : 1.0;

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
          const Text("This Week's Performance",
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 16),
          _PerfBar('Jobs Completed', completionVal, '$completionRate%', AppColors.primary),
          const SizedBox(height: 12),
          _PerfBar('Customer Rating', ratingVal, '${rating.toStringAsFixed(1)}/5.0', AppColors.success),
          const SizedBox(height: 12),
          _PerfBar('On-time Arrival', 0.98, '98%', AppColors.warning),
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
