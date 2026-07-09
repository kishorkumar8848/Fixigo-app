import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'common_widgets.dart';
import 'api.dart';
import 'session.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class ActiveJobScreen extends StatefulWidget {
  const ActiveJobScreen({super.key});

  @override
  State<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends State<ActiveJobScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _activeJob;

  final _checklist = [
    _CheckItem('Inspect appliance and identify issue', false),
    _CheckItem('Check power supply and connections', false),
    _CheckItem('Clean filters and components', true),
    _CheckItem('Refill gas / replace parts', false),
    _CheckItem('Test appliance functionality', false),
    _CheckItem('Collect customer sign-off', false),
  ];

  @override
  void initState() {
    super.initState();
    _fetchActiveJob();
  }

  Future<void> _fetchActiveJob() async {
    try {
      final resp = await Api.get('/technician/jobs');
      if (resp['status'] == 200 && resp['data'] is List) {
        final List<dynamic> jobs = resp['data'];
        // Find first job with status in_progress or accepted
        final job = jobs.firstWhere(
          (j) => j['status'] == 'in_progress',
          orElse: () => jobs.firstWhere(
            (j) => j['status'] == 'accepted',
            orElse: () => null,
          ),
        );
        setState(() {
          _activeJob = job;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateJobStatus(String status) async {
    if (_activeJob == null) return;
    setState(() => _isLoading = true);
    try {
      final resp = await Api.patch('/technician/jobs/${_activeJob!['id']}/status', {
        'status': status,
      });
      if (resp['status'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Job status updated successfully to $status!')),
        );
        await _fetchActiveJob();
      } else {
        final message = resp['data']['message'] ?? 'Failed to update job status';
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

  void _showCompleteSheet() {
    if (_activeJob == null) return;
    final double bookingFee = double.tryParse(_activeJob!['booking_fee']?.toString() ?? '50.0') ?? 50.0;
    final String initialPrice = _activeJob!['price']?.toString() ?? '500';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CompleteJobSheet(
        initialPrice: initialPrice,
        bookingFee: bookingFee,
        onConfirm: (finalPrice) async {
          await _updateJobStatusWithPrice('completed', finalPrice);
        },
      ),
    );
  }

  Future<void> _updateJobStatusWithPrice(String status, double price) async {
    if (_activeJob == null) return;
    setState(() => _isLoading = true);
    try {
      final resp = await Api.patch('/technician/jobs/${_activeJob!['id']}/status', {
        'status': status,
        'price': price,
      });
      if (resp['status'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Job completed with service charge ₹${price.toStringAsFixed(0)}!')),
        );
        await _fetchActiveJob();
      } else {
        final message = resp['data']['message'] ?? 'Failed to complete job';
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

  void _callCustomer() {
    if (_activeJob == null) return;
    final name = _activeJob!['customer_name'] ?? 'Customer';
    final phone = _activeJob!['customer_phone'] ?? 'Unknown';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Contact Customer', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: $name', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Phone: $phone'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Calling $phone...')),
              );
            },
            icon: const Icon(Icons.call),
            label: const Text('Call'),
          ),
        ],
      ),
    );
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

    if (_activeJob == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const FixigoAppBar(title: 'Active Job'),
        body: RefreshIndicator(
          onRefresh: _fetchActiveJob,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Container(
              height: 400,
              alignment: Alignment.center,
              padding: EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_rounded, size: 64, color: AppColors.textTertiary),
                  SizedBox(height: 16),
                  Text(
                    'No Active Jobs',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Head over to the Jobs tab to accept a job request and start working.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final job = _activeJob!;
    final status = job['status'] ?? 'accepted';
    final isStarted = status == 'in_progress';

    final double custLat = double.tryParse(job['customer_latitude']?.toString() ?? '') ?? 12.971598;
    final double custLon = double.tryParse(job['customer_longitude']?.toString() ?? '') ?? 77.594562;
    final double techLat = Session.latitude ?? 12.971598;
    final double techLon = Session.longitude ?? 77.594562;
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
        infoWindow: const InfoWindow(title: 'My Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
      Marker(
        markerId: const MarkerId('customer'),
        position: custPoint,
        infoWindow: const InfoWindow(title: 'Customer Location'),
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: FixigoAppBar(
        title: 'Active Job',
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchActiveJob,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _JobHeaderCard(job: job),
              const SizedBox(height: 16),
              _CustomerCard(job: job, onCall: _callCustomer),
              const SizedBox(height: 16),
              
              // Map section if started
              if (isStarted) ...[
                const Text('Routing & Navigation',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Container(
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
                          target: LatLng(centerLat, centerLon),
                          zoom: 12.0,
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
                            'Distance: ${distance.toStringAsFixed(1)} km',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: FloatingActionButton.small(
                          heroTag: 'view_in_google_maps_tech',
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
                          child: const Icon(Icons.navigation_rounded, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Checklist
              const Text('Repair Checklist',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('Complete all steps to finish the job',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: List.generate(_checklist.length, (i) {
                    final item = _checklist[i];
                    return Column(
                      children: [
                        CheckboxListTile(
                          value: item.done,
                          onChanged: !isStarted ? null : (v) =>
                              setState(() => _checklist[i].done = v ?? false),
                          title: Text(
                            item.task,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: item.done
                                  ? AppColors.textTertiary
                                  : AppColors.textPrimary,
                              decoration:
                                  item.done ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          activeColor: AppColors.secondary,
                          checkColor: Colors.white,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 2),
                        ),
                        if (i < _checklist.length - 1)
                          const Padding(
                            padding: EdgeInsets.only(left: 56),
                            child: Divider(height: 1),
                          ),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),
              // Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_checklist.where((c) => c.done).length}/${_checklist.length} tasks done',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary),
                  ),
                  Text(
                    '${((_checklist.where((c) => c.done).length / _checklist.length) * 100).toInt()}%',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value:
                      _checklist.where((c) => c.done).length / _checklist.length,
                  backgroundColor: AppColors.border,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 20),
              
              // Parts used (only visual)
              _PartsCard(),
              const SizedBox(height: 20),
              
              // Notes
              const TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Repair Notes (Optional)',
                  hintText: 'Describe the repair done, parts replaced, etc.',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(left: 12, top: 12),
                    child: Icon(Icons.note_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Action button
              if (!isStarted)
                GradientButton(
                  text: 'Start Job / Mark In-Progress',
                  onTap: () => _updateJobStatus('in_progress'),
                  gradient: const LinearGradient(
                      colors: [Color(0xFF00897B), Color(0xFF26C6DA)]),
                  icon: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 20),
                )
              else
                GradientButton(
                  text: 'Mark Job as Completed',
                  onTap: _showCompleteSheet,
                  gradient: const LinearGradient(
                      colors: [Color(0xFF00897B), Color(0xFF26C6DA)]),
                  icon: const Icon(Icons.task_alt_rounded,
                      color: Colors.white, size: 20),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _callCustomer,
                icon: const Icon(Icons.call_rounded, size: 18),
                label: const Text('Call Customer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckItem {
  final String task;
  bool done;
  _CheckItem(this.task, this.done);
}

class _JobHeaderCard extends StatelessWidget {
  final Map<String, dynamic> job;
  const _JobHeaderCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final service = job['appliance_type'] ?? 'Repair Service';
    final bookingId = job['booking_id'] != null ? 'FIX-2026-${job['booking_id']}' : 'FIX-2026-JOB';
    final status = job['status'] ?? 'accepted';

    String statusLabel = 'Accepted';
    Color badgeColor = Colors.amber;
    if (status == 'in_progress') {
      statusLabel = 'In Progress';
      badgeColor = Colors.orange;
    } else if (status == 'completed') {
      statusLabel = 'Completed';
      badgeColor = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF00897B)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.build_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                const SizedBox(height: 4),
                const Text('Doorstep Appliance Service',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(bookingId,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(statusLabel,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback onCall;
  const _CustomerCard({required this.job, required this.onCall});

  @override
  Widget build(BuildContext context) {
    final name = job['customer_name'] ?? 'Customer';
    final address = job['location'] ?? 'Location';
    final initials = name.isNotEmpty
        ? name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'C';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Customer Info',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(initials,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(address,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onCall,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.call_rounded,
                      color: AppColors.primary, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PartsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Parts Used',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              GestureDetector(
                onTap: () {},
                child: const Text('+ Add Part',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _PartRow('Standard Consumables', 1, '₹150'),
          const Divider(),
          _PartRow('Safety Seal / Tape', 2, '₹80'),
          const Divider(),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Total Parts Cost',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              Text('₹230',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                      fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _PartRow(String name, int qty, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(name, style: const TextStyle(fontSize: 13))),
          Text('x$qty',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(width: 16),
          Text(price,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}

class _CompleteJobSheet extends StatefulWidget {
  final String initialPrice;
  final double bookingFee;
  final ValueChanged<double> onConfirm;

  const _CompleteJobSheet({
    required this.initialPrice,
    required this.bookingFee,
    required this.onConfirm,
  });

  @override
  State<_CompleteJobSheet> createState() => _CompleteJobSheetState();
}

class _CompleteJobSheetState extends State<_CompleteJobSheet> {
  late TextEditingController _priceController;
  double _totalPrice = 500.0;
  double _collectAmount = 450.0;

  @override
  void initState() {
    super.initState();
    final double initPrice = double.tryParse(widget.initialPrice) ?? 500.0;
    _priceController = TextEditingController(text: initPrice.toStringAsFixed(0));
    _totalPrice = initPrice;
    _calculateAmount();
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _calculateAmount() {
    final double entered = double.tryParse(_priceController.text) ?? 0.0;
    setState(() {
      _totalPrice = entered;
      _collectAmount = entered - widget.bookingFee;
      if (_collectAmount < 0) _collectAmount = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text('Complete This Job',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
                'Enter the final service price to calculate customer collection details.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 20),
          
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            onChanged: (_) => _calculateAmount(),
            decoration: const InputDecoration(
              labelText: 'Total Service Charge (₹)',
              hintText: 'Enter total amount',
              prefixIcon: Icon(Icons.currency_rupee_rounded),
            ),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Service Price', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    Text('₹${_totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Booking Fee (Deducted)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    Text('-₹${widget.bookingFee.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.error)),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Collect from Customer',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      '₹${_collectAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          GradientButton(
            text: 'Confirm Job Completion',
            onTap: () {
              if (_totalPrice >= widget.bookingFee) {
                Navigator.pop(context);
                widget.onConfirm(_totalPrice);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Total price must be at least the booking fee of ₹${widget.bookingFee.toStringAsFixed(0)}.')),
                );
              }
            },
            gradient: const LinearGradient(
                colors: [Color(0xFF00897B), Color(0xFF26C6DA)]),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
          ),
        ],
      ),
    );
  }
}
