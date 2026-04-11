import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'common_widgets.dart';

class ActiveJobScreen extends StatefulWidget {
  const ActiveJobScreen({super.key});

  @override
  State<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends State<ActiveJobScreen> {
  final _checklist = [
    _CheckItem('Inspect appliance and identify issue', false),
    _CheckItem('Check power supply and connections', false),
    _CheckItem('Clean filters and components', true),
    _CheckItem('Refill gas / replace parts', false),
    _CheckItem('Test appliance functionality', false),
    _CheckItem('Collect customer sign-off', false),
  ];

  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job header card
            _JobHeaderCard(),
            const SizedBox(height: 16),
            // Customer info
            _CustomerCard(),
            const SizedBox(height: 16),
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
                        onChanged: (v) =>
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
            // Parts used
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
            // Complete button
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
              onPressed: () {},
              icon: const Icon(Icons.call_rounded, size: 18),
              label: const Text('Call Customer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompleteSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CompleteJobSheet(),
    );
  }
}

class _CheckItem {
  final String task;
  bool done;
  _CheckItem(this.task, this.done);
}

class _JobHeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
            child: const Icon(Icons.ac_unit_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AC Gas Refill & Service',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                const SizedBox(height: 4),
                Text('LG 1.5 Ton Split AC',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 12)),
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
                      child: const Text('FIX-2024-8841',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('In Progress',
                          style: TextStyle(
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
                child: const Center(
                  child: Text('PS',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Priya Sharma',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    Text('42, 3rd Cross, Indiranagar, Bengaluru',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.call_rounded,
                    color: AppColors.primary, size: 20),
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
          _PartRow('Gas Refill (R-22)', 1, '₹350'),
          const Divider(),
          _PartRow('Capacitor', 2, '₹280'),
          const Divider(),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Total Parts Cost',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              Text('₹630',
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

class _CompleteJobSheet extends StatelessWidget {
  const _CompleteJobSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Complete This Job?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(
              'Once completed, payment will be processed within 24 hours.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Your Payout',
                    style: TextStyle(
                        fontSize: 14, color: AppColors.textSecondary)),
                Text('₹799',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.success)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GradientButton(
            text: 'Confirm Completion',
            onTap: () => Navigator.pop(context),
            gradient: const LinearGradient(
                colors: [Color(0xFF00897B), Color(0xFF26C6DA)]),
          ),
          const SizedBox(height: 12),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
        ],
      ),
    );
  }
}
