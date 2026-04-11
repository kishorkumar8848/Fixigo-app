import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'common_widgets.dart';

class TrackRepairScreen extends StatelessWidget {
  const TrackRepairScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: FixigoAppBar(
        title: 'Track Repair',
        showBack: Navigator.of(context).canPop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Tech card
            _TechnicianCard(),
            const SizedBox(height: 20),
            // Map placeholder
            _MapPlaceholder(),
            const SizedBox(height: 20),
            // Job info
            _JobInfoCard(),
            const SizedBox(height: 20),
            // Timeline
            _TimelineCard(),
            const SizedBox(height: 20),
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.call_rounded, size: 18),
                    label: const Text('Call'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.chat_rounded, size: 18),
                    label: const Text('Chat'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TechnicianCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
                child: const Center(
                  child: Text('RK',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                ),
              ),
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
                const Text('Rajesh Kumar',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
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
                    const Text('4.8 (127)',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    StatusBadge.success('Verified'),
                    const SizedBox(width: 6),
                    const Text('AC Specialist • 6 yrs exp',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
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

class _MapPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFFE8EFF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          // Grid lines for map feel
          CustomPaint(
            size: const Size(double.infinity, 200),
            painter: _MapGridPainter(),
          ),
          // ETA pill
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.electric_moped_rounded,
                          color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('ETA: 15 mins',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('1.2 km away',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ),
              ],
            ),
          ),
          // Location pin
          const Positioned(
            bottom: 24,
            right: 40,
            child: Icon(Icons.home_rounded, color: AppColors.primary, size: 28),
          ),
          const Positioned(
            top: 40,
            left: 60,
            child: Icon(Icons.engineering_rounded,
                color: AppColors.secondary, size: 28),
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD0DCE8)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _JobInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
              StatusBadge.warning('In Progress'),
            ],
          ),
          const SizedBox(height: 12),
          const InfoRow(
              icon: Icons.ac_unit_rounded,
              label: 'Service',
              value: 'AC Gas Refill & Service'),
          const Divider(),
          const InfoRow(
              icon: Icons.tag_rounded,
              label: 'Booking ID',
              value: 'FIX-2024-8841'),
          const Divider(),
          const InfoRow(
              icon: Icons.schedule_rounded,
              label: 'Scheduled',
              value: 'Today • 11:00 AM – 1:00 PM'),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final steps = [
      _TimeStep('Booking Confirmed', 'Your booking has been confirmed', true,
          true, Icons.check_circle_rounded),
      _TimeStep('Technician Assigned', 'Rajesh Kumar has been assigned', true,
          false, Icons.engineering_rounded),
      _TimeStep('On the Way', 'Technician is heading to your location', false,
          false, Icons.electric_moped_rounded),
      _TimeStep('Service Ongoing', 'Repair in progress', false, false,
          Icons.build_rounded),
      _TimeStep('Job Completed', 'Payment & invoice', false, false,
          Icons.task_alt_rounded),
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
            return _TimelineRow(step: s, isLast: isLast, isActive: i == 2);
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
