import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'common_widgets.dart';

class BookServiceScreen extends StatefulWidget {
  const BookServiceScreen({super.key});

  @override
  State<BookServiceScreen> createState() => _BookServiceScreenState();
}

class _BookServiceScreenState extends State<BookServiceScreen> {
  int _step = 0;
  int? _selectedAppliance;
  int? _selectedIssue;
  String? _selectedSlot;
  final _issueController = TextEditingController();

  final _appliances = const [
    _ApplianceItem('AC & Air Cooler', Icons.ac_unit_rounded, Color(0xFF1565C0)),
    _ApplianceItem('Washing Machine', Icons.local_laundry_service_rounded,
        Color(0xFF00897B)),
    _ApplianceItem('Refrigerator', Icons.kitchen_rounded, Color(0xFF6A1B9A)),
    _ApplianceItem('Microwave', Icons.microwave_rounded, Color(0xFFE65100)),
    _ApplianceItem('Television', Icons.tv_rounded, Color(0xFF0277BD)),
    _ApplianceItem(
        'Water Purifier', Icons.water_drop_rounded, Color(0xFF2E7D32)),
    _ApplianceItem('Geyser', Icons.water_rounded, Color(0xFFC62828)),
    _ApplianceItem('Chimney', Icons.outdoor_grill_rounded, Color(0xFF546E7A)),
  ];

  final _issues = [
    'Not turning on',
    'Making unusual noise',
    'Not cooling/heating',
    'Water leakage',
    'Remote control issue',
    'Display problem',
    'Other issue',
  ];

  final _slots = [
    '9:00 AM – 11:00 AM',
    '11:00 AM – 1:00 PM',
    '2:00 PM – 4:00 PM',
    '4:00 PM – 6:00 PM'
  ];

  @override
  Widget build(BuildContext context) {
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
                  selected: _selectedAppliance,
                  onSelect: (i) => setState(() => _selectedAppliance = i),
                ),
                _StepDescribeIssue(
                  key: const ValueKey(1),
                  issues: _issues,
                  selectedIssue: _selectedIssue,
                  controller: _issueController,
                  onSelect: (i) => setState(() => _selectedIssue = i),
                ),
                _StepSelectSlot(
                  key: const ValueKey(2),
                  slots: _slots,
                  selected: _selectedSlot,
                  onSelect: (s) => setState(() => _selectedSlot = s),
                ),
                _StepConfirm(
                  key: const ValueKey(3),
                  appliance: _selectedAppliance != null
                      ? _appliances[_selectedAppliance!].name
                      : '',
                  issue: _selectedIssue != null ? _issues[_selectedIssue!] : '',
                  slot: _selectedSlot ?? '',
                ),
              ][_step],
            ),
          ),
          // Bottom buttons
          _BottomNav(
            step: _step,
            canProceed: _canProceed(),
            onBack: () => setState(() => _step--),
            onNext: () {
              if (_step < 3) {
                setState(() => _step++);
              } else {
                _showBookingSuccess();
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
        return _selectedIssue != null;
      case 2:
        return _selectedSlot != null;
      default:
        return true;
    }
  }

  void _showBookingSuccess() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _BookingSuccessSheet(),
    );
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
class _StepSelectAppliance extends StatelessWidget {
  final List<_ApplianceItem> appliances;
  final int? selected;
  final ValueChanged<int> onSelect;

  const _StepSelectAppliance({
    super.key,
    required this.appliances,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Which appliance needs repair?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Select one appliance to continue',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            itemCount: appliances.length,
            itemBuilder: (_, i) {
              final item = appliances[i];
              final isSelected = selected == i;
              return GestureDetector(
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? item.color.withOpacity(0.1)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? item.color : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon,
                          color:
                              isSelected ? item.color : AppColors.textSecondary,
                          size: 36),
                      const SizedBox(height: 8),
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color:
                              isSelected ? item.color : AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ApplianceItem {
  final String name;
  final IconData icon;
  final Color color;
  const _ApplianceItem(this.name, this.icon, this.color);
}

// ── Step 2: Describe Issue ────────────────────────────────────────────────────
class _StepDescribeIssue extends StatelessWidget {
  final List<String> issues;
  final int? selectedIssue;
  final TextEditingController controller;
  final ValueChanged<int> onSelect;

  const _StepDescribeIssue({
    super.key,
    required this.issues,
    required this.selectedIssue,
    required this.controller,
    required this.onSelect,
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
                    Text(
                      issues[i],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        color: sel ? AppColors.primary : AppColors.textPrimary,
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
            decoration: const InputDecoration(
              hintText: 'Describe your issue in detail (optional)',
              prefixIcon: Padding(
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
class _StepSelectSlot extends StatelessWidget {
  final List<String> slots;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _StepSelectSlot({
    super.key,
    required this.slots,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(5, (i) => now.add(Duration(days: i)));
    final dayNames = ['Today', 'Tomorrow', 'Wed', 'Thu', 'Fri'];
    final months = [
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('When should we visit?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Select a date and time slot',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          // Date pills
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final sel = i == 0;
                return Container(
                  width: 58,
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: sel ? AppColors.primary : AppColors.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayNames[i],
                        style: TextStyle(
                            fontSize: 11,
                            color:
                                sel ? Colors.white70 : AppColors.textSecondary,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${days[i].day}',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: sel ? Colors.white : AppColors.textPrimary),
                      ),
                      Text(
                        months[days[i].month],
                        style: TextStyle(
                            fontSize: 10,
                            color:
                                sel ? Colors.white70 : AppColors.textTertiary),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const Text('Available Slots',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...slots.asMap().entries.map((e) {
            final sel = selected == e.value;
            return GestureDetector(
              onTap: () => onSelect(e.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primarySurface : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: sel ? AppColors.primary : AppColors.border,
                      width: sel ? 2 : 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        color: sel ? AppColors.primary : AppColors.textTertiary,
                        size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                          color:
                              sel ? AppColors.primary : AppColors.textPrimary,
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
                        child: Icon(Icons.check_circle_rounded,
                            color: AppColors.primary, size: 20),
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
  const _StepConfirm(
      {super.key,
      required this.appliance,
      required this.issue,
      required this.slot});

  @override
  Widget build(BuildContext context) {
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
                    icon: Icons.schedule_rounded, label: 'Slot', value: slot),
                const Divider(),
                InfoRow(
                    icon: Icons.location_on_rounded,
                    label: 'Address',
                    value: '42, 3rd Cross, Indiranagar, Bengaluru'),
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
                _PriceRow('Inspection charge', '₹99', isGreen: false),
                _PriceRow('Repair charge (est.)', '₹300 – ₹800',
                    isGreen: false),
                _PriceRow('Parts (if required)', 'At actuals', isGreen: false),
                const Divider(height: 20),
                _PriceRow('Total Estimate', '₹399 – ₹899', isGreen: true),
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
  final VoidCallback onBack, onNext;

  const _BottomNav({
    required this.step,
    required this.canProceed,
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
                onPressed: onBack,
                child: const Text('Back'),
              ),
            ),
          if (step > 0) const SizedBox(width: 12),
          Expanded(
            flex: step == 0 ? 1 : 2,
            child: GradientButton(
              text: step == 3 ? 'Confirm Booking' : 'Continue',
              onTap: canProceed ? onNext : () {},
              gradient: canProceed ? AppColors.primaryGradient : null,
              icon: step == 3
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
  const _BookingSuccessSheet();

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
            child: const Text('Booking ID: FIX-2024-8841',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 24),
          GradientButton(
            text: 'Track Your Technician',
            onTap: () => Navigator.pop(context),
            icon: const Icon(Icons.location_on_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }
}
