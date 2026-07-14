import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_theme.dart';
import 'common_widgets.dart';
import 'api.dart';
import 'session.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'location_picker_screen.dart';
import 'track_repair_screen.dart';


class BookServiceScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialIssue;
  final VoidCallback? onBookingCompleted;

  const BookServiceScreen({
    super.key,
    this.initialCategory,
    this.initialIssue,
    this.onBookingCompleted,
  });

  @override
  State<BookServiceScreen> createState() => _BookServiceScreenState();
}

class _BookServiceScreenState extends State<BookServiceScreen> {
  int _step = 0;
  int? _selectedAppliance;
  int? _selectedIssue;
  String? _selectedSlot;
  DateTime _selectedDate = DateTime.now();
  final _issueController = TextEditingController();
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _parsePrefilledInfo();
  }

  @override
  void didUpdateWidget(covariant BookServiceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategory != oldWidget.initialCategory ||
        widget.initialIssue != oldWidget.initialIssue) {
      _parsePrefilledInfo();
    }
  }

  void _parsePrefilledInfo() {
    if (widget.initialCategory != null) {
      final idx = _mapCategoryToIndex(widget.initialCategory);
      if (idx != null) {
        _selectedAppliance = idx;
        _step = 1;
      }
    } else {
      _selectedAppliance = null;
      _step = 0;
    }

    if (widget.initialIssue != null) {
      final issues = _currentIssues;
      final idx = issues.indexOf(widget.initialIssue!);
      if (idx != -1) {
        _selectedIssue = idx;
        _step = 2;
      } else {
        // Prefill unknown free-text issues under "Other Issue"
        final otherIdx = issues.indexOf(ApplianceIssues.otherLabel);
        _selectedIssue = otherIdx >= 0 ? otherIdx : issues.length - 1;
        _issueController.text = widget.initialIssue!;
        _step = 2;
      }
    } else {
      _selectedIssue = null;
      _issueController.clear();
    }
  }

  /// Issues for the currently selected appliance (always includes "Other Issue").
  List<String> get _currentIssues {
    if (_selectedAppliance == null) {
      return ApplianceIssues.generic;
    }
    return ApplianceIssues.forAppliance(_appliances[_selectedAppliance!].name);
  }

  bool get _isOtherIssueSelected {
    if (_selectedIssue == null) return false;
    final issues = _currentIssues;
    if (_selectedIssue! < 0 || _selectedIssue! >= issues.length) return false;
    return issues[_selectedIssue!] == ApplianceIssues.otherLabel;
  }

  String get _selectedIssueText {
    if (_selectedIssue == null) return '';
    final issues = _currentIssues;
    if (_selectedIssue! < 0 || _selectedIssue! >= issues.length) return '';
    final label = issues[_selectedIssue!];
    if (label == ApplianceIssues.otherLabel) {
      return _issueController.text.trim();
    }
    return label;
  }

  int? _mapCategoryToIndex(String? category) {
    if (category == null) return null;
    final lower = category.toLowerCase();
    
    // Find the appliance whose name matches the category query
    for (int i = 0; i < _appliances.length; i++) {
      final name = _appliances[i].name.toLowerCase();
      if (name.contains(lower) || lower.contains(name)) {
        return i;
      }
    }
    
    // Fallback shorthand mappings
    if (lower.contains('ac') || lower.contains('air conditioner')) return 0;
    if (lower.contains('cooler')) return 1;
    if (lower.contains('washing') || lower.contains('laundry')) return 17;
    if (lower.contains('refrigerator') || lower.contains('fridge')) return 2;
    if (lower.contains('microwave')) return 15;
    if (lower.contains('tv') || lower.contains('television')) return 21;
    if (lower.contains('purifier') || lower.contains('water purifier')) return 45;
    if (lower.contains('geyser') || lower.contains('water heater')) return 46;
    if (lower.contains('chimney')) return 16;
    
    return null;
  }

  Future<void> _chooseLocationOnMap() async {
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
        await Api.put('/auth/customer/profile/${Session.userId}', {
          'name': Session.name ?? 'User',
          'email': Session.email ?? '',
          'phone': Session.phone ?? '',
          'address': result.address,
        });
      } catch (_) {}
    }
  }

  Future<void> _createBooking() async {
    setState(() => _isBooking = true);

    final applianceName = _appliances[_selectedAppliance!].name;
    final issueName = _selectedIssueText.isNotEmpty
        ? _selectedIssueText
        : ApplianceIssues.otherLabel;
    final preferredDate = _selectedDate.toIso8601String().substring(0, 10); // YYYY-MM-DD

    try {
      final resp = await Api.post('/bookings/initiate', {
        'customerId': Session.userId,
        'appliance_type': applianceName,
        'issue_description': issueName,
        'location': Session.address != null && Session.address!.isNotEmpty
            ? Session.address
            : '42, 3rd Cross, Indiranagar, Bengaluru',
        'preferred_date': preferredDate,
        'latitude': Session.latitude,
        'longitude': Session.longitude,
      });

      if (resp['status'] != 200) {
        final message = resp['data']['message'] ?? 'Failed to initiate booking';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        return;
      }

      final bookingId = resp['data']['bookingId'];
      String paymentUrl = resp['data']['paymentUrl'] ?? '';

      if (paymentUrl.contains('localhost:3000')) {
        paymentUrl = paymentUrl.replaceAll('http://localhost:3000', Api.baseUrl);
      } else if (paymentUrl.contains('127.0.0.1:3000')) {
        paymentUrl = paymentUrl.replaceAll('http://127.0.0.1:3000', Api.baseUrl);
      }

      // Upgrade cleartext http to https if using a secure production backend
      if (Api.baseUrl.startsWith('https://') && paymentUrl.startsWith('http://')) {
        paymentUrl = paymentUrl.replaceFirst('http://', 'https://');
      }

      if (paymentUrl.isEmpty) {
        throw 'Payment URL is empty';
      }

      final uri = Uri.parse(paymentUrl);
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        throw 'Could not launch payment gateway URL: $e';
      }

      if (!mounted) return;
      final bool? isVerified = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (_) => PaymentVerificationSheet(
          bookingId: bookingId,
        ),
      );

      if (isVerified == true) {
        if (widget.onBookingCompleted != null) {
          widget.onBookingCompleted!();
        }
        _showBookingSuccess(bookingId.toString());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment verification incomplete. Booking status: Pending Payment.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  final _appliances = const [
    // --- Cooling Appliances ---
    _ApplianceItem(
      'Air Conditioner',
      Icons.ac_unit_rounded,
      Color(0xFF1565C0),
      'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=500&auto=format&fit=crop&q=60',
      'Cooling Appliances',
    ),
    _ApplianceItem(
      'Air Cooler',
      Icons.wind_power,
      Color(0xFF1565C0),
      'https://images.unsplash.com/photo-1585338107529-13afc5f02586?w=500&auto=format&fit=crop&q=60',
      'Cooling Appliances',
    ),
    _ApplianceItem(
      'Refrigerator',
      Icons.kitchen_rounded,
      Color(0xFF1565C0),
      'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=500&auto=format&fit=crop&q=60',
      'Cooling Appliances',
    ),
    _ApplianceItem(
      'Deep Freezer',
      Icons.kitchen_rounded,
      Color(0xFF1565C0),
      'https://images.unsplash.com/photo-1571175482282-46698683e444?w=500&auto=format&fit=crop&q=60',
      'Cooling Appliances',
    ),
    _ApplianceItem(
      'Water Cooler',
      Icons.water_drop_rounded,
      Color(0xFF1565C0),
      'https://images.unsplash.com/photo-1589139011550-2b556e300240?w=500&auto=format&fit=crop&q=60',
      'Cooling Appliances',
    ),

    // --- Kitchen Appliances ---
    _ApplianceItem(
      'Mixer Grinder',
      Icons.blender_rounded,
      Color(0xFFE65100),
      'https://images.unsplash.com/photo-1578643463396-0997cb5328c1?w=500&auto=format&fit=crop&q=60',
      'Kitchen Appliances',
    ),
    _ApplianceItem(
      'Induction Stove',
      Icons.microwave_rounded,
      Color(0xFFE65100),
      'https://images.unsplash.com/photo-1574269909862-7e1d70bb8078?w=500&auto=format&fit=crop&q=60',
      'Kitchen Appliances',
    ),
    _ApplianceItem(
      'Gas Stove',
      Icons.outdoor_grill_rounded,
      Color(0xFFE65100),
      'https://images.unsplash.com/photo-1522869635100-9f4c5e86aa37?w=500&auto=format&fit=crop&q=60',
      'Kitchen Appliances',
    ),
    _ApplianceItem(
      'Electric Kettle',
      Icons.coffee_maker_rounded,
      Color(0xFFE65100),
      'https://images.unsplash.com/photo-1594897030264-ab7d87efc473?w=500&auto=format&fit=crop&q=60',
      'Kitchen Appliances',
    ),
    _ApplianceItem(
      'Rice Cooker',
      Icons.rice_bowl_rounded,
      Color(0xFFE65100),
      'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=500&auto=format&fit=crop&q=60',
      'Kitchen Appliances',
    ),
    _ApplianceItem(
      'Air Fryer',
      Icons.kitchen_rounded,
      Color(0xFFE65100),
      'https://images.unsplash.com/photo-1621972750749-0fbb1abb7736?w=500&auto=format&fit=crop&q=60',
      'Kitchen Appliances',
    ),
    _ApplianceItem(
      'Toaster',
      Icons.breakfast_dining_rounded,
      Color(0xFFE65100),
      'https://images.unsplash.com/photo-1583694921277-289f417de11f?w=500&auto=format&fit=crop&q=60',
      'Kitchen Appliances',
    ),
    _ApplianceItem(
      'Coffee Maker',
      Icons.coffee_maker_rounded,
      Color(0xFFE65100),
      'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=500&auto=format&fit=crop&q=60',
      'Kitchen Appliances',
    ),
    _ApplianceItem(
      'Dishwasher',
      Icons.local_laundry_service_rounded,
      Color(0xFFE65100),
      'https://images.unsplash.com/photo-1585515320310-259814833e62?w=500&auto=format&fit=crop&q=60',
      'Kitchen Appliances',
    ),
    _ApplianceItem(
      'OTG Oven',
      Icons.microwave_rounded,
      Color(0xFFE65100),
      'https://images.unsplash.com/photo-1527018601619-a508a2be00cd?w=500&auto=format&fit=crop&q=60',
      'Kitchen Appliances',
    ),
    _ApplianceItem(
      'Microwave',
      Icons.microwave_rounded,
      Color(0xFFE65100),
      'https://images.unsplash.com/photo-1574269909862-7e1d70bb8078?w=500&auto=format&fit=crop&q=60',
      'Kitchen Appliances',
    ),
    _ApplianceItem(
      'Chimney',
      Icons.outdoor_grill_rounded,
      Color(0xFFE65100),
      'https://images.unsplash.com/photo-1505691938895-1758d7feb511?w=500&auto=format&fit=crop&q=60',
      'Kitchen Appliances',
    ),

    // --- Laundry Appliances ---
    _ApplianceItem(
      'Washing Machine',
      Icons.local_laundry_service_rounded,
      Color(0xFF00897B),
      'https://images.unsplash.com/photo-1626806787461-102c1bfaaea1?w=500&auto=format&fit=crop&q=60',
      'Laundry Appliances',
    ),
    _ApplianceItem(
      'Clothes Dryer',
      Icons.dry_cleaning_rounded,
      Color(0xFF00897B),
      'https://images.unsplash.com/photo-1545173168-9f1947eebd01?w=500&auto=format&fit=crop&q=60',
      'Laundry Appliances',
    ),
    _ApplianceItem(
      'Steam Iron',
      Icons.iron_rounded,
      Color(0xFF00897B),
      'https://images.unsplash.com/photo-1479064555552-3ef4979f8908?w=500&auto=format&fit=crop&q=60',
      'Laundry Appliances',
    ),
    _ApplianceItem(
      'Garment Steamer',
      Icons.iron_rounded,
      Color(0xFF00897B),
      'https://images.unsplash.com/photo-1524805444758-089113d48a6d?w=500&auto=format&fit=crop&q=60',
      'Laundry Appliances',
    ),

    // --- Entertainment & Electronics ---
    _ApplianceItem(
      'Television',
      Icons.tv_rounded,
      Color(0xFF0277BD),
      'https://images.unsplash.com/photo-1593305841991-05c297ba4575?w=500&auto=format&fit=crop&q=60',
      'Entertainment & Electronics',
    ),
    _ApplianceItem(
      'Home Theater',
      Icons.home_max_rounded,
      Color(0xFF0277BD),
      'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=500&auto=format&fit=crop&q=60',
      'Entertainment & Electronics',
    ),
    _ApplianceItem(
      'Sound Bar',
      Icons.volume_up_rounded,
      Color(0xFF0277BD),
      'https://images.unsplash.com/photo-1545454675-3531b543be5d?w=500&auto=format&fit=crop&q=60',
      'Entertainment & Electronics',
    ),
    _ApplianceItem(
      'Speaker Systems',
      Icons.speaker_rounded,
      Color(0xFF0277BD),
      'https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?w=500&auto=format&fit=crop&q=60',
      'Entertainment & Electronics',
    ),
    _ApplianceItem(
      'Set-Top Box',
      Icons.settings_input_hdmi_rounded,
      Color(0xFF0277BD),
      'https://images.unsplash.com/photo-1585130401366-fe05a8d813c4?w=500&auto=format&fit=crop&q=60',
      'Entertainment & Electronics',
    ),
    _ApplianceItem(
      'Gaming Console (PS5/Xbox)',
      Icons.sports_esports_rounded,
      Color(0xFF0277BD),
      'https://images.unsplash.com/photo-1606144042614-b2417e99c4e3?w=500&auto=format&fit=crop&q=60',
      'Entertainment & Electronics',
    ),
    _ApplianceItem(
      'Projector',
      Icons.videocam_rounded,
      Color(0xFF0277BD),
      'https://images.unsplash.com/photo-1535016120720-40c646be5580?w=500&auto=format&fit=crop&q=60',
      'Entertainment & Electronics',
    ),

    // --- IT & Smart Devices ---
    _ApplianceItem(
      'Laptop',
      Icons.laptop_chromebook_rounded,
      Color(0xFF6A1B9A),
      'https://images.unsplash.com/photo-1496181130204-755241524eab?w=500&auto=format&fit=crop&q=60',
      'IT & Smart Devices',
    ),
    _ApplianceItem(
      'Desktop PC',
      Icons.desktop_windows_rounded,
      Color(0xFF6A1B9A),
      'https://images.unsplash.com/photo-1587831990711-23ca6441447b?w=500&auto=format&fit=crop&q=60',
      'IT & Smart Devices',
    ),
    _ApplianceItem(
      'Printer',
      Icons.print_rounded,
      Color(0xFF6A1B9A),
      'https://images.unsplash.com/photo-1612815154858-60aa4c59eaa6?w=500&auto=format&fit=crop&q=60',
      'IT & Smart Devices',
    ),
    _ApplianceItem(
      'WiFi Router',
      Icons.router_rounded,
      Color(0xFF6A1B9A),
      'https://images.unsplash.com/photo-1595844730900-85c629380f6c?w=500&auto=format&fit=crop&q=60',
      'IT & Smart Devices',
    ),
    _ApplianceItem(
      'CCTV Camera',
      Icons.security_rounded,
      Color(0xFF6A1B9A),
      'https://images.unsplash.com/photo-1557597774-9d273605dfa9?w=500&auto=format&fit=crop&q=60',
      'IT & Smart Devices',
    ),
    _ApplianceItem(
      'Smart Door Lock',
      Icons.lock_rounded,
      Color(0xFF6A1B9A),
      'https://images.unsplash.com/photo-1558002038-1055907df827?w=500&auto=format&fit=crop&q=60',
      'IT & Smart Devices',
    ),
    _ApplianceItem(
      'Smart Home Devices',
      Icons.home_rounded,
      Color(0xFF6A1B9A),
      'https://images.unsplash.com/photo-1558002038-1055907df827?w=500&auto=format&fit=crop&q=60',
      'IT & Smart Devices',
    ),

    // --- Electrical Services ---
    _ApplianceItem(
      'Fan Repair',
      Icons.mode_fan_off_rounded,
      Color(0xFF546E7A),
      'https://images.unsplash.com/photo-1618944847023-38aa001235f0?w=500&auto=format&fit=crop&q=60',
      'Electrical Services',
    ),
    _ApplianceItem(
      'Exhaust Fan',
      Icons.mode_fan_off_rounded,
      Color(0xFF546E7A),
      'https://images.unsplash.com/photo-1618944847023-38aa001235f0?w=500&auto=format&fit=crop&q=60',
      'Electrical Services',
    ),
    _ApplianceItem(
      'Switchboard Repair',
      Icons.electrical_services_rounded,
      Color(0xFF546E7A),
      'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=500&auto=format&fit=crop&q=60',
      'Electrical Services',
    ),
    _ApplianceItem(
      'Wiring Work',
      Icons.electrical_services_rounded,
      Color(0xFF546E7A),
      'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=500&auto=format&fit=crop&q=60',
      'Electrical Services',
    ),
    _ApplianceItem(
      'MCB/Fuse Replacement',
      Icons.electric_bolt_rounded,
      Color(0xFF546E7A),
      'https://images.unsplash.com/photo-1621905252507-b354bc25edac?w=500&auto=format&fit=crop&q=60',
      'Electrical Services',
    ),
    _ApplianceItem(
      'Door Bell Installation',
      Icons.notifications_rounded,
      Color(0xFF546E7A),
      'https://images.unsplash.com/photo-1558002038-1055907df827?w=500&auto=format&fit=crop&q=60',
      'Electrical Services',
    ),
    _ApplianceItem(
      'Inverter Repair',
      Icons.battery_charging_full_rounded,
      Color(0xFF546E7A),
      'https://images.unsplash.com/photo-1621905252507-b354bc25edac?w=500&auto=format&fit=crop&q=60',
      'Electrical Services',
    ),
    _ApplianceItem(
      'UPS Repair',
      Icons.battery_charging_full_rounded,
      Color(0xFF546E7A),
      'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=500&auto=format&fit=crop&q=60',
      'Electrical Services',
    ),
    _ApplianceItem(
      'Stabilizer Repair',
      Icons.bolt_rounded,
      Color(0xFF546E7A),
      'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=500&auto=format&fit=crop&q=60',
      'Electrical Services',
    ),
    _ApplianceItem(
      'Generator Service',
      Icons.power_rounded,
      Color(0xFF546E7A),
      'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=500&auto=format&fit=crop&q=60',
      'Electrical Services',
    ),

    // --- Water & Heating ---
    _ApplianceItem(
      'Water Purifier',
      Icons.water_drop_rounded,
      Color(0xFF2E7D32),
      'https://images.unsplash.com/photo-1618579895756-65b827ac4f53?w=500&auto=format&fit=crop&q=60',
      'Water & Heating',
    ),
    _ApplianceItem(
      'Water Heater / Geyser',
      Icons.water_rounded,
      Color(0xFF2E7D32),
      'https://images.unsplash.com/photo-1584622781564-1d987f7333c1?w=500&auto=format&fit=crop&q=60',
      'Water & Heating',
    ),
    _ApplianceItem(
      'Solar Water Heater',
      Icons.solar_power_rounded,
      Color(0xFF2E7D32),
      'https://images.unsplash.com/photo-1509391366360-2e959784a276?w=500&auto=format&fit=crop&q=60',
      'Water & Heating',
    ),
    _ApplianceItem(
      'Water Pump',
      Icons.power_rounded,
      Color(0xFF2E7D32),
      'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=500&auto=format&fit=crop&q=60',
      'Water & Heating',
    ),
    _ApplianceItem(
      'Borewell Motor',
      Icons.power_rounded,
      Color(0xFF2E7D32),
      'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=500&auto=format&fit=crop&q=60',
      'Water & Heating',
    ),
  ];

  final _slots = [
    '9:00 AM – 11:00 AM',
    '11:00 AM – 1:00 PM',
    '2:00 PM – 4:00 PM',
    '4:00 PM – 6:00 PM'
  ];

  @override
  Widget build(BuildContext context) {
    final issues = _currentIssues;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: FixigoAppBar(
        title: 'Book a Service',
        showBack: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Step ${_step + 1} of 4',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          _StepProgress(step: _step),
          // Content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.15, 0),
                  end: Offset.zero,
                ).animate(anim),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: [
                _StepSelectAppliance(
                  key: const ValueKey(0),
                  appliances: _appliances,
                  selectedIndex: _selectedAppliance,
                  onSelect: (item) {
                    final idx = _appliances.indexOf(item);
                    setState(() {
                      _selectedAppliance = idx;
                      _selectedIssue = null;
                      _issueController.clear();
                    });
                  },
                ),
                _StepDescribeIssue(
                  key: ValueKey('issue-${_selectedAppliance ?? -1}'),
                  issues: issues,
                  selectedIssue: _selectedIssue,
                  controller: _issueController,
                  isOtherSelected: _isOtherIssueSelected,
                  onSelect: (i) => setState(() => _selectedIssue = i),
                  onDetailsChanged: () => setState(() {}),
                ),
                _StepSelectSlot(
                  key: const ValueKey(2),
                  slots: _slots,
                  selectedSlot: _selectedSlot,
                  selectedDate: _selectedDate,
                  onSelectSlot: (s) => setState(() => _selectedSlot = s),
                  onSelectDate: (d) => setState(() => _selectedDate = d),
                ),
                _StepConfirm(
                  key: const ValueKey(3),
                  appliance: _selectedAppliance != null
                      ? _appliances[_selectedAppliance!].name
                      : '',
                  issue: _selectedIssueText.isNotEmpty
                      ? _selectedIssueText
                      : (_selectedIssue != null &&
                              _selectedIssue! < issues.length
                          ? issues[_selectedIssue!]
                          : ''),
                  slot: _selectedSlot ?? '',
                  date: _selectedDate,
                  onSelectLocation: _chooseLocationOnMap,
                ),
              ][_step],
            ),
          ),
          // Bottom buttons
          _BottomNav(
            step: _step,
            canProceed: _canProceed(),
            isBooking: _isBooking,
            onBack: () => setState(() => _step--),
            onNext: () {
              if (_step < 3) {
                setState(() => _step++);
              } else {
                if (!_isBooking) {
                  _createBooking();
                }
              }
            },
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_step) {
      case 0:
        return _selectedAppliance != null;
      case 1:
        if (_selectedIssue == null) return false;
        if (_isOtherIssueSelected) {
          return _issueController.text.trim().isNotEmpty;
        }
        return true;
      case 2:
        return _selectedSlot != null;
      default:
        return true;
    }
  }

  void _showBookingSuccess(String bookingId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingSuccessSheet(bookingId: bookingId),
    ).then((result) {
      if (!mounted) return;
      if (result != 'home') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TrackRepairScreen(booking: {'id': bookingId}),
          ),
        );
      }
    });
  }
}

// ── Step Progress ─────────────────────────────────────────────────────────────
class _StepProgress extends StatelessWidget {
  final int step;
  const _StepProgress({required this.step});

  @override
  Widget build(BuildContext context) {
    final labels = ['Appliance', 'Issue', 'Schedule', 'Confirm'];
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      color: AppColors.surface,
      child: Row(
        children: List.generate(labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: Container(
                height: 2,
                color: i ~/ 2 < step ? AppColors.primary : AppColors.border,
              ),
            );
          }
          final idx = i ~/ 2;
          final done = idx < step;
          final active = idx == step;
          return Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: done
                      ? AppColors.primary
                      : active
                          ? AppColors.primarySurface
                          : AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                  border: active
                      ? Border.all(color: AppColors.primary, width: 2)
                      : null,
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 16)
                      : Text(
                          '${idx + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: active
                                ? AppColors.primary
                                : AppColors.textTertiary,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                labels[idx],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.primary : AppColors.textTertiary,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Step 1: Select Appliance ──────────────────────────────────────────────────
class _StepSelectAppliance extends StatefulWidget {
  final List<_ApplianceItem> appliances;
  final int? selectedIndex;
  final ValueChanged<_ApplianceItem> onSelect;

  const _StepSelectAppliance({
    super.key,
    required this.appliances,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  State<_StepSelectAppliance> createState() => _StepSelectApplianceState();
}

class _StepSelectApplianceState extends State<_StepSelectAppliance> {
  String _selectedCategory = 'All';

  final _categories = const [
    'All',
    'Kitchen',
    'Cooling',
    'Laundry',
    'Entertainment',
    'IT & Smart',
    'Electrical',
    'Water & Heating',
  ];

  @override
  Widget build(BuildContext context) {
    // Filter appliances based on selected category pill
    final filtered = widget.appliances.where((item) {
      if (_selectedCategory == 'All') return true;
      final filterKeyword = _selectedCategory.split(' ')[0].toLowerCase();
      return item.category.toLowerCase().contains(filterKeyword);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Text('Which appliance needs repair?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text('Select category and appliance to continue',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ),
        // Horizontal category pills selector
        SizedBox(
          height: 38,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final cat = _categories[index];
              final isSelected = _selectedCategory == cat;
              return ChoiceChip(
                label: Text(cat),
                selected: isSelected,
                onSelected: (val) {
                  if (val) {
                    setState(() => _selectedCategory = cat);
                  }
                },
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surface,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                showCheckmark: false,
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.25,
            ),
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final item = filtered[i];
              final isSelected = widget.selectedIndex != null &&
                  widget.appliances[widget.selectedIndex!] == item;
              return GestureDetector(
                onTap: () => widget.onSelect(item),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? item.color : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      children: [
                        Expanded(
                          child: CachedNetworkImage(
                            imageUrl: item.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (ctx, url) => Container(
                              color: item.color.withOpacity(0.1),
                              child: Center(
                                child: Icon(item.icon,
                                    color: isSelected ? item.color : AppColors.textSecondary,
                                    size: 28),
                              ),
                            ),
                            errorWidget: (ctx, url, err) => Container(
                              color: item.color.withOpacity(0.1),
                              child: Center(
                                child: Icon(item.icon,
                                    color: isSelected ? item.color : AppColors.textSecondary,
                                    size: 28),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          width: double.infinity,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? item.color.withOpacity(0.08) : Colors.transparent,
                          ),
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? item.color : AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ApplianceItem {
  final String name;
  final IconData icon;
  final Color color;
  final String imageUrl;
  final String category;
  const _ApplianceItem(this.name, this.icon, this.color, this.imageUrl, this.category);
}

/// Appliance-specific service issues shown in booking Step 2.
class ApplianceIssues {
  static const String otherLabel = 'Other Issue';

  static const List<String> tv = [
    'Display problem',
    'No picture',
    'No sound',
    'Screen cracked',
    'HDMI issue',
    'Remote not working',
    'Power issue',
  ];

  static const List<String> refrigerator = [
    'Not cooling',
    'Water leakage',
    'Ice buildup',
    'Compressor issue',
    'Door not closing',
    'Unusual noise',
  ];

  static const List<String> washingMachine = [
    'Not spinning',
    'Water not draining',
    'Water leakage',
    'Drum not rotating',
    'Door lock issue',
    'Excessive vibration',
  ];

  static const List<String> airConditioner = [
    'Not cooling',
    'Gas leakage',
    'Water leakage',
    'Unusual noise',
    'Remote issue',
    'Fan not working',
  ];

  static const List<String> microwave = [
    'Not heating',
    'Sparking inside',
    'Door issue',
    'Turntable not rotating',
    'Display issue',
  ];

  static const List<String> fan = [
    'Not rotating',
    'Low speed',
    'Noise',
    'Capacitor issue',
    'Regulator issue',
  ];

  static const List<String> laptop = [
    'Not turning on',
    'Battery issue',
    'Screen issue',
    'Keyboard issue',
    'Charging issue',
    'Overheating',
  ];

  static const List<String> mobile = [
    'Display issue',
    'Battery draining',
    'Charging issue',
    'Camera issue',
    'Speaker issue',
    'Network issue',
  ];

  static const List<String> generic = [
    'Not turning on',
    'Making unusual noise',
    'Not cooling/heating',
    'Water leakage',
    'Display problem',
    'Power issue',
    otherLabel,
  ];

  static List<String> forAppliance(String applianceName) {
    final n = applianceName.toLowerCase().trim();
    List<String> base;

    if (n.contains('television') ||
        n == 'tv' ||
        n.startsWith('tv ') ||
        n.contains('led tv') ||
        n.contains('smart tv')) {
      base = tv;
    } else if (n.contains('refrigerator') ||
        n.contains('fridge') ||
        n.contains('deep freezer')) {
      base = refrigerator;
    } else if (n.contains('washing') || n.contains('washer')) {
      base = washingMachine;
    } else if (n.contains('air conditioner') ||
        n == 'ac' ||
        n.startsWith('ac ') ||
        n.contains(' split ac') ||
        n.contains('window ac')) {
      base = airConditioner;
    } else if (n.contains('microwave') || n.contains('otg')) {
      base = microwave;
    } else if (n.contains('fan')) {
      base = fan;
    } else if (n.contains('laptop') || n.contains('notebook')) {
      base = laptop;
    } else if (n.contains('mobile') ||
        n.contains('phone') ||
        n.contains('smartphone')) {
      base = mobile;
    } else if (n.contains('air cooler') || n.contains('water cooler')) {
      base = airConditioner;
    } else if (n.contains('desktop') || n.contains(' pc')) {
      base = laptop;
    } else if (n.contains('home theater') ||
        n.contains('sound bar') ||
        n.contains('speaker') ||
        n.contains('projector') ||
        n.contains('set-top') ||
        n.contains('gaming console')) {
      base = tv;
    } else {
      return List<String>.from(generic);
    }

    return [...base, otherLabel];
  }
}

// ── Step 2: Describe Issue ────────────────────────────────────────────────────
class _StepDescribeIssue extends StatelessWidget {
  final List<String> issues;
  final int? selectedIssue;
  final TextEditingController controller;
  final ValueChanged<int> onSelect;
  final bool isOtherSelected;
  final VoidCallback? onDetailsChanged;

  const _StepDescribeIssue({
    super.key,
    required this.issues,
    required this.selectedIssue,
    required this.controller,
    required this.onSelect,
    this.isOtherSelected = false,
    this.onDetailsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What\'s the issue?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Select the issue or describe it below',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          ...List.generate(issues.length, (i) {
            final sel = selectedIssue == i;
            return GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primarySurface : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: sel ? AppColors.primary : AppColors.border,
                      width: sel ? 2 : 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      sel
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: sel ? AppColors.primary : AppColors.textTertiary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        issues[i],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                          color:
                              sel ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: 3,
            onChanged: (_) => onDetailsChanged?.call(),
            decoration: InputDecoration(
              hintText: isOtherSelected
                  ? 'Describe your issue in detail *'
                  : 'Describe your issue in detail (optional)',
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 12, top: 12),
                child: Icon(Icons.edit_note_rounded,
                    color: AppColors.textTertiary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 3: Select Slot ───────────────────────────────────────────────────────
class _StepSelectSlot extends StatefulWidget {
  final List<String> slots;
  final String? selectedSlot;
  final DateTime selectedDate;
  final ValueChanged<String> onSelectSlot;
  final ValueChanged<DateTime> onSelectDate;

  const _StepSelectSlot({
    super.key,
    required this.slots,
    required this.selectedSlot,
    required this.selectedDate,
    required this.onSelectSlot,
    required this.onSelectDate,
  });

  @override
  State<_StepSelectSlot> createState() => _StepSelectSlotState();
}

class _StepSelectSlotState extends State<_StepSelectSlot> {
  late DateTime _focusedMonth;

  final List<String> _months = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  final List<String> _weekdays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month, 1);
  }

  int _daysInMonth(DateTime date) {
    var firstDayOfNextMonth = (date.month < 12)
        ? DateTime(date.year, date.month + 1, 1)
        : DateTime(date.year + 1, 1, 1);
    return firstDayOfNextMonth.subtract(const Duration(days: 1)).day;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday; // 1 = Mon, ..., 7 = Sun
    final emptyCells = firstWeekday - 1;
    final totalDays = _daysInMonth(_focusedMonth);
    final totalCells = emptyCells + totalDays;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'When should we visit?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Select a date and time slot',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          
          // Calendar Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Month Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_months[_focusedMonth.month]} ${_focusedMonth.year}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded),
                          onPressed: _focusedMonth.year > today.year || (_focusedMonth.year == today.year && _focusedMonth.month > today.month)
                              ? () {
                                  setState(() {
                                    int newMonth = _focusedMonth.month - 1;
                                    int newYear = _focusedMonth.year;
                                    if (newMonth == 0) {
                                      newMonth = 12;
                                      newYear--;
                                    }
                                    _focusedMonth = DateTime(newYear, newMonth, 1);
                                  });
                                }
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded),
                          onPressed: () {
                            setState(() {
                              int newMonth = _focusedMonth.month + 1;
                              int newYear = _focusedMonth.year;
                              if (newMonth == 13) {
                                newMonth = 1;
                                newYear++;
                              }
                              _focusedMonth = DateTime(newYear, newMonth, 1);
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 12),
                
                // Weekday Headers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _weekdays.map((day) {
                    return SizedBox(
                      width: 36,
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                
                // Days Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 1,
                  ),
                  itemCount: totalCells,
                  itemBuilder: (context, index) {
                    if (index < emptyCells) {
                      return const SizedBox();
                    }
                    
                    final day = index - emptyCells + 1;
                    final cellDate = DateTime(_focusedMonth.year, _focusedMonth.month, day);
                    final isPast = cellDate.isBefore(todayStart);
                    
                    final isSelected = widget.selectedDate.year == cellDate.year &&
                        widget.selectedDate.month == cellDate.month &&
                        widget.selectedDate.day == cellDate.day;
                        
                    final isToday = todayStart.year == cellDate.year &&
                        todayStart.month == cellDate.month &&
                        todayStart.day == cellDate.day;

                    return GestureDetector(
                      onTap: isPast
                          ? null
                          : () => widget.onSelectDate(cellDate),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : isToday
                                  ? AppColors.primarySurface
                                  : Colors.transparent,
                          shape: BoxShape.circle,
                          border: isToday && !isSelected
                              ? Border.all(color: AppColors.primary, width: 1)
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected || isToday
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isPast
                                ? AppColors.textTertiary.withOpacity(0.5)
                                : isSelected
                                    ? Colors.white
                                    : isToday
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          const Text(
            'Available Slots',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          
          // Slots list
          ...widget.slots.asMap().entries.map((e) {
            final sel = widget.selectedSlot == e.value;
            return GestureDetector(
              onTap: () => widget.onSelectSlot(e.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primarySurface : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sel ? AppColors.primary : AppColors.border,
                    width: sel ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: sel ? AppColors.primary : AppColors.textTertiary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                          color: sel ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (e.key == 0)
                      StatusBadge.success('Popular')
                    else if (e.key == 3)
                      StatusBadge.warning('Few slots'),
                    if (sel)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Step 4: Confirm ───────────────────────────────────────────────────────────
class _StepConfirm extends StatelessWidget {
  final String appliance, issue, slot;
  final DateTime date;
  final VoidCallback onSelectLocation;

  const _StepConfirm({
    super.key,
    required this.appliance,
    required this.issue,
    required this.slot,
    required this.date,
    required this.onSelectLocation,
  });

  @override
  Widget build(BuildContext context) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final formattedDate = '${date.day} ${months[date.month]} ${date.year}';

    final estimate = BookingPriceEstimator.getEstimate(appliance, issue);
    final inspection = estimate['inspection']!;
    final repairMin = estimate['repairMin']!;
    final repairMax = estimate['repairMax']!;
    final totalMin = estimate['totalMin']!;
    final totalMax = estimate['totalMax']!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Booking Summary',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                InfoRow(
                    icon: Icons.category_rounded,
                    label: 'Appliance',
                    value: appliance),
                const Divider(),
                InfoRow(
                    icon: Icons.report_problem_rounded,
                    label: 'Issue',
                    value: issue),
                const Divider(),
                InfoRow(
                    icon: Icons.calendar_month_rounded,
                    label: 'Date',
                    value: formattedDate),
                const Divider(),
                InfoRow(
                    icon: Icons.schedule_rounded, label: 'Slot', value: slot),
                const Divider(),
                const SizedBox(height: 6),
                InkWell(
                  onTap: onSelectLocation,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Service Address (Tap to change)',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(
                                Session.address != null && Session.address!.isNotEmpty
                                    ? Session.address!
                                    : 'Tap to select address on Google Maps',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_rounded,
                    color: AppColors.success, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '90-day service warranty included with all repairs',
                    style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Price Estimate',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 12),
                _PriceRow('Inspection charge', '₹$inspection', isGreen: false),
                _PriceRow('Repair charge (est.)', '₹$repairMin – ₹$repairMax',
                    isGreen: false),
                _PriceRow('Parts (if required)', 'At actuals', isGreen: false),
                const Divider(height: 20),
                _PriceRow('Total Estimate', '₹$totalMin – ₹$totalMax', isGreen: true),
                const Divider(height: 20),
                Row(
                  children: [
                    const Icon(Icons.payment_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Booking Fee (Payable via Razorpay now)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ),
                    const Text(
                      '₹50',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  '* Note: ₹50 will be deducted from your final bill after repair completion.',
                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _PriceRow(String label, String value, {required bool isGreen}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color:
                      isGreen ? AppColors.textPrimary : AppColors.textSecondary,
                  fontWeight: isGreen ? FontWeight.w700 : FontWeight.w400)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  color: isGreen ? AppColors.success : AppColors.textPrimary,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ── Bottom Nav ────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int step;
  final bool canProceed;
  final bool isBooking;
  final VoidCallback onBack, onNext;

  const _BottomNav({
    required this.step,
    required this.canProceed,
    this.isBooking = false,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (step > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: isBooking ? null : onBack,
                child: const Text('Back'),
              ),
            ),
          if (step > 0) const SizedBox(width: 12),
          Expanded(
            flex: step == 0 ? 1 : 2,
            child: GradientButton(
              text: isBooking
                  ? 'Booking...'
                  : step == 3
                      ? 'Confirm Booking'
                      : 'Continue',
              onTap: canProceed && !isBooking ? onNext : () {},
              gradient: canProceed && !isBooking ? AppColors.primaryGradient : null,
              icon: isBooking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : step == 3
                      ? const Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 18)
                      : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Booking Success Sheet ─────────────────────────────────────────────────────
class _BookingSuccessSheet extends StatelessWidget {
  final String bookingId;

  const _BookingSuccessSheet({required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.successLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: AppColors.success, size: 44),
          ),
          const SizedBox(height: 20),
          const Text('Booking Confirmed!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(
            'Your technician will arrive at the scheduled time. You\'ll receive a call 30 mins before.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('Booking ID: FIX-$bookingId',
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 24),
          GradientButton(
            text: 'Track Your Technician',
            onTap: () => Navigator.pop(context, 'track'),
            icon: const Icon(Icons.location_on_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context, 'home'),
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }
}

// ── Booking Price Estimator ──────────────────────────────────────────────────
class BookingPriceEstimator {
  static Map<String, int> getEstimate(String appliance, String issue) {
    final String appLower = appliance.toLowerCase();
    final String issueLower = issue.toLowerCase();

    int baseMin = 150;
    int baseMax = 300;

    final isPremium = appLower.contains('ac') ||
        appLower.contains('conditioner') ||
        appLower.contains('refrigerator') ||
        appLower.contains('freezer') ||
        appLower.contains('laptop') ||
        appLower.contains('pc') ||
        appLower.contains('desktop') ||
        appLower.contains('television') ||
        appLower.contains('tv') ||
        appLower.contains('solar') ||
        appLower.contains('pump') ||
        appLower.contains('borewell');

    final isMedium = appLower.contains('washing') ||
        appLower.contains('dryer') ||
        appLower.contains('laundry') ||
        appLower.contains('microwave') ||
        appLower.contains('oven') ||
        appLower.contains('dishwasher') ||
        appLower.contains('purifier') ||
        appLower.contains('geyser') ||
        appLower.contains('heater') ||
        appLower.contains('cctv') ||
        appLower.contains('router') ||
        appLower.contains('lock') ||
        appLower.contains('generator') ||
        appLower.contains('inverter');

    if (isPremium) {
      baseMin = 400;
      baseMax = 800;
    } else if (isMedium) {
      baseMin = 250;
      baseMax = 500;
    }

    double factorMin = 1.0;
    double factorMax = 1.0;

    if (issueLower.contains('not turning') || issueLower.contains('display')) {
      factorMin = 1.5;
      factorMax = 2.0;
    } else if (issueLower.contains('not cooling') ||
        issueLower.contains('not heating') ||
        issueLower.contains('leakage') ||
        issueLower.contains('noise')) {
      factorMin = 1.2;
      factorMax = 1.5;
    } else if (issueLower.contains('remote') || issueLower.contains('other')) {
      factorMin = 0.8;
      factorMax = 1.0;
    }

    final int minCharge = (baseMin * factorMin).round();
    final int maxCharge = (baseMax * factorMax).round();

    return {
      'inspection': 99,
      'repairMin': minCharge,
      'repairMax': maxCharge,
      'totalMin': minCharge + 99,
      'totalMax': maxCharge + 99,
    };
  }
}

// ── Razorpay Secure Checkout Sheet ──────────────────────────────────────────
class RazorpayCheckoutSheet extends StatefulWidget {
  final double amount;
  final String email;
  final String phone;

  const RazorpayCheckoutSheet({
    super.key,
    required this.amount,
    required this.email,
    required this.phone,
  });

  @override
  State<RazorpayCheckoutSheet> createState() => _RazorpayCheckoutSheetState();
}

class _RazorpayCheckoutSheetState extends State<RazorpayCheckoutSheet> {
  String _viewState = 'options'; // 'options', 'upi', 'card', 'processing', 'success'
  String _selectedUpiApp = '';
  final _upiIdController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();
  final _cardHolderController = TextEditingController();
  String _processingMessage = '';

  @override
  void dispose() {
    _upiIdController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  void _processPayment() async {
    setState(() {
      _viewState = 'processing';
      _processingMessage = 'Connecting to secure servers...';
    });

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    setState(() {
      _processingMessage = 'Authorizing booking fee payment...';
    });

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    setState(() {
      _viewState = 'success';
    });

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    // Generate simulated payment credentials
    final rng = javaRandomString(12);
    Navigator.pop(context, {
      'paymentId': 'pay_$rng',
      'orderId': 'order_${javaRandomString(10)}',
    });
  }

  String javaRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = math.Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(rand.nextInt(chars.length))));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_viewState == 'processing') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF528FF0),
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            Text(
              _processingMessage,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please do not close or press back button',
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
          ],
        ),
      );
    }

    if (_viewState == 'success') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 70),
            SizedBox(height: 20),
            Text(
              'Payment Successful!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
            ),
            SizedBox(height: 8),
            Text(
              'Booking registered with Razorpay secured payment',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Razorpay Secured Brand Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF528FF0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.security_rounded, color: Color(0xFF528FF0), size: 16),
                ),
                const SizedBox(width: 8),
                const Text(
                  'RAZORPAY SECURE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF528FF0),
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close_rounded, color: AppColors.textTertiary, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 8),
        
        // Amount Details
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fixigo Appliance Repairs',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Deposit Fee: FIX-EST50',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            Text(
              '₹${widget.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_viewState == 'options') ...[
          const Text(
            'SELECT PAYMENT OPTION',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 10),
          _PaymentOptionTile(
            icon: Icons.qr_code_rounded,
            title: 'UPI - Google Pay / PhonePe / Paytm',
            subtitle: 'Instant transfer using your UPI Apps',
            onTap: () => setState(() => _viewState = 'upi'),
          ),
          _PaymentOptionTile(
            icon: Icons.credit_card_rounded,
            title: 'Card - Visa, MasterCard, RuPay',
            subtitle: 'Pay using Credit/Debit cards',
            onTap: () => setState(() => _viewState = 'card'),
          ),
          _PaymentOptionTile(
            icon: Icons.account_balance_rounded,
            title: 'Netbanking',
            subtitle: 'All Indian major banks available',
            onTap: _processPayment, // direct simulation shortcut for simplicity
          ),
        ] else if (_viewState == 'upi') ...[
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                onPressed: () => setState(() => _viewState = 'options'),
              ),
              const Text(
                'Pay via UPI',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _UpiAppButton('GPay', Icons.account_balance_wallet_rounded, _selectedUpiApp == 'gpay', () {
                setState(() => _selectedUpiApp = 'gpay');
                _upiIdController.text = '${widget.phone}@okaxis';
              }),
              _UpiAppButton('PhonePe', Icons.payment_rounded, _selectedUpiApp == 'phonepe', () {
                setState(() => _selectedUpiApp = 'phonepe');
                _upiIdController.text = '${widget.phone}@ybl';
              }),
              _UpiAppButton('Paytm', Icons.qr_code_scanner_rounded, _selectedUpiApp == 'paytm', () {
                setState(() => _selectedUpiApp = 'paytm');
                _upiIdController.text = '${widget.phone}@paytm';
              }),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _upiIdController,
            decoration: const InputDecoration(
              labelText: 'UPI ID / VPA',
              hintText: 'username@upi',
              prefixIcon: Icon(Icons.alternate_email_rounded, size: 16),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _upiIdController.text.isNotEmpty ? _processPayment : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF528FF0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Pay ₹${widget.amount.toStringAsFixed(2)} Securely'),
            ),
          ),
        ] else if (_viewState == 'card') ...[
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                onPressed: () => setState(() => _viewState = 'options'),
              ),
              const Text(
                'Pay via Card',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _cardNumberController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Card Number',
              hintText: '4111 2222 3333 4444',
              prefixIcon: Icon(Icons.credit_card_rounded, size: 16),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cardExpiryController,
                  decoration: const InputDecoration(
                    labelText: 'Expiry Date',
                    hintText: 'MM/YY',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _cardCvvController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'CVV / CVC',
                    hintText: '123',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cardHolderController,
            decoration: const InputDecoration(
              labelText: 'Cardholder Name',
              hintText: 'John Doe',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _cardNumberController.text.isNotEmpty ? _processPayment : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF528FF0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Pay ₹${widget.amount.toStringAsFixed(2)} Securely'),
            ),
          ),
        ],
        const SizedBox(height: 12),
        const Center(
          child: Text(
            '🔒 PCI-DSS Compliant • Secure 256-bit SSL connection',
            style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
          ),
        ),
      ],
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PaymentOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF528FF0)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

class _UpiAppButton extends StatelessWidget {
  final String name;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _UpiAppButton(this.name, this.icon, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF528FF0).withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? const Color(0xFF528FF0) : Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? const Color(0xFF528FF0) : Colors.grey, size: 24),
            const SizedBox(height: 4),
            Text(name, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
// Random helper replaced with standard math.Random

// ── Payment Verification Sheet ──────────────────────────────────────────────
class PaymentVerificationSheet extends StatefulWidget {
  final dynamic bookingId;

  const PaymentVerificationSheet({
    super.key,
    required this.bookingId,
  });

  @override
  State<PaymentVerificationSheet> createState() => _PaymentVerificationSheetState();
}

class _PaymentVerificationSheetState extends State<PaymentVerificationSheet> {
  bool _isLoading = false;
  String _statusMessage = 'Waiting for payment confirmation...';
  bool _isSuccess = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Poll every 3 seconds to check payment status automatically
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkPaymentStatus(auto: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkPaymentStatus({bool auto = false}) async {
    if (_isLoading && !auto) return;
    if (mounted && !auto) {
      setState(() => _isLoading = true);
    }

    try {
      final resp = await Api.get('/bookings/details/${widget.bookingId}');
      if (resp['status'] == 200) {
        final booking = resp['data'];
        final paymentStatus = booking['payment_status'];
        if (paymentStatus == 'paid') {
          _timer?.cancel();
          if (mounted) {
            setState(() {
              _isSuccess = true;
              _isLoading = false;
              _statusMessage = 'Payment Verified Successfully!';
            });
          }
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.pop(context, true);
          }
        } else {
          if (mounted && !auto) {
            setState(() {
              _isLoading = false;
              _statusMessage = 'Payment not received yet. Please try again.';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment not completed or updated yet.')),
            );
          }
        }
      } else {
        if (mounted && !auto) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted && !auto) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cancelBooking() async {
    try {
      await Api.put('/bookings/${widget.bookingId}/cancel', {'reason': 'Payment flow cancelled by user.'});
    } catch (e) {
      // ignore
    }
    if (mounted) {
      Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.security_rounded, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'SECURE CHECKOUT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              if (!_isSuccess)
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textTertiary),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Cancel booking?'),
                        content: const Text('Are you sure you want to cancel the booking? If you have paid, click Check Status instead.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Go Back'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _cancelBooking();
                            },
                            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 20),
          if (_isSuccess) ...[
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 72),
            const SizedBox(height: 20),
            Text(
              _statusMessage,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your booking is confirmed. Assigning technician...',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            const SizedBox(
              height: 50,
              width: 50,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _statusMessage,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'We have opened Razorpay Checkout in your web browser. Please pay the ₹50.00 booking fee to complete your booking.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _cancelBooking,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _checkPaymentStatus(auto: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('I Have Paid'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            '🔒 Secure payment processed by Razorpay',
            style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
