import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'app_theme.dart';
import 'common_widgets.dart';
import 'role_selection.dart';
import 'api.dart';
import 'session.dart';
import 'location_picker_screen.dart';
import 'fixigo_logout_dialog.dart';

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
  List<dynamic> _reviews = [];
  String _aadharCardUrl = '';
  String _aadharVerificationStatus = 'unuploaded';
  String _panCardUrl = '';
  String _panVerificationStatus = 'unuploaded';
  String _workSchedule = '';

  final List<String> _availableSkills = const [
    'Air Conditioner',
    'Refrigerator',
    'Washing Machine',
    'Television',
    'Laptop & PC',
    'Water Purifier',
    'Water Heater / Geyser',
    'Kitchen Appliances',
    'Electrical Services'
  ];

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
          _reviews = data['reviews'] ?? [];
          _aadharCardUrl = data['aadharCardUrl'] ?? '';
          _aadharVerificationStatus = data['aadharVerificationStatus'] ?? 'unuploaded';
          _panCardUrl = data['panCardUrl'] ?? '';
          _panVerificationStatus = data['panVerificationStatus'] ?? 'unuploaded';
          _workSchedule = data['workSchedule'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showEditAddressDialog() async {
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
        _address = result.address;
        Session.address = result.address;
        Session.latitude = result.latitude;
        Session.longitude = result.longitude;
      });
      _updateProfileAddress(result.address);
    }
  }

  Future<void> _updateProfileAddress(String newAddress) async {
    setState(() => _isLoading = true);
    try {
      final resp = await Api.put('/auth/technician/profile/${Session.userId}', {
        'name': _name,
        'email': _email,
        'phone': _phone,
        'address': newAddress,
        'skills': _skills.join(', '),
        'experience': _experience,
        'workSchedule': _workSchedule,
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

  Future<void> _uploadProof(String type) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _isLoading = true);
    try {
      print('Uploading $type proof from: ${pickedFile.path}');
      
      final resp = await Api.multipartPost(
        '/auth/technician/upload-proof',
        {'type': type},
        'id_proof',
        pickedFile.path,
      );

      print('Upload response: $resp');

      if (resp['status'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${type == 'aadhar' ? 'Aadhaar' : 'PAN'} Card uploaded successfully!')),
        );
        await _fetchProfile();
      } else {
        final message = resp['data']?['message'] ?? 'Failed to upload proof';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() => _isLoading = false);
      }
    } catch (e, stackTrace) {
      print('Upload error: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Server error uploading proof. Please check your connection and try again. Error: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  void _showPersonalDetailsDialog() {
    final nameController = TextEditingController(text: _name);
    final phoneController = TextEditingController(text: _phone);
    final emailController = TextEditingController(text: _email);
    final expController = TextEditingController(text: _experience.toString());
    List<String> tempSkills = List.from(_skills);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Personal Details', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
                TextField(controller: expController, decoration: const InputDecoration(labelText: 'Experience (Years)'), keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                const Text('Select Skills:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _availableSkills.map((s) {
                    final selected = tempSkills.contains(s);
                    return ChoiceChip(
                      label: Text(s, style: const TextStyle(fontSize: 11)),
                      selected: selected,
                      onSelected: (val) {
                        setDialogState(() {
                          if (val) {
                            tempSkills.add(s);
                          } else {
                            tempSkills.remove(s);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                try {
                  final resp = await Api.put('/auth/technician/profile/${Session.userId}', {
                    'name': nameController.text.trim(),
                    'email': emailController.text.trim(),
                    'phone': phoneController.text.trim(),
                    'address': _address,
                    'skills': tempSkills.join(', '),
                    'experience': int.tryParse(expController.text.trim()) ?? 0,
                    'workSchedule': _workSchedule,
                  });
                  if (resp['status'] == 200) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
                    _fetchProfile();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp['data']['message'] ?? 'Failed to update')));
                    setState(() => _isLoading = false);
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  setState(() => _isLoading = false);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showWorkScheduleDialog() {
    final scheduleController = TextEditingController(text: _workSchedule.isNotEmpty ? _workSchedule : '9:00 AM - 6:00 PM (Mon-Sat)');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Work Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: scheduleController,
          decoration: const InputDecoration(hintText: 'e.g. 9:00 AM - 6:00 PM (Mon-Sat)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                final resp = await Api.put('/auth/technician/profile/${Session.userId}', {
                  'name': _name,
                  'email': _email,
                  'phone': _phone,
                  'address': _address,
                  'skills': _skills.join(', '),
                  'experience': _experience,
                  'workSchedule': scheduleController.text.trim(),
                });
                if (resp['status'] == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Work schedule updated')));
                  _fetchProfile();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp['data']['message'] ?? 'Failed to update')));
                  setState(() => _isLoading = false);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
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
                child: _VerificationCard(
                  status: _verificationStatus,
                  aadharStatus: _aadharVerificationStatus,
                  panStatus: _panVerificationStatus,
                  onUploadAadhar: () => _uploadProof('aadhar'),
                  onUploadPan: () => _uploadProof('pan'),
                ),
              ),
              const SizedBox(height: 16),
              // Reviews
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _ReviewsCard(reviews: _reviews),
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
                onItemTap: (item) {
                  if (item == 'Personal Details') {
                    _showPersonalDetailsDialog();
                  } else if (item == 'Work Schedule') {
                    _showWorkScheduleDialog();
                  }
                },
              ),
              const SizedBox(height: 12),
              _MenuGroup(
                title: 'Support',
                items: const [
                  ('Help & Support', Icons.help_rounded),
                  ('Report an Issue', Icons.flag_rounded),
                  ('Terms & Conditions', Icons.description_rounded),
                ],
                onItemTap: (item) {},
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showFixigoLogoutDialog(context);

                    if (confirm == true) {
                      await Session.clear();
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RoleSelectionScreen()),
                        );
                      }
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
  final String aadharStatus;
  final String panStatus;
  final VoidCallback onUploadAadhar;
  final VoidCallback onUploadPan;

  const _VerificationCard({
    required this.status,
    required this.aadharStatus,
    required this.panStatus,
    required this.onUploadAadhar,
    required this.onUploadPan,
  });

  Widget _buildDocRow(String title, String docStatus, VoidCallback onUpload) {
    Color statusColor = Colors.grey;
    IconData icon = Icons.help_outline_rounded;
    Widget? actionWidget;

    if (docStatus == 'verified') {
      statusColor = AppColors.success;
      icon = Icons.check_circle_rounded;
    } else if (docStatus == 'pending') {
      statusColor = Colors.orange;
      icon = Icons.hourglass_empty_rounded;
      actionWidget = const Text('Awaiting Verification',
          style: TextStyle(
              fontSize: 11, fontStyle: FontStyle.italic, color: Colors.orange));
    } else if (docStatus == 'rejected') {
      statusColor = AppColors.error;
      icon = Icons.cancel_rounded;
      actionWidget = TextButton.icon(
        onPressed: onUpload,
        icon: const Icon(Icons.upload_file_rounded, size: 14),
        label: const Text('Re-upload', style: TextStyle(fontSize: 11)),
        style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
      );
    } else {
      statusColor = AppColors.textTertiary;
      icon = Icons.radio_button_unchecked_rounded;
      actionWidget = TextButton.icon(
        onPressed: onUpload,
        icon: const Icon(Icons.upload_file_rounded, size: 14),
        label: const Text('Upload', style: TextStyle(fontSize: 11)),
        style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: statusColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                if (docStatus == 'rejected')
                  const Text('Rejected by Admin',
                      style: TextStyle(fontSize: 10, color: AppColors.error)),
              ],
            ),
          ),
          if (actionWidget != null) actionWidget,
        ],
      ),
    );
  }

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
          const SizedBox(height: 16),
          _buildDocRow('Aadhaar Card', aadharStatus, onUploadAadhar),
          const Divider(height: 12),
          _buildDocRow('PAN Card', panStatus, onUploadPan),
        ],
      ),
    );
  }
}

class _ReviewsCard extends StatelessWidget {
  final List<dynamic> reviews;

  const _ReviewsCard({required this.reviews});

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
            children: const [
              Text('Recent Reviews',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              Text('View all',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          if (reviews.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No reviews yet. Reviews from customers will appear here.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...reviews.map((r) {
              final name = r['customer_name'] ?? 'Customer';
              final rating = r['rating']?.toString() ?? '5.0';
              final comment = r['comment'] ?? '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                              color: AppColors.primarySurface,
                              shape: BoxShape.circle),
                          child: Center(
                              child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'C',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary))),
                        ),
                        const SizedBox(width: 10),
                        Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        const Spacer(),
                        Icon(Icons.star_rounded,
                            color: Colors.amber[600], size: 14),
                        const SizedBox(width: 2),
                        Text(rating,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 12)),
                      ],
                    ),
                    if (comment.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(comment,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.4)),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  final String title;
  final List<(String, IconData)> items;
  final ValueChanged<String>? onItemTap;

  const _MenuGroup({
    required this.title,
    required this.items,
    this.onItemTap,
  });

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
                    onTap: () => onItemTap?.call(item.$1),
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
