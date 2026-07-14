import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'common_widgets.dart';
import 'api.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class TrackRepairScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const TrackRepairScreen({super.key, required this.booking});

  @override
  State<TrackRepairScreen> createState() => _TrackRepairScreenState();
}

class _TrackRepairScreenState extends State<TrackRepairScreen> {
  Map<String, dynamic>? _booking;

  @override
  void initState() {
    super.initState();
    if (widget.booking['status'] == null) {
      _booking = null;
    } else {
      _booking = widget.booking;
    }
    _fetchBookingDetails();
  }

  Future<void> _fetchBookingDetails() async {
    try {
      final resp = await Api.get('/bookings/details/${widget.booking['id']}');
      if (resp['status'] == 200) {
        setState(() {
          _booking = resp['data'];
        });
      }
    } catch (e) {
      // fallback to passed data
    }
  }

  void _showCancelDialog() {
    final reasonController = TextEditingController();
    bool isCancelling = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Cancel Repair Service', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please tell us the reason for cancelling this repair service:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Enter reason (e.g. Technician took too long, solved it myself, etc.)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isCancelling ? null : () => Navigator.pop(ctx),
              child: const Text('Go Back'),
            ),
            ElevatedButton(
              onPressed: isCancelling
                  ? null
                  : () async {
                      final reason = reasonController.text.trim();
                      if (reason.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a cancellation reason.')),
                        );
                        return;
                      }

                      setModalState(() => isCancelling = true);

                      try {
                        final resp = await Api.put('/bookings/${_booking!['id']}/cancel', {
                          'reason': reason,
                        });

                        if (resp['status'] == 200) {
                          Navigator.pop(ctx);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Repair service cancelled successfully.')),
                          );
                          _fetchBookingDetails();
                        } else {
                          final message = resp['data']['message'] ?? 'Failed to cancel repair';
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(message)),
                          );
                          setModalState(() => isCancelling = false);
                        }
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                        setModalState(() => isCancelling = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: isCancelling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Confirm Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_booking == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const FixigoAppBar(title: 'Track Repair'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final booking = _booking!;
    final status = booking['status'] ?? 'pending';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: FixigoAppBar(
        title: 'Track Repair',
        showBack: Navigator.of(context).canPop(),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            children: [
            if (status == 'cancelled') ...[
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_rounded, color: AppColors.error, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Repair Cancelled',
                            style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Reason: ${booking['cancellation_reason'] ?? 'No reason provided'}',
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Tech card
            _TechnicianCard(booking: booking),
            const SizedBox(height: 20),
            // Map placeholder
            _MapPlaceholder(booking: booking),
            const SizedBox(height: 20),
            // Job info
            _JobInfoCard(booking: booking),
            const SizedBox(height: 20),
            // Timeline
            _TimelineCard(booking: booking),
            const SizedBox(height: 20),
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final phone = booking['technician_phone'];
                      if (phone != null && phone.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Calling technician at $phone...')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No technician assigned to call yet.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.call_rounded, size: 18),
                    label: const Text('Call'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chat system starting...')),
                      );
                    },
                    icon: const Icon(Icons.chat_rounded, size: 18),
                    label: const Text('Chat'),
                  ),
                ),
              ],
            ),
            if (status != 'completed' && status != 'cancelled') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _showCancelDialog,
                  icon: const Icon(Icons.cancel_rounded, color: Colors.white, size: 20),
                  label: const Text(
                    'Cancel Repair',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
        ),
      ),
    );
  }
}

class _TechnicianCard extends StatelessWidget {
  final Map<String, dynamic> booking;

  const _TechnicianCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final techName = booking['technician_name'];
    final hasTech = techName != null && techName.toString().isNotEmpty;
    final initials = hasTech
        ? techName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              if (hasTech)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hasTech ? techName : 'Assigning Technician...',
                    style:
                        const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                if (hasTech) ...[
                  Row(
                    children: [
                      ...List.generate(
                          5,
                          (i) => Icon(
                              i < 4
                                  ? Icons.star_rounded
                                  : Icons.star_half_rounded,
                              size: 14,
                              color: Colors.amber[600])),
                      const SizedBox(width: 4),
                      Text('${booking['rating'] ?? '4.8'} (127)',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      StatusBadge(
                        text: 'Verified',
                        color: AppColors.success,
                        bgColor: AppColors.successLight,
                      ),
                      SizedBox(width: 6),
                      Text('Repair Specialist',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ] else ...[
                  const Text('Finding the best technician for your repair',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  final Map<String, dynamic> booking;

  const _MapPlaceholder({required this.booking});

  @override
  Widget build(BuildContext context) {
    final status = booking['status'] ?? 'pending';

    String eta = 'Finding Technician...';
    if (status == 'assigned') {
      eta = 'ETA: 30 mins';
    } else if (status == 'in_progress') {
      eta = 'Ongoing Service';
    } else if (status == 'pending') {
      eta = 'Scheduling...';
    } else if (status == 'completed') {
      eta = 'Service Completed';
    }

    final double custLat = double.tryParse(booking['latitude']?.toString() ?? '') ?? 12.971598;
    final double custLon = double.tryParse(booking['longitude']?.toString() ?? '') ?? 77.594562;
    final custPoint = LatLng(custLat, custLon);

    final double? techLat = double.tryParse(booking['technician_latitude']?.toString() ?? '');
    final double? techLon = double.tryParse(booking['technician_longitude']?.toString() ?? '');

    final LatLng centerPoint;
    final double distance;
    if (techLat != null && techLon != null) {
      centerPoint = LatLng((custLat + techLat) / 2, (custLon + techLon) / 2);
      final double distanceInMeters = Geolocator.distanceBetween(custLat, custLon, techLat, techLon);
      distance = distanceInMeters / 1000.0;
    } else {
      centerPoint = custPoint;
      distance = 0.0;
    }

    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('customer'),
        position: custPoint,
        infoWindow: const InfoWindow(title: 'My House'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
      if (techLat != null && techLon != null)
        Marker(
          markerId: const MarkerId('technician'),
          position: LatLng(techLat, techLon),
          infoWindow: const InfoWindow(title: 'Technician'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
    };

    final Set<Polyline> polylines = {
      if (techLat != null && techLon != null)
        Polyline(
          polylineId: const PolylineId('route'),
          points: [custPoint, LatLng(techLat, techLon)],
          color: AppColors.primary,
          width: 4,
        ),
    };

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: centerPoint,
              zoom: techLat != null ? 12.0 : 14.0,
            ),
            markers: markers,
            polylines: polylines,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                techLat != null
                    ? '${distance.toStringAsFixed(1)} km away • $eta'
                    : eta,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: FloatingActionButton.small(
              heroTag: 'view_in_google_maps_customer',
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              onPressed: () async {
                final url = 'https://www.google.com/maps/search/?api=1&query=$custLat,$custLon';
                final uri = Uri.parse(url);
                try {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not open maps: $e')),
                  );
                }
              },
              tooltip: 'View on Google Maps',
              child: const Icon(Icons.navigation_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _JobInfoCard extends StatelessWidget {
  final Map<String, dynamic> booking;

  const _JobInfoCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final status = booking['status'] ?? 'pending';

    StatusBadge statusBadge;
    if (status == 'pending') {
      statusBadge = StatusBadge.info('Pending');
    } else if (status == 'assigned') {
      statusBadge = StatusBadge.warning('Assigned');
    } else if (status == 'in_progress') {
      statusBadge = StatusBadge.warning('In Progress');
    } else if (status == 'completed') {
      statusBadge = StatusBadge.success('Completed');
    } else {
      statusBadge = StatusBadge.error('Cancelled');
    }

    final preferredDate = booking['preferred_date'] ?? 'Today';

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Job Details',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              statusBadge,
            ],
          ),
          const SizedBox(height: 12),
          InfoRow(
              icon: Icons.build_rounded,
              label: 'Service',
              value: booking['appliance_type'] ?? 'General Repair'),
          const Divider(),
          InfoRow(
              icon: Icons.tag_rounded,
              label: 'Booking ID',
              value: 'FIX-${booking['id']}'),
          const Divider(),
          InfoRow(
              icon: Icons.schedule_rounded,
              label: 'Scheduled',
              value: '$preferredDate • 9:00 AM – 6:00 PM'),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final Map<String, dynamic> booking;

  const _TimelineCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final status = booking['status'] ?? 'pending';
    final hasTech = booking['technician_name'] != null;

    final steps = [
      _TimeStep(
        'Booking Confirmed',
        'Your booking has been confirmed',
        true,
        status == 'pending' && !hasTech,
        Icons.check_circle_rounded,
      ),
      _TimeStep(
        'Technician Assigned',
        hasTech
            ? '${booking['technician_name']} has been assigned'
            : 'Finding a nearby technician',
        hasTech,
        status == 'pending' && hasTech,
        Icons.engineering_rounded,
      ),
      _TimeStep(
        'On the Way',
        'Technician is heading to your location',
        status == 'assigned' || status == 'in_progress' || status == 'completed',
        status == 'assigned',
        Icons.electric_moped_rounded,
      ),
      _TimeStep(
        'Service Ongoing',
        'Repair in progress',
        status == 'in_progress' || status == 'completed',
        status == 'in_progress',
        Icons.build_rounded,
      ),
      _TimeStep(
        'Job Completed',
        'Payment & invoice',
        status == 'completed',
        status == 'completed',
        Icons.task_alt_rounded,
      ),
    ];

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
          const Text('Repair Progress',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (i) {
            final s = steps[i];
            final isLast = i == steps.length - 1;
            return _TimelineRow(
              step: s,
              isLast: isLast,
              isActive: s.active,
            );
          }),
        ],
      ),
    );
  }
}

class _TimeStep {
  final String title, subtitle;
  final bool done, active;
  final IconData icon;
  const _TimeStep(this.title, this.subtitle, this.done, this.active, this.icon);
}

class _TimelineRow extends StatelessWidget {
  final _TimeStep step;
  final bool isLast, isActive;

  const _TimelineRow({
    super.key,
    required this.step,
    required this.isLast,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final color = step.done
        ? AppColors.primary
        : isActive
            ? AppColors.secondary
            : AppColors.textTertiary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: step.done
                    ? AppColors.primarySurface
                    : isActive
                        ? AppColors.secondarySurface
                        : AppColors.surfaceVariant,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(step.icon, size: 18, color: color),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                margin: const EdgeInsets.symmetric(vertical: 3),
                color: step.done
                    ? AppColors.primary.withOpacity(0.3)
                    : AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 4, bottom: isLast ? 0 : 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: step.done || isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: color)),
                const SizedBox(height: 2),
                Text(step.subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
