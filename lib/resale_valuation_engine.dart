class ResaleValuationResult {
  final int minValue;
  final int maxValue;
  final String note;

  ResaleValuationResult({
    required this.minValue,
    required this.maxValue,
    required this.note,
  });

  String get displayRange => '₹${minValue.toString()}–₹${maxValue.toString()}';
}

class ResaleValuationEngine {
  static final Map<String, _CategoryRule> _categoryRules = {
    'tv': _CategoryRule(
        lifespanYears: 7, defaultMarketValue: 32000, volatility: 0.11),
    'refrigerator': _CategoryRule(
        lifespanYears: 10, defaultMarketValue: 26000, volatility: 0.10),
    'washing machine': _CategoryRule(
        lifespanYears: 8, defaultMarketValue: 24000, volatility: 0.12),
    'ac': _CategoryRule(
        lifespanYears: 12, defaultMarketValue: 42000, volatility: 0.12),
    'laptop': _CategoryRule(
        lifespanYears: 5, defaultMarketValue: 70000, volatility: 0.14),
    'mobile': _CategoryRule(
        lifespanYears: 4, defaultMarketValue: 30000, volatility: 0.16),
    'fan': _CategoryRule(
        lifespanYears: 10, defaultMarketValue: 5000, volatility: 0.08),
    'microwave': _CategoryRule(
        lifespanYears: 6, defaultMarketValue: 12000, volatility: 0.12),
    'water purifier': _CategoryRule(
        lifespanYears: 8, defaultMarketValue: 18000, volatility: 0.10),
    'geyser': _CategoryRule(
        lifespanYears: 8, defaultMarketValue: 15000, volatility: 0.10),
    'speaker': _CategoryRule(
        lifespanYears: 7, defaultMarketValue: 16000, volatility: 0.12),
    'mixer grinder': _CategoryRule(
        lifespanYears: 7, defaultMarketValue: 9000, volatility: 0.09),
    'all': _CategoryRule(
        lifespanYears: 8, defaultMarketValue: 18000, volatility: 0.14),
  };

  static final Map<String, double> _brandMultipliers = {
    'lg': 1.05,
    'samsung': 1.08,
    'sony': 1.07,
    'whirlpool': 1.04,
    'bosch': 1.06,
    'godrej': 1.03,
    'dell': 1.05,
    'hp': 1.04,
    'apple': 1.12,
    'oneplus': 1.08,
    'xiaomi': 0.97,
    'realme': 0.96,
    'mi': 0.96,
    'panasonic': 1.02,
    'mitsubishi': 1.05,
  };

  static final Map<String, double> _conditionFactors = {
    'excellent': 1.0,
    'good': 0.92,
    'fair': 0.78,
    'poor': 0.62,
  };

  static final Map<String, double> _workingFactors = {
    'working': 1.0,
    'minor issue': 0.84,
    'major issue': 0.62,
    'not working': 0.38,
  };

  static final Map<String, double> _cosmeticFactors = {
    'excellent': 1.0,
    'good': 0.94,
    'fair': 0.82,
    'poor': 0.68,
  };

  static ResaleValuationResult estimate({
    required String applianceName,
    required String category,
    required String brand,
    required int originalPrice,
    required int purchaseYear,
    required String condition,
    required String workingStatus,
    required String cosmeticCondition,
    required bool hasBill,
    required bool hasBox,
    required bool hasWarranty,
    required bool hasAccessories,
  }) {
    final normalizedCategory = category.trim().toLowerCase();
    final rule = _categoryRules[normalizedCategory] ?? _categoryRules['all']!;

    final now = DateTime.now().year;
    final age = (now - purchaseYear).clamp(0, rule.lifespanYears * 2);
    final basePrice = originalPrice > 0
        ? originalPrice.toDouble()
        : rule.defaultMarketValue.toDouble();

    final depreciation = _applyDepreciation(age, rule.lifespanYears);
    final conditionFactor = _conditionFactors[condition.toLowerCase()] ?? 0.88;
    final workingFactor = _workingFactors[workingStatus.toLowerCase()] ?? 0.82;
    final cosmeticFactor =
        _cosmeticFactors[cosmeticCondition.toLowerCase()] ?? 0.88;
    final brandFactor = _findBrandMultiplier(brand);
    final accessoryBonus = 1 +
        (hasBill ? 0.03 : 0.0) +
        (hasBox ? 0.02 : 0.0) +
        (hasWarranty ? 0.04 : 0.0) +
        (hasAccessories ? 0.03 : 0.0);

    final estimated = basePrice *
        depreciation *
        conditionFactor *
        workingFactor *
        cosmeticFactor *
        brandFactor *
        accessoryBonus;
    final minValue = _roundToHundred(
        (estimated * (1 - rule.volatility)).clamp(400, double.infinity));
    final maxValue = _roundToHundred(
        (estimated * (1 + rule.volatility)).clamp(600, double.infinity));

    return ResaleValuationResult(
      minValue: minValue,
      maxValue: maxValue,
      note:
          'Final price will be confirmed after physical inspection by a Fixigo technician.',
    );
  }

  static double _applyDepreciation(int age, int lifespanYears) {
    if (age <= 0) return 1.0;
    final ratio = age / lifespanYears;
    final depreciation = 1 - (ratio * 0.72);
    return depreciation.clamp(0.22, 1.0);
  }

  static double _findBrandMultiplier(String brand) {
    final key = brand.trim().toLowerCase();
    if (key.isEmpty) return 1.0;
    for (final entry in _brandMultipliers.entries) {
      if (key.contains(entry.key)) {
        return entry.value;
      }
    }
    return 1.0;
  }

  static int _roundToHundred(double value) {
    return (value / 100).round() * 100;
  }
}

class _CategoryRule {
  final int lifespanYears;
  final int defaultMarketValue;
  final double volatility;

  const _CategoryRule({
    required this.lifespanYears,
    required this.defaultMarketValue,
    required this.volatility,
  });
}
