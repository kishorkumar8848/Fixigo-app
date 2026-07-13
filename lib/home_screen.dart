import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'common_widgets.dart';
import 'track_repair_screen.dart';
import 'session.dart';
import 'api.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'location_picker_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<String>? onCategorySelected;
  final Function(String, String)? onPopularSelected;

  const HomeScreen({
    super.key,
    this.onCategorySelected,
    this.onPopularSelected,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _activeBooking;
  bool _isLoadingBooking = true;

  String? _filterCategory;
  double? _filterMaxPrice;
  double? _filterMinRating;

  @override
  void initState() {
    super.initState();
    _fetchActiveBooking();
  }

  Future<void> _fetchActiveBooking() async {
    if (Session.userId == null) {
      if (mounted) {
        setState(() => _isLoadingBooking = false);
      }
      return;
    }
    try {
      final resp = await Api.get('/bookings/user/${Session.userId}');
      if (resp['status'] == 200 && resp['data'] is List) {
        final List bookings = resp['data'];
        // Find first active booking (status is not completed or cancelled)
        final active = bookings.firstWhere(
          (b) => b['status'] != 'completed' && b['status'] != 'cancelled',
          orElse: () => null,
        );
        if (mounted) {
          setState(() {
            _activeBooking = active;
            _isLoadingBooking = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingBooking = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingBooking = false);
      }
    }
  }

  void _showSearchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (ctx, setStateSheet) {
            final filteredCategories = _allCategories
                .where((c) => c.label.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            final filteredRepairs = _allRepairs
                .where((r) => r.name.toLowerCase().contains(searchQuery.toLowerCase()) || r.category.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Search services, appliances...',
                            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textTertiary),
                            suffixIcon: searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, color: AppColors.textTertiary),
                                    onPressed: () {
                                      setStateSheet(() {
                                        searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (val) {
                            setStateSheet(() {
                              searchQuery = val;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: filteredCategories.isEmpty && filteredRepairs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off_rounded, color: Colors.grey.shade400, size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  'No services found for "$searchQuery"',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            children: [
                              if (filteredCategories.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                  child: Text('CATEGORIES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textTertiary)),
                                ),
                                ...filteredCategories.map((cat) {
                                  return ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: cat.color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(cat.icon, color: cat.color, size: 20),
                                    ),
                                    title: Text(cat.label.replaceAll('\n', ' ')),
                                    onTap: () {
                                      Navigator.pop(context);
                                      widget.onCategorySelected?.call(cat.label.replaceAll('\n', ' '));
                                    },
                                  );
                                }),
                                const SizedBox(height: 16),
                              ],
                              if (filteredRepairs.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                  child: Text('POPULAR REPAIRS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textTertiary)),
                                ),
                                ...filteredRepairs.map((r) {
                                  return ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: r.color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(r.icon, color: r.color, size: 20),
                                    ),
                                    title: Text(r.name),
                                    subtitle: Text(r.category),
                                    trailing: Text(
                                      r.price,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      widget.onPopularSelected?.call(r.category, r.name.replaceAll('\n', ' '));
                                    },
                                  );
                                }),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        String? tempCategory = _filterCategory;
        double? tempMaxPrice = _filterMaxPrice;
        double? tempMinRating = _filterMinRating;

        return StatefulBuilder(
          builder: (ctx, setStateSheet) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Services',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      TextButton(
                        onPressed: () {
                          setStateSheet(() {
                            tempCategory = null;
                            tempMaxPrice = null;
                            tempMinRating = null;
                          });
                        },
                        child: const Text('Reset All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allCategories.map((cat) {
                      final cleanLabel = cat.label.replaceAll('\n', ' ');
                      final isSelected = tempCategory == cleanLabel;
                      return ChoiceChip(
                        label: Text(cleanLabel),
                        selected: isSelected,
                        onSelected: (selected) {
                          setStateSheet(() {
                            tempCategory = selected ? cleanLabel : null;
                          });
                        },
                        selectedColor: AppColors.primarySurface,
                        backgroundColor: Colors.grey.shade100,
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text('Max Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(tempMaxPrice == null ? 'Any Price' : 'Up to ₹${tempMaxPrice!.toInt()}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Slider(
                    value: tempMaxPrice ?? 800,
                    min: 200,
                    max: 800,
                    divisions: 6,
                    activeColor: AppColors.primary,
                    inactiveColor: Colors.grey.shade200,
                    onChanged: (val) {
                      setStateSheet(() {
                        tempMaxPrice = val == 800 ? null : val;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('Minimum Rating', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  Row(
                    children: [4.5, 4.7, 4.8].map((rating) {
                      final isSelected = tempMinRating == rating;
                      return Container(
                        margin: const EdgeInsets.only(right: 10),
                        child: ChoiceChip(
                          avatar: Icon(Icons.star_rounded, color: isSelected ? AppColors.primary : Colors.amber, size: 16),
                          label: Text('$rating+ Stars'),
                          selected: isSelected,
                          onSelected: (selected) {
                            setStateSheet(() {
                              tempMinRating = selected ? rating : null;
                            });
                          },
                          selectedColor: AppColors.primarySurface,
                          backgroundColor: Colors.grey.shade100,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _filterCategory = tempCategory;
                          _filterMaxPrice = tempMaxPrice;
                          _filterMinRating = tempMinRating;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Apply Filters', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredRepairs = _allRepairs.where((r) {
      if (_filterCategory != null) {
        final catLower = _filterCategory!.toLowerCase();
        final repCatLower = r.category.toLowerCase();
        if (!repCatLower.contains(catLower) && !catLower.contains(repCatLower) &&
            !(catLower.contains('ac') && repCatLower.contains('ac')) &&
            !(catLower.contains('tv') && repCatLower.contains('tv'))) {
          return false;
        }
      }
      if (_filterMaxPrice != null) {
        final priceVal = double.tryParse(r.price.replaceAll('₹', '')) ?? 0.0;
        if (priceVal > _filterMaxPrice!) return false;
      }
      if (_filterMinRating != null) {
        if (r.rating < _filterMinRating!) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _HomeHeader()),
          // ── Search ─────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _SearchBar(
                onSearchTap: () => _showSearchSheet(context),
                onFilterTap: () => _showFilterSheet(context),
              ),
            ),
          ),
          // ── Active Filter Chips ─────────────────────────────────────────────
          if (_filterCategory != null || _filterMaxPrice != null || _filterMinRating != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      if (_filterCategory != null)
                        _FilterChip(
                          label: _filterCategory!,
                          onDelete: () => setState(() => _filterCategory = null),
                        ),
                      if (_filterMaxPrice != null)
                        _FilterChip(
                          label: 'Max ₹${_filterMaxPrice!.toInt()}',
                          onDelete: () => setState(() => _filterMaxPrice = null),
                        ),
                      if (_filterMinRating != null)
                        _FilterChip(
                          label: '${_filterMinRating!}+ Stars',
                          onDelete: () => setState(() => _filterMinRating = null),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          // ── Active booking banner ───────────────────────────────────────────
          if (!_isLoadingBooking && _activeBooking != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _ActiveBookingBanner(context, _activeBooking!),
              ),
            ),
          // ── Categories ─────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.only(top: 24),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  SectionHeader(
                    title: 'Our Services',
                    actionText: 'View all',
                    onAction: () => widget.onCategorySelected?.call('More'),
                  ),
                  const SizedBox(height: 16),
                  _ServiceCategories(
                    onCategorySelected: (cat) => widget.onCategorySelected?.call(cat),
                  ),
                ],
              ),
            ),
          ),
          // ── Quick Booking ───────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.only(top: 28),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  const SectionHeader(title: 'Popular Repairs'),
                  const SizedBox(height: 16),
                  _PopularRepairs(
                    repairs: filteredRepairs,
                    onPopularSelected: (cat, issue) => widget.onPopularSelected?.call(cat, issue),
                  ),
                ],
              ),
            ),
          ),
          // ── Promo Banner ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            sliver: SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () => widget.onCategorySelected?.call('More'),
                child: _PromoBanner(),
              ),
            ),
          ),
          // ── How it works ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.only(top: 28),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  const SectionHeader(title: 'How It Works'),
                  const SizedBox(height: 16),
                  _HowItWorks(),
                ],
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }

  Widget _ActiveBookingBanner(BuildContext context, Map<String, dynamic> booking) {
    final techName = booking['technician_name'] ?? 'Assigning Technician...';
    final status = booking['status'] ?? 'pending';

    String statusInfo = '';
    if (status == 'pending') {
      statusInfo = 'Awaiting technician assignment';
    } else if (status == 'assigned') {
      statusInfo = 'Technician assigned • ETA 30 mins';
    } else if (status == 'in_progress') {
      statusInfo = 'Service in progress';
    } else {
      statusInfo = status;
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TrackRepairScreen(booking: booking),
        ),
      ).then((_) => _fetchActiveBooking()),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00897B), Color(0xFF00ACC1)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00897B).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.engineering_rounded,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status == 'pending' ? 'Booking Confirmed!' : 'Technician On the Way!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    techName == 'Assigning Technician...' ? statusInfo : '$techName • $statusInfo',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Track',
                  style: TextStyle(
                      color: Color(0xFF00897B),
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero Header ───────────────────────────────────────────────────────────────
class _HomeHeader extends StatefulWidget {
  @override
  State<_HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<_HomeHeader> {
  Future<void> _changeLocation() async {
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
      // Optionally persist to database if user is logged in
      if (Session.userId != null) {
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
  }

  @override
  Widget build(BuildContext context) {
    final displayAddress = (Session.address != null && Session.address!.isNotEmpty)
        ? (Session.address!.length > 25 ? '${Session.address!.substring(0, 22)}...' : Session.address!)
        : 'Bengaluru, KA';

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: _changeLocation,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded,
                              color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              displayAddress,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12),
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded,
                              color: Colors.white70, size: 18),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hello, ${Session.name ?? 'User'}! 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'What needs fixing today?',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.75), fontSize: 13),
                    ),
                  ],
                ),
              ),
              Stack(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.notifications_rounded,
                        color: Colors.white, size: 22),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF6F00),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Search Bar ────────────────────────────────────────────────────────────────
// ── Master Lists ─────────────────────────────────────────────────────────────
const List<_Cat> _allCategories = [
  _Cat(
    'AC Repair',
    Icons.ac_unit_rounded,
    Color(0xFF1565C0),
    'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=500&auto=format&fit=crop&q=60',
  ),
  _Cat(
    'Washing\nMachine',
    Icons.local_laundry_service_rounded,
    Color(0xFF00897B),
    'https://images.unsplash.com/photo-1626806787461-102c1bfaaea1?w=500&auto=format&fit=crop&q=60',
  ),
  _Cat(
    'Refrigerator',
    Icons.kitchen_rounded,
    Color(0xFF6A1B9A),
    'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=500&auto=format&fit=crop&q=60',
  ),
  _Cat(
    'Microwave',
    Icons.microwave_rounded,
    Color(0xFFE65100),
    'https://images.unsplash.com/photo-1574269909862-7e1d70bb8078?w=500&auto=format&fit=crop&q=60',
  ),
  _Cat(
    'TV Repair',
    Icons.tv_rounded,
    Color(0xFF0277BD),
    'https://images.unsplash.com/photo-1593305841991-05c297ba4575?w=500&auto=format&fit=crop&q=60',
  ),
  _Cat(
    'Water\nPurifier',
    Icons.water_drop_rounded,
    Color(0xFF2E7D32),
    'https://images.unsplash.com/photo-1618579895756-65b827ac4f53?w=500&auto=format&fit=crop&q=60',
  ),
  _Cat(
    'Geyser',
    Icons.water_rounded,
    Color(0xFFC62828),
    'https://images.unsplash.com/photo-1584622781564-1d987f7333c1?w=500&auto=format&fit=crop&q=60',
  ),
];

const List<_Repair> _allRepairs = [
  _Repair(
    'AC Gas Refill',
    'AC & Air Coolers',
    '₹499',
    Icons.ac_unit_rounded,
    Color(0xFF1565C0),
    '45 min',
    4.8,
    'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=500&auto=format&fit=crop&q=60',
  ),
  _Repair(
    'Washing Machine\nService',
    'Washing Machines',
    '₹349',
    Icons.local_laundry_service_rounded,
    Color(0xFF00897B),
    '60 min',
    4.7,
    'https://images.unsplash.com/photo-1626806787461-102c1bfaaea1?w=500&auto=format&fit=crop&q=60',
  ),
  _Repair(
    'Refrigerator\nCooling Fix',
    'Refrigerators',
    '₹599',
    Icons.kitchen_rounded,
    Color(0xFF6A1B9A),
    '90 min',
    4.9,
    'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=500&auto=format&fit=crop&q=60',
  ),
];

// ── Filter Chip ───────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onDelete;

  const _FilterChip({required this.label, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(
              Icons.close_rounded,
              color: AppColors.primary,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search Bar ────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onFilterTap;

  const _SearchBar({required this.onSearchTap, required this.onFilterTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onSearchTap,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: const [
                  SizedBox(width: 16),
                  Icon(Icons.search_rounded, color: AppColors.textTertiary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Search services, appliances...',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: onFilterTap,
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Filter',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Service Categories ────────────────────────────────────────────────────────
class _ServiceCategories extends StatelessWidget {
  final ValueChanged<String>? onCategorySelected;

  const _ServiceCategories({this.onCategorySelected});

  @override
  Widget build(BuildContext context) {
    final cats = [
      ..._allCategories,
      const _Cat(
        'More',
        Icons.grid_view_rounded,
        Color(0xFF546E7A),
        'https://images.unsplash.com/photo-1517524206127-48bbd363f3d7?w=500&auto=format&fit=crop&q=60',
      ),
    ];
    return SizedBox(
      height: 96,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) {
          final cat = cats[i];
          return GestureDetector(
            onTap: () => onCategorySelected?.call(cat.label.replaceAll('\n', ' ')),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cat.color.withOpacity(0.2)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: CachedNetworkImage(
                      imageUrl: cat.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) => Container(
                        color: cat.color.withOpacity(0.1),
                        child: Center(
                          child: Icon(cat.icon, color: cat.color, size: 24),
                        ),
                      ),
                      errorWidget: (ctx, url, err) => Container(
                        color: cat.color.withOpacity(0.1),
                        child: Center(
                          child: Icon(cat.icon, color: cat.color, size: 24),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  cat.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Cat {
  final String label;
  final IconData icon;
  final Color color;
  final String imageUrl;
  const _Cat(this.label, this.icon, this.color, this.imageUrl);
}

// ── Popular Repairs ───────────────────────────────────────────────────────────
class _PopularRepairs extends StatelessWidget {
  final List<_Repair> repairs;
  final Function(String, String)? onPopularSelected;

  const _PopularRepairs({
    required this.repairs,
    this.onPopularSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (repairs.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.filter_list_off_rounded, color: AppColors.textTertiary, size: 36),
            SizedBox(height: 8),
            Text(
              'No repairs match active filters.',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return SizedBox(
      height: 180,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: repairs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (ctx, i) {
          final r = repairs[i];
          return GestureDetector(
            onTap: () => onPopularSelected?.call(r.category, r.name.replaceAll('\n', ' ')),
            child: Container(
              width: 180,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 80,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                            child: CachedNetworkImage(
                              imageUrl: r.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (ctx, url) => Container(
                                color: r.color.withOpacity(0.1),
                                child: Center(
                                  child: Icon(r.icon, color: r.color, size: 36),
                                ),
                              ),
                              errorWidget: (ctx, url, err) => Container(
                                color: r.color.withOpacity(0.1),
                                child: Center(
                                  child: Icon(r.icon, color: r.color, size: 36),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                              gradient: LinearGradient(
                                colors: [Colors.black.withOpacity(0.2), Colors.transparent],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.successLight,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Text(
                              'Starts ${r.price}',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              height: 1.3,
                            )),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.star_rounded,
                                size: 14, color: Colors.amber[600]),
                            const SizedBox(width: 3),
                            Text(
                              '${r.rating}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.schedule_rounded,
                                size: 13, color: AppColors.textTertiary),
                            const SizedBox(width: 3),
                            Text(r.duration,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Repair {
  final String name, category, price, duration;
  final IconData icon;
  final Color color;
  final double rating;
  final String imageUrl;
  const _Repair(this.name, this.category, this.price, this.icon, this.color,
      this.duration, this.rating, this.imageUrl);
}

// ── Promo Banner ──────────────────────────────────────────────────────────────
class _PromoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6F00), Color(0xFFFFA000)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('LIMITED OFFER',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1)),
                ),
                const SizedBox(height: 8),
                const Text('First repair\nat ₹99 only!',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.2)),
                const SizedBox(height: 4),
                Text('Use code: FIXNOW',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.85), fontSize: 12)),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Book Now',
                      style: TextStyle(
                          color: Color(0xFFFF6F00),
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ),
              ],
            ),
          ),
          const Icon(Icons.local_offer_rounded, color: Colors.white, size: 72),
        ],
      ),
    );
  }
}

// ── How It Works ──────────────────────────────────────────────────────────────
class _HowItWorks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final steps = [
      _Step(Icons.search_rounded, 'Choose\nService', AppColors.primary),
      _Step(Icons.calendar_today_rounded, 'Book\nSlot', AppColors.secondary),
      _Step(Icons.engineering_rounded, 'Expert\nVisits', Color(0xFF6A1B9A)),
      _Step(Icons.star_rounded, 'Rate &\nReview', Color(0xFFFF6F00)),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: Container(
                height: 2,
                color: AppColors.border,
                margin: const EdgeInsets.only(bottom: 28),
              ),
            );
          }
          final step = steps[i ~/ 2];
          return Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: step.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: step.color.withOpacity(0.3)),
                ),
                child: Icon(step.icon, color: step.color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                step.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _Step {
  final IconData icon;
  final String label;
  final Color color;
  const _Step(this.icon, this.label, this.color);
}
