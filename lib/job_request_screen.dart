import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'common_widgets.dart';
import 'api.dart';
import 'session.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class JobRequestsScreen extends StatefulWidget {
  const JobRequestsScreen({super.key});

  @override
  State<JobRequestsScreen> createState() => _JobRequestsScreenState();
}

class _JobRequestsScreenState extends State<JobRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _isLoading = true;
  List<dynamic> _jobs = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _fetchJobs();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _fetchJobs() async {
    try {
      final resp = await Api.get('/technician/jobs');
      if (resp['status'] == 200 && resp['data'] is List) {
        setState(() {
          _jobs = resp['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptJob(int jobId) async {
    setState(() => _isLoading = true);
    try {
      final resp = await Api.post('/technician/jobs/$jobId/accept', {});
      if (resp['status'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job accepted successfully!')),
        );
        await _fetchJobs();
        _tab.animateTo(1);
      } else {
        final message = resp['data']['message'] ?? 'Failed to accept job';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectJob(int jobId) async {
    setState(() => _isLoading = true);
    try {
      final resp = await Api.post('/technician/jobs/$jobId/reject', {});
      if (resp['status'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job declined.')),
        );
        await _fetchJobs();
        _tab.animateTo(2);
      } else {
        final message = resp['data']['message'] ?? 'Failed to decline job';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  void _showMap(Map<String, dynamic> job) {
    final double custLat = double.tryParse(job['customer_latitude']?.toString() ?? '') ?? 12.971598;
    final double custLon = double.tryParse(job['customer_longitude']?.toString() ?? '') ?? 77.594562;
    final double techLat = Session.latitude ?? 12.971598;
    final double techLon = Session.longitude ?? 77.594562;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildMapSheet(ctx, techLat, techLon, custLat, custLon),
    );
  }

  Widget _buildMapSheet(BuildContext context, double techLat, double techLon, double custLat, double custLon) {
    final techPoint = LatLng(techLat, techLon);
    final custPoint = LatLng(custLat, custLon);
    final centerLat = (techLat + custLat) / 2;
    final centerLon = (techLon + custLon) / 2;
    final double distanceInMeters = Geolocator.distanceBetween(techLat, techLon, custLat, custLon);
    final double distance = distanceInMeters / 1000.0;

    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('technician'),
        position: techPoint,
        infoWindow: const InfoWindow(title: 'My Position'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
      Marker(
        markerId: const MarkerId('customer'),
        position: custPoint,
        infoWindow: const InfoWindow(title: 'Customer Home'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    };

    final Set<Polyline> polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [techPoint, custPoint],
        color: AppColors.primary,
        width: 4,
      ),
    };

    return Container(
      height: 450,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(centerLat, centerLon),
              zoom: 12.0,
            ),
            markers: markers,
            polylines: polylines,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Distance: ${distance.toStringAsFixed(1)} km',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'view_in_google_maps_request',
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              onPressed: () async {
                final url = 'https://www.google.com/maps/dir/?api=1&origin=$techLat,$techLon&destination=$custLat,$custLon&travelmode=driving';
                final uri = Uri.parse(url);
                try {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not open maps: $e')),
                  );
                }
              },
              tooltip: 'Start Navigation',
              child: const Icon(Icons.navigation_rounded),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final newJobs = _jobs.where((j) => j['status'] == 'assigned').toList();
    final acceptedJobs = _jobs.where((j) => j['status'] == 'accepted' || j['status'] == 'in_progress').toList();
    final rejectedJobs = _jobs.where((j) => j['status'] == 'rejected').toList();

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
      appBar: FixigoAppBar(
        title: 'Job Requests',
        actions: [
          if (newJobs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${newJobs.length} New',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchJobs,
        child: Column(
          children: [
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: TabBar(
                controller: _tab,
                labelColor: AppColors.secondary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.secondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: [
                  Tab(text: 'New (${newJobs.length})'),
                  Tab(text: 'Accepted (${acceptedJobs.length})'),
                  Tab(text: 'Rejected (${rejectedJobs.length})'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _NewJobsList(
                    jobs: newJobs,
                    onAccept: _acceptJob,
                    onReject: _rejectJob,
                    onViewMap: _showMap,
                  ),
                  _AcceptedList(jobs: acceptedJobs),
                  _RejectedList(jobs: rejectedJobs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewJobsList extends StatelessWidget {
  final List<dynamic> jobs;
  final ValueChanged<int> onAccept, onReject;
  final ValueChanged<Map<String, dynamic>> onViewMap;

  const _NewJobsList({
    required this.jobs,
    required this.onAccept,
    required this.onReject,
    required this.onViewMap,
  });

  IconData _getApplianceIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('ac') || lower.contains('cooler') || lower.contains('conditioner')) return Icons.ac_unit_rounded;
    if (lower.contains('refrigerator') || lower.contains('freezer')) return Icons.kitchen_rounded;
    if (lower.contains('washing') || lower.contains('dryer') || lower.contains('iron')) return Icons.local_laundry_service_rounded;
    if (lower.contains('tv') || lower.contains('theater') || lower.contains('sound') || lower.contains('speaker')) return Icons.tv_rounded;
    if (lower.contains('laptop') || lower.contains('pc') || lower.contains('printer') || lower.contains('router')) return Icons.laptop_chromebook_rounded;
    if (lower.contains('purifier') || lower.contains('heater') || lower.contains('geyser') || lower.contains('pump') || lower.contains('motor')) return Icons.water_drop_rounded;
    return Icons.build_rounded;
  }

  Color _getApplianceColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('ac') || lower.contains('cooler') || lower.contains('conditioner')) return const Color(0xFF1565C0);
    if (lower.contains('refrigerator') || lower.contains('freezer')) return const Color(0xFF1565C0);
    if (lower.contains('washing') || lower.contains('dryer') || lower.contains('iron')) return const Color(0xFF00897B);
    if (lower.contains('tv') || lower.contains('theater') || lower.contains('sound') || lower.contains('speaker')) return const Color(0xFF0277BD);
    if (lower.contains('laptop') || lower.contains('pc') || lower.contains('printer') || lower.contains('router')) return const Color(0xFF6A1B9A);
    return const Color(0xFFE65100);
  }

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return const EmptyState(
        icon: Icons.inbox_rounded,
        title: 'No New Requests',
        subtitle: 'New service bookings within 20km will show up here',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: jobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) {
        final job = jobs[i];
        final double custLat = double.tryParse(job['customer_latitude']?.toString() ?? '') ?? 12.971598;
        final double custLon = double.tryParse(job['customer_longitude']?.toString() ?? '') ?? 77.594562;
        final double techLat = Session.latitude ?? 12.971598;
        final double techLon = Session.longitude ?? 77.594562;
        final double distanceInMeters = Geolocator.distanceBetween(techLat, techLon, custLat, custLon);
        final double dist = distanceInMeters / 1000.0;

        return _JobRequestCard(
          job: job,
          distance: '${dist.toStringAsFixed(1)} km',
          icon: _getApplianceIcon(job['appliance_type'] ?? ''),
          color: _getApplianceColor(job['appliance_type'] ?? ''),
          onAccept: () => onAccept(job['id']),
          onReject: () => onReject(job['id']),
          onViewMap: () => onViewMap(job),
        );
      },
    );
  }
}

class _JobRequestCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final String distance;
  final IconData icon;
  final Color color;
  final VoidCallback onAccept, onReject, onViewMap;

  const _JobRequestCard({
    required this.job,
    required this.distance,
    required this.icon,
    required this.color,
    required this.onAccept,
    required this.onReject,
    required this.onViewMap,
  });

  @override
  Widget build(BuildContext context) {
    final service = job['appliance_type'] ?? 'Service';
    final customer = job['customer_name'] ?? 'Customer';
    final address = job['location'] ?? 'Location';
    final payout = job['price'] != null ? '₹${job['price']}' : '₹499';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
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
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(service,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          Text(customer,
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: onViewMap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.map_rounded, color: AppColors.primary, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Map',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _InfoChip(Icons.location_on_rounded, address)),
                    const SizedBox(width: 8),
                    _InfoChip(Icons.directions_rounded, distance),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Payout: $payout',
                          style: const TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ),
                    const Spacer(),
                    const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textTertiary),
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
                    gradient: const LinearGradient(colors: [Color(0xFF00897B), Color(0xFF26C6DA)]),
                    icon: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
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
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _AcceptedList extends StatelessWidget {
  final List<dynamic> jobs;
  const _AcceptedList({required this.jobs});

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return const EmptyState(
        icon: Icons.assignment_turned_in_rounded,
        title: 'No Accepted Jobs',
        subtitle: 'Accepted jobs will appear here',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: jobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final job = jobs[i];
        final service = job['appliance_type'] ?? 'Repair';
        final customer = job['customer_name'] ?? 'Customer';
        final preferredDate = job['preferred_date'] ?? 'Today';
        final status = job['status'] ?? 'accepted';
        final statusLabel = status == 'in_progress' ? 'In Progress' : 'Accepted';

        return _SimpleJobCard(
          service,
          customer,
          preferredDate.toString().substring(0, 10),
          statusLabel,
          AppColors.success,
        );
      },
    );
  }
}

class _RejectedList extends StatelessWidget {
  final List<dynamic> jobs;
  const _RejectedList({required this.jobs});

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return const EmptyState(
        icon: Icons.do_not_disturb_rounded,
        title: 'No Declined Jobs',
        subtitle: "You haven't declined any jobs recently",
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: jobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final job = jobs[i];
        final service = job['appliance_type'] ?? 'Repair';
        final customer = job['customer_name'] ?? 'Customer';

        return _SimpleJobCard(
          service,
          customer,
          'Declined',
          'Declined',
          AppColors.error,
        );
      },
    );
  }
}

class _SimpleJobCard extends StatelessWidget {
  final String service, customer, time, status;
  final Color color;

  const _SimpleJobCard(this.service, this.customer, this.time, this.status, this.color);

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
                Text(service, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text('$customer • $time', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          StatusBadge(
            text: status,
            color: color,
            bgColor: color.withOpacity(0.1),
          ),
        ],
      ),
    );
  }
}
