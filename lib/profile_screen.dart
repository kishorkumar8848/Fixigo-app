import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'common_widgets.dart';
import 'role_selection.dart';
import 'session.dart';
import 'api.dart';
import 'warranty_screen.dart';
import 'customer_listings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isSaving = false;

  void _showPersonalInfoDialog(BuildContext context) {
    final nameController = TextEditingController(text: Session.name);
    final emailController = TextEditingController(text: Session.email);
    final phoneController = TextEditingController(text: Session.phone ?? '9999999999');
    final addressController = TextEditingController(text: Session.address);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Personal Information',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            content: _isSaving
                ? const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.email_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
            actions: _isSaving
                ? []
                : [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        final email = emailController.text.trim();
                        final phone = phoneController.text.trim();

                        if (name.isEmpty || email.isEmpty || phone.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill all fields')),
                          );
                          return;
                        }

                        setDialogState(() => _isSaving = true);

                        try {
                          final resp = await Api.put('/auth/customer/profile/${Session.userId}', {
                            'name': name,
                            'email': email,
                            'phone': phone,
                            'address': addressController.text.trim(),
                          });

                          if (resp['status'] == 200) {
                            setState(() {
                              Session.name = name;
                              Session.email = email;
                              Session.phone = phone;
                            });
                            await Session.saveToDisk();

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Profile updated successfully!')),
                              );
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(resp['data']['message'] ?? 'Failed to update profile')),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Connection error, try again.')),
                            );
                          }
                        } finally {
                          setDialogState(() => _isSaving = false);
                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text('Save'),
                    ),
                  ],
          );
        },
      ),
    );
  }

  void _showSavedAddressDialog(BuildContext context) {
    final addressController = TextEditingController(text: Session.address);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Saved Address',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            content: _isSaving
                ? const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: addressController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Home / Delivery Address',
                          prefixIcon: Icon(Icons.location_on_rounded),
                        ),
                      ),
                    ],
                  ),
            actions: _isSaving
                ? []
                : [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final address = addressController.text.trim();
                        if (address.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Address cannot be empty')),
                          );
                          return;
                        }

                        setDialogState(() => _isSaving = true);

                        try {
                          final resp = await Api.put('/auth/customer/profile/${Session.userId}', {
                            'name': Session.name ?? 'Customer',
                            'email': Session.email ?? '',
                            'phone': Session.phone ?? '9999999999',
                            'address': address,
                          });

                          if (resp['status'] == 200) {
                            setState(() {
                              Session.address = address;
                            });
                            await Session.saveToDisk();

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Address saved successfully!')),
                              );
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(resp['data']['message'] ?? 'Failed to save address')),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Connection error, try again.')),
                            );
                          }
                        } finally {
                          setDialogState(() => _isSaving = false);
                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text('Save'),
                    ),
                  ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const FixigoAppBar(
        title: 'My Profile',
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            _ProfileHeader(),
            const SizedBox(height: 16),
            // Menu groups
            _MenuGroup(
              title: 'Account',
              items: [
                _MenuItem(
                  Icons.person_rounded,
                  'Personal Information',
                  onTap: () => _showPersonalInfoDialog(context),
                ),
                _MenuItem(
                  Icons.location_on_rounded,
                  'Saved Addresses',
                  onTap: () => _showSavedAddressDialog(context),
                ),
                _MenuItem(
                  Icons.payment_rounded,
                  'Payment Methods',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payment profiles are safely managed at checkout.')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MenuGroup(
              title: 'Services',
              items: [
                _MenuItem(
                  Icons.history_rounded,
                  'Repair History',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WarrantyScreen(initialIndex: 1),
                      ),
                    );
                  },
                ),
                _MenuItem(
                  Icons.verified_rounded,
                  'My Warranties',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WarrantyScreen(initialIndex: 0),
                      ),
                    );
                  },
                ),
                _MenuItem(
                  Icons.sell_rounded,
                  'My Listings (Resell)',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CustomerListingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MenuGroup(
              title: 'Support & Legal',
              items: [
                _MenuItem(
                  Icons.headset_mic_rounded,
                  'Customer Support',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Support line: 1800-FIX-IGO (Mon-Sat)')),
                    );
                  },
                ),
                _MenuItem(
                  Icons.star_rounded,
                  'Rate the App',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thank you for rating us 5 stars!')),
                    );
                  },
                ),
                _MenuItem(
                  Icons.share_rounded,
                  'Refer & Earn ₹200',
                  isHighlight: true,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Referral link copied to clipboard!')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Session.clear();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RoleSelectionScreen(),
                      ),
                    );
                  }
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
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      color: AppColors.surface,
      child: Column(
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
                Session.name != null && Session.name!.isNotEmpty
                    ? Session.name!.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
                    : 'U',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(Session.name ?? 'User',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(Session.email ?? '',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
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
