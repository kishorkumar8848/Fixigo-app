import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'common_widgets.dart';
import 'resell_schedule_screen.dart';
import 'role_selection.dart';
import 'session.dart';
import 'api.dart';
import 'location_picker_screen.dart';
class ProfileScreen extends StatefulWidget {
  final Function(int)? onTabChanged;

  const ProfileScreen({super.key, this.onTabChanged});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String _name = '';
  String _email = '';
  String _phone = '';
  String _address = '';
  int _totalRepairs = 0;
  int _activeWarranties = 0;
  int _appliancesSold = 0;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    if (Session.userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final resp = await Api.get('/auth/customer/profile/${Session.userId}');
      if (resp['status'] == 200) {
        final data = resp['data'];
        final stats = data['stats'] ?? {};
        if (mounted) {
          setState(() {
            _name = data['name'] ?? '';
            _email = data['email'] ?? '';
            _phone = data['phone'] ?? '';
            _address = data['address'] ?? '';
            _totalRepairs = stats['totalRepairs'] ?? 0;
            _activeWarranties = stats['activeWarranties'] ?? 0;
            _appliancesSold = stats['appliancesSold'] ?? 0;

            // Sync with Session
            Session.name = _name;
            Session.email = _email;
            Session.phone = _phone;
            Session.address = _address;

            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile(
      String newName, String newEmail, String newPhone, String newAddress) async {
    setState(() => _isLoading = true);
    try {
      final resp = await Api.put('/auth/customer/profile/${Session.userId}', {
        'name': newName,
        'email': newEmail,
        'phone': newPhone,
        'address': newAddress,
      });
      if (resp['status'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        await _fetchProfileData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  resp['data']['message'] ?? 'Failed to update profile')),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  void _showEditPersonalDialog() {
    final nameController = TextEditingController(text: _name);
    final emailController = TextEditingController(text: _email);
    final phoneController = TextEditingController(text: _phone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Personal Information'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email Address'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateProfile(
                nameController.text.trim(),
                emailController.text.trim(),
                phoneController.text.trim(),
                _address,
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditAddressDialog() {
    final addressController = TextEditingController(text: _address);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Saved Address'),
        content: TextField(
          controller: addressController,
          decoration: InputDecoration(
            hintText: 'Enter your full address',
            suffixIcon: IconButton(
              icon: const Icon(Icons.my_location_rounded, color: AppColors.primary),
              onPressed: () => _requestAndFetchLocation(addressController),
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateProfile(
                _name,
                _email,
                _phone,
                addressController.text.trim(),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestAndFetchLocation(TextEditingController controller) async {
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
        controller.text = result.address;
        Session.address = result.address;
        Session.latitude = result.latitude;
        Session.longitude = result.longitude;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: FixigoAppBar(
        title: 'My Profile',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: _showEditPersonalDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchProfileData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Profile header
                    _ProfileHeader(name: _name, email: _email),
                    const SizedBox(height: 16),
                    // Stats
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                              child: StatCard(
                                  label: 'Total Repairs',
                                  value: _totalRepairs.toString(),
                                  icon: Icons.build_rounded,
                                  color: AppColors.primary,
                                  bgColor: AppColors.primarySurface)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: StatCard(
                                  label: 'Active Warranties',
                                  value: _activeWarranties.toString(),
                                  icon: Icons.verified_rounded,
                                  color: AppColors.success,
                                  bgColor: AppColors.successLight)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: StatCard(
                                  label: 'Appliances Sold',
                                  value: _appliancesSold.toString(),
                                  icon: Icons.sell_rounded,
                                  color: AppColors.secondary,
                                  bgColor: AppColors.secondarySurface)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Menu groups
                    _MenuGroup(
                      title: 'Account',
                      items: [
                        _MenuItem(Icons.person_rounded, 'Personal Information',
                            onTap: _showEditPersonalDialog),
                        _MenuItem(Icons.location_on_rounded, 'Saved Address',
                            badge: _address.isNotEmpty ? '1' : null,
                            onTap: _showEditAddressDialog),
                        _MenuItem(Icons.payment_rounded, 'Payment Methods',
                            onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Payment methods coming soon!')),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _MenuGroup(
                      title: 'Services',
                      items: [
                        _MenuItem(Icons.history_rounded, 'Repair History',
                            onTap: () => widget.onTabChanged?.call(3)),
                        _MenuItem(Icons.verified_rounded, 'My Warranties',
                            onTap: () => widget.onTabChanged?.call(3)),
                        _MenuItem(Icons.sell_rounded, 'My Listings (Resell)',
                            badge: _appliancesSold > 0
                                ? _appliancesSold.toString()
                                : null,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ResellScheduleScreen(),
                                ),
                              );
                            }),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _MenuGroup(
                      title: 'Support & Legal',
                      items: [
                        _MenuItem(Icons.headset_mic_rounded, 'Customer Support',
                            onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Opening Support Ticket...')),
                          );
                        }),
                        _MenuItem(Icons.star_rounded, 'Rate the App', onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Thank you for your rating!')),
                          );
                        }),
                        _MenuItem(Icons.share_rounded, 'Refer & Earn ₹200',
                            isHighlight: true, onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Referral link copied!')),
                          );
                        }),
                        _MenuItem(Icons.privacy_tip_rounded, 'Privacy Policy',
                            onTap: () {}),
                        _MenuItem(Icons.description_rounded, 'Terms of Service',
                            onTap: () {}),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Clear session
                          Session.token = null;
                          Session.role = null;
                          Session.userId = null;
                          Session.name = null;
                          Session.email = null;
                          Session.phone = null;
                          Session.address = null;

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RoleSelectionScreen()),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text('Logout'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Version 1.0.0 • Fixigo',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textTertiary)),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;

  const _ProfileHeader({required this.name, required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      color: AppColors.surface,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty
                        ? name
                            .trim()
                            .split(' ')
                            .map((e) => e.isNotEmpty ? e[0] : '')
                            .take(2)
                            .join()
                            .toUpperCase()
                        : 'U',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.edit_rounded,
                      color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(name.isNotEmpty ? name : 'User',
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(email,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          StatusBadge.success('Verified Customer'),
        ],
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _MenuGroup({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Text(title.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary,
                  letterSpacing: 1)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: List.generate(items.length, (i) {
              final item = items[i];
              return Column(
                children: [
                  ListTile(
                    onTap: item.onTap,
                    leading: Container(
                       padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: item.isHighlight
                            ? AppColors.accentLight
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(item.icon,
                          size: 18,
                          color: item.isHighlight
                              ? AppColors.accent
                              : AppColors.primary),
                    ),
                    title: Text(item.label,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: item.isHighlight
                                ? AppColors.accent
                                : AppColors.textPrimary)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.badge != null)
                          Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(item.badge!,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            size: 14, color: AppColors.textTertiary),
                      ],
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  ),
                  if (i < items.length - 1)
                    const Padding(
                      padding: EdgeInsets.only(left: 56),
                      child: Divider(height: 1),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String? badge;
  final bool isHighlight;
  final VoidCallback? onTap;

  const _MenuItem(this.icon, this.label,
      {this.badge, this.isHighlight = false, this.onTap});
}
