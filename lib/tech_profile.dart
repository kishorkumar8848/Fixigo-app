import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'common_widgets.dart';
import 'role_selection.dart';
import 'api.dart';
import 'session.dart';

class TechProfileScreen extends StatefulWidget {
  const TechProfileScreen({super.key});

  @override
  State<TechProfileScreen> createState() => _TechProfileScreenState();
}

class _TechProfileScreenState extends State<TechProfileScreen> {
  bool _isLoading = true;
  String _name = '';
  String _email = '';
  String _phone = '';
  List<String> _skills = [];
  int _experience = 0;
  double _rating = 0.0;
  String _verificationStatus = 'pending';
  int _totalJobs = 0;
  double _totalEarnings = 0.0;
  String _address = '';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final resp = await Api.get('/auth/technician/profile/${Session.userId}');
      if (resp['status'] == 200) {
        final data = resp['data'];
        setState(() {
          _name = data['name'] ?? '';
          _email = data['email'] ?? '';
          _phone = data['phone'] ?? '';
          final skillsStr = data['skills'] ?? '';
          _skills = skillsStr.isNotEmpty
              ? skillsStr.split(',').map((s) => s.toString().trim()).toList()
              : [];
          _experience = int.tryParse(data['experience']?.toString() ?? '0') ?? 0;
          _rating = double.tryParse(data['rating']?.toString() ?? '0') ?? 0.0;
          _verificationStatus = data['verificationStatus'] ?? 'pending';
          _totalJobs = int.tryParse(data['totalJobs']?.toString() ?? '0') ?? 0;
          _totalEarnings = double.tryParse(data['totalEarnings']?.toString() ?? '0') ?? 0.0;
          _address = data['address'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showEditAddressDialog() {
    final addressController = TextEditingController(text: _address);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Service Address'),
        content: TextField(
          controller: addressController,
          decoration: InputDecoration(
            hintText: 'Enter your service address',
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
              _updateProfileAddress(addressController.text.trim());
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestAndFetchLocation(TextEditingController controller) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_on_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Location Permission'),
          ],
        ),
        content: const Text(
          'Allow "Fixigo" to access this device\'s location to find doorstep repairs and assignments nearby?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Deny'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showLocationFetchingProgress(controller);
            },
            child: const Text('Allow'),
          ),
        ],
      ),
    );
  }

  void _showLocationFetchingProgress(TextEditingController controller) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text('Fetching current GPS coordinates...')),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pop(context);
      final neighborhoods = [
        'Indiranagar, Bengaluru',
        'Koramangala, Bengaluru',
        'HSR Layout, Bengaluru',
        'Jayanagar, Bengaluru',
        'Whitefield, Bengaluru',
      ];
      final randomNeighborhood = neighborhoods[DateTime.now().millisecond % neighborhoods.length];
      controller.text = randomNeighborhood;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Auto-filled current location: $randomNeighborhood')),
      );
    });
  }

  Future<void> _updateProfileAddress(String newAddress) async {
    setState(() => _isLoading = true);
    try {
      final resp = await Api.put('/auth/technician/profile/${Session.userId}', {
        'name': _name,
        'email': _email,
        'phone': _phone,
        'address': newAddress,
      });
      if (resp['status'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address updated successfully')),
        );
        await _fetchProfile();
      } else {
        final message = resp['data']['message'] ?? 'Failed to update address';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: FixigoAppBar(
        title: 'My Profile',
        actions: [
          IconButton(icon: const Icon(Icons.share_rounded), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _TechProfileHeader(
                name: _name,
                skills: _skills,
                verificationStatus: _verificationStatus,
                experience: _experience,
                rating: _rating,
              ),
              const SizedBox(height: 16),
              // Stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                        child: StatCard(
                            label: 'Total Jobs',
                            value: '$_totalJobs',
                            icon: Icons.work_rounded,
                            color: AppColors.secondary,
                            bgColor: AppColors.secondarySurface)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: StatCard(
                            label: 'Rating',
                            value: _rating.toStringAsFixed(1),
                            icon: Icons.star_rounded,
                            color: const Color(0xFFFF6F00),
                            bgColor: const Color(0xFFFFF8E1))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: StatCard(
                            label: 'Earnings',
                            value: '₹${_totalEarnings.toStringAsFixed(0)}',
                            icon: Icons.currency_rupee_rounded,
                            color: AppColors.success,
                            bgColor: AppColors.successLight)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Skills
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SkillsCard(skills: _skills),
              ),
              const SizedBox(height: 16),
              // Address if available
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
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
                          const Text('Service Address',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          GestureDetector(
                            onTap: _showEditAddressDialog,
                            child: const Icon(Icons.edit_rounded, size: 16, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _address.isNotEmpty ? _address : 'Not set. Tap edit to set address.',
                              style: TextStyle(
                                fontSize: 13,
                                color: _address.isNotEmpty ? AppColors.textSecondary : Colors.red.shade400,
                                fontStyle: _address.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Verification
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _VerificationCard(status: _verificationStatus),
              ),
              const SizedBox(height: 16),
              // Reviews
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _ReviewsCard(),
              ),
              const SizedBox(height: 16),
              // Menu
              _MenuGroup(
                title: 'Account',
                items: const [
                  ('Personal Details', Icons.person_rounded),
                  ('Bank Account', Icons.account_balance_rounded),
                  ('Work Schedule', Icons.calendar_today_rounded),
                ],
              ),
              const SizedBox(height: 12),
              _MenuGroup(
                title: 'Support',
                items: const [
                  ('Help & Support', Icons.help_rounded),
                  ('Report an Issue', Icons.flag_rounded),
                  ('Terms & Conditions', Icons.description_rounded),
                ],
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: OutlinedButton.icon(
                  onPressed: () {
                    Session.token = null;
                    Session.role = null;
                    Session.userId = null;
                    Session.name = null;
                    Session.email = null;
                    Session.address = null;
                    Session.latitude = null;
                    Session.longitude = null;
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _TechProfileHeader extends StatelessWidget {
  final String name;
  final List<String> skills;
  final String verificationStatus;
  final int experience;
  final double rating;

  const _TechProfileHeader({
    required this.name,
    required this.skills,
    required this.verificationStatus,
    required this.experience,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty
        ? name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'Tech';
    final primarySkill = skills.isNotEmpty ? skills.first : 'Specialist';

    Widget statusBadge;
    if (verificationStatus == 'verified') {
      statusBadge = StatusBadge.success('Verified');
    } else if (verificationStatus == 'rejected') {
      statusBadge = StatusBadge.error('Rejected');
    } else {
      statusBadge = StatusBadge.warning('Pending');
    }

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
                  gradient: LinearGradient(
                    colors: [Color(0xFF00695C), Color(0xFF00897B)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: verificationStatus == 'verified' ? AppColors.success : AppColors.warning,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(verificationStatus == 'verified' ? Icons.check_rounded : Icons.hourglass_empty_rounded,
                      color: Colors.white, size: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('$primarySkill Specialist',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              statusBadge,
              const SizedBox(width: 8),
              if (experience >= 5) StatusBadge.info('Senior Tech'),
              const SizedBox(width: 8),
              StatusBadge(
                text: '$experience yrs exp',
                color: AppColors.warning,
                bgColor: AppColors.warningLight,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
                5,
                (i) => Icon(
                    i < rating.floor() ? Icons.star_rounded : (i < rating ? Icons.star_half_rounded : Icons.star_border_rounded),
                    color: Colors.amber[600],
                    size: 20)),
          ),
          Text('${rating.toStringAsFixed(1)} out of 5',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _SkillsCard extends StatelessWidget {
  final List<String> skills;
  const _SkillsCard({required this.skills});

  @override
  Widget build(BuildContext context) {
    final displaySkills = skills.isNotEmpty ? skills : ['General Appliance Repair'];

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
          const Text('Skills & Expertise',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: displaySkills
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.secondarySurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.secondary.withOpacity(0.3)),
                      ),
                      child: Text(s,
                          style: const TextStyle(
                              color: AppColors.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  final String status;
  const _VerificationCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final docs = [
      ('Aadhar Card', true),
      ('PAN Card', true),
      ('Police Verification', status == 'verified'),
      ('Skill Certificate', status == 'verified'),
    ];

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
            children: [
              const Text('Verification Status',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              if (status == 'verified')
                StatusBadge.success('Fully Verified')
              else if (status == 'rejected')
                StatusBadge.error('Rejected')
              else
                StatusBadge.warning('Pending Approval'),
            ],
          ),
          const SizedBox(height: 12),
          ...docs.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      d.$2 ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: d.$2 ? AppColors.success : AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(d.$1, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _ReviewsCard extends StatelessWidget {
  final _reviews = const [
    (
      'Priya Sharma',
      '5.0',
      'Excellent service! Rajesh was very professional and fixed the AC perfectly.'
    ),
    ('Karan Mehta', '4.5', 'Good work, came on time. Would recommend.'),
  ];

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
              const Text('Recent Reviews',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const Text('View all',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          ..._reviews.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              shape: BoxShape.circle),
                          child: Center(
                              child: Text(r.$1[0],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary))),
                        ),
                        const SizedBox(width: 10),
                        Text(r.$1,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        const Spacer(),
                        Icon(Icons.star_rounded,
                            color: Colors.amber[600], size: 14),
                        const SizedBox(width: 2),
                        Text(r.$2,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(r.$3,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  final String title;
  final List<(String, IconData)> items;

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
                    leading: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.secondarySurface,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child:
                          Icon(item.$2, size: 18, color: AppColors.secondary),
                    ),
                    title: Text(item.$1,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: AppColors.textTertiary),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    onTap: () {},
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
