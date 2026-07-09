import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_theme.dart';
import 'common_widgets.dart';
import 'resale_valuation_engine.dart';
import 'resell_schedule_screen.dart';
import 'session.dart';
import 'location_picker_screen.dart';

class ResellScreen extends StatefulWidget {
  const ResellScreen({super.key});

  @override
  State<ResellScreen> createState() => _ResellScreenState();
}

class _ResellScreenState extends State<ResellScreen> {
  int? _selectedAppliance;
  String _condition = 'Good';
  bool _showValuation = false;
  bool _locationSupported = true;

  final _locationKeywords = const ['chennai'];
  final _appliances = const [
    _ApplianceOption('AC', Icons.ac_unit_rounded, Color(0xFF1565C0), 'Cooling'),
    _ApplianceOption('Washing Machine', Icons.local_laundry_service_rounded,
        Color(0xFF00897B), 'Laundry'),
    _ApplianceOption(
        'Refrigerator', Icons.kitchen_rounded, Color(0xFF6A1B9A), 'Kitchen'),
    _ApplianceOption(
        'TV', Icons.tv_rounded, Color(0xFF0277BD), 'Entertainment'),
    _ApplianceOption(
        'Microwave', Icons.microwave_rounded, Color(0xFFE65100), 'Kitchen'),
    _ApplianceOption(
        'Other', Icons.devices_other_rounded, Color(0xFF546E7A), 'All'),
  ];

  final _conditions = ['Excellent', 'Good', 'Fair', 'Poor'];

  late final TextEditingController _locationController;
  late final TextEditingController _brandController;
  late final TextEditingController _yearController;
  late final TextEditingController _originalPriceController;
  late final TextEditingController _manualApplianceController;
  String? _manualAppliance;
  String _workingStatus = 'Working';
  String _cosmeticCondition = 'Excellent';
  bool _hasBill = false;
  bool _hasBox = false;
  bool _hasWarranty = false;
  bool _hasAccessories = false;
  ResaleValuationResult? _valuationResult;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(text: Session.address ?? '');
    _brandController = TextEditingController();
    _yearController = TextEditingController();
    _originalPriceController = TextEditingController();
    _manualApplianceController = TextEditingController();
    _validateLocation();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _brandController.dispose();
    _yearController.dispose();
    _originalPriceController.dispose();
    _manualApplianceController.dispose();
    super.dispose();
  }

  void _validateLocation() {
    final location = _locationController.text.trim().toLowerCase();
    _locationSupported = location.isNotEmpty &&
        _locationKeywords.any((keyword) => location.contains(keyword));
  }

  void _updateLocation(String value) {
    setState(() {
      _locationController.text = value;
      _locationController.selection = TextSelection.fromPosition(
        TextPosition(offset: _locationController.text.length),
      );
      _validateLocation();
    });
  }

  Future<void> _selectLocationOnMap() async {
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
        _locationController.text = result.address;
        Session.address = result.address;
        Session.latitude = result.latitude;
        Session.longitude = result.longitude;
        _validateLocation();
      });
    }
  }

  void _calculateValuation() {
    final selectedApplianceName = _manualAppliance ??
        (_selectedAppliance != null
            ? _appliances[_selectedAppliance!].name
            : 'Other');
    final category = _selectedAppliance != null
        ? _appliances[_selectedAppliance!].category
        : 'All';
    final purchaseYear =
        int.tryParse(_yearController.text.trim()) ?? DateTime.now().year;
    final originalPrice =
        int.tryParse(_originalPriceController.text.trim()) ?? 0;

    setState(() {
      _valuationResult = ResaleValuationEngine.estimate(
        applianceName: selectedApplianceName,
        category: category,
        brand: _brandController.text.trim(),
        originalPrice: originalPrice,
        purchaseYear: purchaseYear,
        condition: _condition,
        workingStatus: _workingStatus,
        cosmeticCondition: _cosmeticCondition,
        hasBill: _hasBill,
        hasBox: _hasBox,
        hasWarranty: _hasWarranty,
        hasAccessories: _hasAccessories,
      );
    });
  }

  Future<void> _schedulePickup() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );

    if (selectedDate == null) return;

    final selectedApplianceName = _manualAppliance ??
        (_selectedAppliance != null
            ? _appliances[_selectedAppliance!].name
            : 'Other');

    ResellScheduleRepository.addSchedule(
      appliance: selectedApplianceName,
      scheduledDate: selectedDate,
      address: _locationController.text.trim(),
    );

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pickup Scheduled'),
        content: const Text(
          'Your pickup is scheduled. Our delivery partner will contact you shortly.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _openAllAppliances() async {
    final selected = await Navigator.push<_ApplianceOption>(
      context,
      MaterialPageRoute(builder: (_) => const AllAppliancesScreen()),
    );

    if (selected != null) {
      setState(() {
        _manualAppliance = null;
        _selectedAppliance =
            _appliances.indexWhere((item) => item.name == selected.name);
      });
    }
  }

  void _enterManualAppliance() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter appliance name'),
          content: TextField(
            controller: _manualApplianceController,
            decoration: const InputDecoration(hintText: 'e.g. Water Purifier'),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = _manualApplianceController.text.trim();
                if (value.isEmpty) return;
                setState(() {
                  _manualAppliance = value;
                  _selectedAppliance = null;
                });
                _manualApplianceController.clear();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

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
            // Location
            const Text('Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              keyboardType: TextInputType.streetAddress,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Enter your location',
                hintText: 'e.g. Chennai, Anna Nagar',
                prefixIcon: const Icon(Icons.location_on_rounded),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.map_rounded, color: AppColors.primary),
                  onPressed: _selectLocationOnMap,
                  tooltip: 'Select on Google Maps',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => _updateLocation(value),
            ),
            const SizedBox(height: 12),
            if (!_locationSupported)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFB74D)),
                ),
                child: const Text(
                  'Oops! Our service is not in your location yet. We currently serve Chennai only.',
                  style: TextStyle(
                      color: Color(0xFF6D4C41), fontWeight: FontWeight.w600),
                ),
              ),
            const SizedBox(height: 24),
            const Text('Select Appliance Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(_appliances.length, (i) {
                final name = _appliances[i].name;
                final icon = _appliances[i].icon;
                final color = _appliances[i].color;
                final sel = _selectedAppliance == i;
                return GestureDetector(
                  onTap: () {
                    if (name == 'Other') {
                      _openAllAppliances();
                    } else {
                      setState(() {
                        _selectedAppliance = i;
                        _manualAppliance = null;
                      });
                    }
                  },
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _enterManualAppliance,
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Type appliance manually'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
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
            if (_manualAppliance != null) ...[
              Text('Selected Appliance: $_manualAppliance',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
            ],
            const Text('Appliance Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: _brandController,
              decoration: const InputDecoration(
                labelText: 'Brand & Model',
                hintText: 'e.g. LG, 5 Star, 1.5 Ton',
                prefixIcon: Icon(Icons.business_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _yearController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Year of Purchase',
                hintText: 'e.g. 2019',
                prefixIcon: Icon(Icons.calendar_today_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _originalPriceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Original Price / Market Value',
                hintText: 'e.g. 45000',
                prefixIcon: Icon(Icons.currency_rupee_rounded),
              ),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            const Text('Working Status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Working', 'Minor issue', 'Major issue', 'Not working']
                  .map((status) {
                final selected = _workingStatus == status;
                return ChoiceChip(
                  label: Text(status),
                  selected: selected,
                  onSelected: (_) => setState(() => _workingStatus = status),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Extras',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _CheckboxOption(
                  label: 'Original bill',
                  value: _hasBill,
                  onChanged: (value) => setState(() => _hasBill = value),
                ),
                _CheckboxOption(
                  label: 'Original box',
                  value: _hasBox,
                  onChanged: (value) => setState(() => _hasBox = value),
                ),
                _CheckboxOption(
                  label: 'Warranty',
                  value: _hasWarranty,
                  onChanged: (value) => setState(() => _hasWarranty = value),
                ),
                _CheckboxOption(
                  label: 'Accessories',
                  value: _hasAccessories,
                  onChanged: (value) => setState(() => _hasAccessories = value),
                ),
              ],
            ),
            const SizedBox(height: 24),
            GradientButton(
              text: _locationSupported
                  ? 'Get Instant Valuation'
                  : 'Location not supported',
              onTap: _locationSupported ? _calculateValuation : null,
              gradient: const LinearGradient(
                colors: [Color(0xFF00897B), Color(0xFF00ACC1)],
              ),
              icon: const Icon(Icons.price_check_rounded,
                  color: Colors.white, size: 20),
            ),
            if (_valuationResult != null) ...[
              const SizedBox(height: 20),
              _ValuationCard(
                result: _valuationResult!,
                onSchedule: _schedulePickup,
              ),
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
  final ResaleValuationResult result;
  final VoidCallback? onSchedule;

  const _ValuationCard({
    required this.result,
    this.onSchedule,
  });

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
          Text(result.displayRange,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.success)),
          const SizedBox(height: 4),
          const Text('Estimated range based on available details',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Text(result.note,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              )),
          const SizedBox(height: 16),
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
            onTap: onSchedule,
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

class _CheckboxOption extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CheckboxOption({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: onChanged,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        color: value ? Colors.white : AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ApplianceOption {
  final String name;
  final IconData icon;
  final Color color;
  final String category;

  const _ApplianceOption(this.name, this.icon, this.color, this.category);
}

class AllAppliancesScreen extends StatefulWidget {
  const AllAppliancesScreen({super.key});

  @override
  State<AllAppliancesScreen> createState() => _AllAppliancesScreenState();
}

class _AllAppliancesScreenState extends State<AllAppliancesScreen> {
  String _selectedCategory = 'All';

  final List<_ApplianceOption> _allAppliances = const [
    _ApplianceOption('AC', Icons.ac_unit_rounded, Color(0xFF1565C0), 'Cooling'),
    _ApplianceOption(
        'Refrigerator', Icons.kitchen_rounded, Color(0xFF6A1B9A), 'Kitchen'),
    _ApplianceOption('Washing Machine', Icons.local_laundry_service_rounded,
        Color(0xFF00897B), 'Laundry'),
    _ApplianceOption(
        'Microwave', Icons.microwave_rounded, Color(0xFFE65100), 'Kitchen'),
    _ApplianceOption(
        'TV', Icons.tv_rounded, Color(0xFF0277BD), 'Entertainment'),
    _ApplianceOption('Water Purifier', Icons.water_damage_rounded,
        Color(0xFF4A148C), 'Kitchen'),
    _ApplianceOption(
        'Geyser', Icons.hot_tub_rounded, Color(0xFFEF6C00), 'Water & Heating'),
    _ApplianceOption(
        'Mixer Grinder', Icons.kitchen_rounded, Color(0xFF8E24AA), 'Kitchen'),
    _ApplianceOption(
        'Laptop', Icons.laptop_mac_rounded, Color(0xFF37474F), 'IT & Smart'),
    _ApplianceOption(
        'Speaker', Icons.speaker_rounded, Color(0xFF5D4037), 'Entertainment'),
    _ApplianceOption(
        'Fan', Icons.toys_rounded, Color(0xFF1976D2), 'Electrical'),
    _ApplianceOption('Water Heater', Icons.bolt_rounded, Color(0xFFD32F2F),
        'Water & Heating'),
  ];

  final _categories = const [
    'All',
    'Cooling',
    'Kitchen',
    'Laundry',
    'Entertainment',
    'IT & Smart',
    'Electrical',
    'Water & Heating',
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedCategory == 'All'
        ? _allAppliances
        : _allAppliances
            .where((item) => item.category == _selectedCategory)
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('All Appliances')),
      body: Column(
        children: [
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final selected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: selected,
                  onSelected: (value) {
                    if (value) {
                      setState(() => _selectedCategory = category);
                    }
                  },
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: selected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.05,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                return GestureDetector(
                  onTap: () => Navigator.pop(context, item),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: item.color.withOpacity(0.25)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: item.color.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(item.icon, color: item.color, size: 28),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.category,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
