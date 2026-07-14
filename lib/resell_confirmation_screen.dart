import 'dart:io';

import 'package:flutter/material.dart';

import 'api.dart';
import 'app_theme.dart';
import 'common_widgets.dart';
import 'resell_schedule_screen.dart';
import 'session.dart';

class ResellConfirmationData {
  final String applianceCategory;
  final String brand;
  final String model;
  final int yearOfPurchase;
  final String originalPrice;
  final String condition;
  final String workingStatus;
  final File? photo;
  final String estimatedValueRange;
  final int estimatedMidValue;
  final String pickupAddress;
  final bool hasBill;
  final bool hasBox;
  final bool hasAccessories;

  const ResellConfirmationData({
    required this.applianceCategory,
    required this.brand,
    required this.model,
    required this.yearOfPurchase,
    required this.originalPrice,
    required this.condition,
    required this.workingStatus,
    required this.photo,
    required this.estimatedValueRange,
    required this.estimatedMidValue,
    required this.pickupAddress,
    required this.hasBill,
    required this.hasBox,
    required this.hasAccessories,
  });
}

class ResellConfirmationScreen extends StatefulWidget {
  final ResellConfirmationData data;

  const ResellConfirmationScreen({super.key, required this.data});

  @override
  State<ResellConfirmationScreen> createState() =>
      _ResellConfirmationScreenState();
}

class _ResellConfirmationScreenState extends State<ResellConfirmationScreen> {
  late DateTime _pickupDate;
  TimeOfDay _pickupTime = const TimeOfDay(hour: 10, minute: 0);
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _pickupDate = DateTime.now().add(const Duration(days: 1));
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _pickupDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (selected != null) {
      setState(() => _pickupDate = selected);
    }
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _pickupTime,
    );
    if (selected != null) {
      setState(() => _pickupTime = selected);
    }
  }

  String get _formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final d = _pickupDate.day.toString().padLeft(2, '0');
    return '$d ${months[_pickupDate.month - 1]} ${_pickupDate.year}';
  }

  String get _formattedTime => _pickupTime.format(context);

  Future<void> _confirmPickup() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final brandLabel = widget.data.model.trim().isEmpty
          ? widget.data.brand
          : '${widget.data.brand} - ${widget.data.model}';
      final ageYears = DateTime.now().year - widget.data.yearOfPurchase;
      final pickupNote =
          'Preferred pickup: $_formattedDate at $_formattedTime';
      final addressWithPickup =
          '${widget.data.pickupAddress.trim()}\n$pickupNote';

      final fields = {
        'customerId': Session.userId?.toString() ?? '1',
        'appliance_type': widget.data.applianceCategory,
        'condition_description': widget.data.condition,
        'expected_price': widget.data.estimatedMidValue.toString(),
        'brand': brandLabel,
        'age_years': ageYears.toString(),
        'original_price': widget.data.originalPrice,
        'estimated_value': widget.data.estimatedMidValue.toString(),
        'working_status': widget.data.workingStatus,
        'cosmetic_condition': widget.data.condition,
        'has_bill': widget.data.hasBill.toString(),
        'has_box': widget.data.hasBox.toString(),
        'has_accessories': widget.data.hasAccessories.toString(),
        'address': addressWithPickup,
      };

      Map<String, dynamic> resp;
      if (widget.data.photo != null) {
        resp = await Api.multipartPost(
          '/resale',
          fields,
          'image',
          widget.data.photo!.path,
        );
      } else {
        resp = await Api.post('/resale', fields);
      }

      if (mounted) Navigator.pop(context); // loading

      if (resp['status'] == 201 || resp['status'] == 200) {
        final scheduledAt = DateTime(
          _pickupDate.year,
          _pickupDate.month,
          _pickupDate.day,
          _pickupTime.hour,
          _pickupTime.minute,
        );
        ResellScheduleRepository.addSchedule(
          appliance: widget.data.applianceCategory,
          scheduledDate: scheduledAt,
          address: addressWithPickup,
        );

        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Pickup Scheduled'),
            content: Text(
              'Your free pickup is confirmed for $_formattedDate at $_formattedTime.\n\n'
              'The request (with photos) has been sent to the admin portal.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (mounted) Navigator.pop(context, true);
      } else {
        final msg = resp['data']?['message'] ?? 'Failed to submit request';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $msg'), duration: const Duration(seconds: 5)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to schedule pickup. Please check your connection and try again. Error: $e',
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const FixigoAppBar(title: 'Confirm Pickup'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Review your details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Confirm everything looks correct before scheduling pickup.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            if (d.photo != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  d.photo!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
            ],
            _InfoCard(
              children: [
                _InfoRow('Appliance Category', d.applianceCategory),
                _InfoRow('Brand', d.brand),
                _InfoRow('Model', d.model.isEmpty ? '—' : d.model),
                _InfoRow('Year of Purchase', d.yearOfPurchase.toString()),
                _InfoRow('Original Price / Market Value', '₹${d.originalPrice}'),
                _InfoRow('Condition', d.condition),
                _InfoRow('Working Status', d.workingStatus),
                _InfoRow('Estimated Resale Value', d.estimatedValueRange),
                _InfoRow('Pickup Address', d.pickupAddress),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Preferred Pickup Date & Time',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_rounded, size: 18),
                    label: Text(_formattedDate, maxLines: 1),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time_rounded, size: 18),
                    label: Text(_formattedTime, maxLines: 1),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            GradientButton(
              text: _submitting ? 'Submitting...' : 'Confirm Pickup',
              onTap: _submitting ? null : _confirmPickup,
              gradient: const LinearGradient(
                colors: [Color(0xFF00897B), Color(0xFF26C6DA)],
              ),
              icon: const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _submitting ? null : () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Edit Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
