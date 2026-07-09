import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'common_widgets.dart';

class ResellScheduleRepository {
  static final List<_ResellScheduleItem> _items = [];

  static List<_ResellScheduleItem> get items => List.unmodifiable(_items);

  static void addSchedule({
    required String appliance,
    required DateTime scheduledDate,
    required String address,
  }) {
    _items.insert(
      0,
      _ResellScheduleItem(
        appliance: appliance,
        scheduledDate: scheduledDate,
        address: address,
        status: _ResellStatus.scheduled,
      ),
    );
  }

  static void cancelSchedule(_ResellScheduleItem item, String reason) {
    item.status = _ResellStatus.cancelled;
    item.cancelReason = reason;
  }
}

class ResellScheduleScreen extends StatefulWidget {
  const ResellScheduleScreen({super.key});

  @override
  State<ResellScheduleScreen> createState() => _ResellScheduleScreenState();
}

class _ResellScheduleScreenState extends State<ResellScheduleScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings Schedule'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Builder(
          builder: (context) {
            final schedules = ResellScheduleRepository.items;
            return schedules.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.sell_rounded,
                          size: 80, color: AppColors.primary),
                      const SizedBox(height: 16),
                      const Text(
                        'No scheduled resell pickups yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Once you schedule a free pickup, it will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: schedules.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final item = schedules[index];
                      return _ResellScheduleCard(
                        item: item,
                        onCancel: item.status == _ResellStatus.scheduled
                            ? () => _cancelSchedule(item)
                            : null,
                      );
                    },
                  );
          },
        ),
      ),
    );
  }

  void _cancelSchedule(_ResellScheduleItem item) async {
    final reason = await _showCancelReasonDialog();
    if (reason == null || reason.isEmpty) return;

    setState(() {
      ResellScheduleRepository.cancelSchedule(item, reason);
    });
  }

  Future<String?> _showCancelReasonDialog() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Pickup'),
        content: TextField(
          controller: controller,
          decoration:
              const InputDecoration(hintText: 'Reason for cancellation'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx, controller.text.trim());
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class _ResellScheduleCard extends StatelessWidget {
  final _ResellScheduleItem item;
  final VoidCallback? onCancel;

  const _ResellScheduleCard({
    required this.item,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.status == _ResellStatus.cancelled
              ? AppColors.error.withOpacity(0.2)
              : AppColors.primary.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.appliance,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: item.status == _ResellStatus.cancelled
                      ? AppColors.errorLight
                      : AppColors.successLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.status == _ResellStatus.cancelled
                      ? 'Cancelled'
                      : 'Scheduled',
                  style: TextStyle(
                    color: item.status == _ResellStatus.cancelled
                        ? AppColors.error
                        : AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                item.formattedDate,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.address,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          if (item.cancelReason != null && item.cancelReason!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cancellation Reason',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.cancelReason!,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          if (onCancel != null) ...[
            const SizedBox(height: 14),
            GradientButton(
              text: 'Cancel Pickup',
              onTap: onCancel,
              gradient: const LinearGradient(
                colors: [Color(0xFFEF5350), Color(0xFFD32F2F)],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _ResellStatus { scheduled, cancelled }

class _ResellScheduleItem {
  final String appliance;
  final DateTime scheduledDate;
  final String address;
  _ResellStatus status;
  String? cancelReason;

  _ResellScheduleItem({
    required this.appliance,
    required this.scheduledDate,
    required this.address,
    required this.status,
    this.cancelReason,
  });

  String get formattedDate {
    return '${scheduledDate.day.toString().padLeft(2, '0')}-${scheduledDate.month.toString().padLeft(2, '0')}-${scheduledDate.year}';
  }
}
