import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'common_widgets.dart';

class ResellScreen extends StatefulWidget {
  const ResellScreen({super.key});

  @override
  State<ResellScreen> createState() => _ResellScreenState();
}

class _ResellScreenState extends State<ResellScreen> {
  int? _selectedAppliance;
  String _condition = 'Good';
  bool _showValuation = false;

  final _appliances = const [
    ('AC', Icons.ac_unit_rounded, Color(0xFF1565C0)),
    ('Washing Machine', Icons.local_laundry_service_rounded, Color(0xFF00897B)),
    ('Refrigerator', Icons.kitchen_rounded, Color(0xFF6A1B9A)),
    ('TV', Icons.tv_rounded, Color(0xFF0277BD)),
    ('Microwave', Icons.microwave_rounded, Color(0xFFE65100)),
    ('Other', Icons.devices_other_rounded, Color(0xFF546E7A)),
  ];

  final _conditions = ['Excellent', 'Good', 'Fair', 'Poor'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const FixigoAppBar(title: 'Sell Your Appliance'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero card
            _HeroBanner(),
            const SizedBox(height: 24),
            // Select appliance
            const Text('Select Appliance Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(_appliances.length, (i) {
                final (name, icon, color) = _appliances[i];
                final sel = _selectedAppliance == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedAppliance = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: (MediaQuery.of(context).size.width - 62) / 3,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: sel ? color.withOpacity(0.1) : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: sel ? color : AppColors.border,
                          width: sel ? 2 : 1),
                    ),
                    child: Column(
                      children: [
                        Icon(icon,
                            color: sel ? color : AppColors.textSecondary,
                            size: 28),
                        const SizedBox(height: 6),
                        Text(name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: sel ? color : AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            // Upload images
            const Text('Upload Photos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Add at least 2 photos for better valuation',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Row(
              children: [
                _UploadBox(label: 'Front view', isDashed: true),
                const SizedBox(width: 10),
                _UploadBox(label: 'Side view', isDashed: true),
                const SizedBox(width: 10),
                _UploadBox(label: 'More', isDashed: false),
              ],
            ),
            const SizedBox(height: 24),
            // Details
            const Text('Appliance Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Brand & Model',
                hintText: 'e.g. LG, 5 Star, 1.5 Ton',
                prefixIcon: Icon(Icons.business_rounded),
              ),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Year of Purchase',
                hintText: 'e.g. 2019',
                prefixIcon: Icon(Icons.calendar_today_rounded),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            // Condition selector
            const Text('Condition',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(
              children: _conditions.map((c) {
                final sel = _condition == c;
                final colors = {
                  'Excellent': AppColors.success,
                  'Good': AppColors.info,
                  'Fair': AppColors.warning,
                  'Poor': AppColors.error,
                };
                final col = colors[c]!;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _condition = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? col.withOpacity(0.1) : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: sel ? col : AppColors.border,
                            width: sel ? 2 : 1),
                      ),
                      child: Text(c,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: sel ? col : AppColors.textSecondary)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // Get valuation
            GradientButton(
              text: 'Get Instant Valuation',
              onTap: () => setState(() => _showValuation = true),
              gradient: const LinearGradient(
                colors: [Color(0xFF00897B), Color(0xFF00ACC1)],
              ),
              icon: const Icon(Icons.price_check_rounded,
                  color: Colors.white, size: 20),
            ),
            if (_showValuation) ...[
              const SizedBox(height: 20),
              _ValuationCard(),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00897B), Color(0xFF26C6DA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Turn Old into Gold! 🪙',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17)),
                const SizedBox(height: 4),
                Text('Sell your old appliances\nat the best price in 48 hours',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                        height: 1.5)),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.4)),
                  ),
                  child: const Text('Free Pickup • Instant Cash',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 11)),
                ),
              ],
            ),
          ),
          const Icon(Icons.sell_rounded, color: Colors.white, size: 60),
        ],
      ),
    );
  }
}

class _UploadBox extends StatelessWidget {
  final String label;
  final bool isDashed;

  const _UploadBox({required this.label, required this.isDashed});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDashed
                  ? AppColors.primary.withOpacity(0.4)
                  : AppColors.border,
              style: isDashed ? BorderStyle.solid : BorderStyle.solid,
              width: isDashed ? 1.5 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDashed ? Icons.add_photo_alternate_rounded : Icons.add_rounded,
              color: isDashed ? AppColors.primary : AppColors.textTertiary,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color:
                        isDashed ? AppColors.primary : AppColors.textTertiary,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ValuationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.secondary.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('Estimated Resale Value',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  fontSize: 13)),
          const SizedBox(height: 8),
          const Text('₹8,500 – ₹11,000',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.success)),
          const SizedBox(height: 4),
          const Text('Based on model, age & condition',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ValDetail('Free Pickup', Icons.local_shipping_rounded),
              _ValDetail('Instant Cash', Icons.currency_rupee_rounded),
              _ValDetail('Same Day', Icons.flash_on_rounded),
            ],
          ),
          const SizedBox(height: 16),
          GradientButton(
            text: 'Schedule Free Pickup',
            onTap: () {},
            gradient: const LinearGradient(
              colors: [Color(0xFF00897B), Color(0xFF26C6DA)],
            ),
          ),
        ],
      ),
    );
  }
}

class _ValDetail extends StatelessWidget {
  final String label;
  final IconData icon;
  const _ValDetail(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.successLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.success, size: 20),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      ],
    );
  }
}
