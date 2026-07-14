import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'api.dart';

class AdminTechniciansScreen extends StatefulWidget {
  const AdminTechniciansScreen({super.key});

  @override
  State<AdminTechniciansScreen> createState() => _AdminTechniciansScreenState();
}

class _AdminTechniciansScreenState extends State<AdminTechniciansScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _error = '';
  List<dynamic> _allTechnicians = [];
  List<dynamic> _pendingTechnicians = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchTechnicians();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchTechnicians() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final response = await Api.get('/admin/technicians');
      if (response['status'] == 200) {
        final List<dynamic> data = response['data'] ?? [];
        setState(() {
          _allTechnicians = data;
          _pendingTechnicians = data.where((t) {
            final overall = t['verification_status'] == 'pending';
            final aadharPending = t['aadhar_verification_status'] == 'pending';
            final panPending = t['pan_verification_status'] == 'pending';
            return overall || aadharPending || panPending;
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['data']['message'] ?? 'Failed to load technicians';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Connection error. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateProofStatus(int technicianId, String type, String action) async {
    try {
      final endpoint = action == 'verify' 
          ? '/admin/technicians/$technicianId/verify/$type'
          : '/admin/technicians/$technicianId/reject/$type';
          
      final response = await Api.patch(endpoint, {});
      
      if (response['status'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${type == 'aadhar' ? 'Aadhaar' : 'PAN'} $action successfully')),
        );
        _fetchTechnicians(); // refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['data']['message'] ?? 'Action failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Please try again.')),
      );
    }
  }

  String _getInitial(dynamic name) {
    if (name == null) return 'U';
    String n = name.toString().trim();
    if (n.isEmpty) return 'U';
    return n.substring(0, 1).toUpperCase();
  }

  Widget _buildDocVerificationRow(dynamic t, String type, String title) {
    final String docUrl = t['${type}_card_url'] ?? '';
    final String docStatus = t['${type}_verification_status'] ?? 'unuploaded';

    Color statusColor = Colors.grey;
    if (docStatus == 'verified') statusColor = Colors.green;
    else if (docStatus == 'pending') statusColor = Colors.orange;
    else if (docStatus == 'rejected') statusColor = Colors.red;

    final baseUrl = Api.baseUrl;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  docStatus.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (docUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                docUrl.startsWith('http') ? docUrl : '$baseUrl$docUrl',
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ),
            if (docStatus == 'pending') ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject', style: TextStyle(fontSize: 12)),
                    onPressed: () => _updateProofStatus(t['id'], type, 'reject'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    icon: const Icon(Icons.check, size: 16, color: Colors.white),
                    label: const Text('Approve', style: TextStyle(color: Colors.white, fontSize: 12)),
                    onPressed: () => _updateProofStatus(t['id'], type, 'verify'),
                  ),
                ],
              ),
            ],
          ] else
            const Text(
              'No document uploaded yet.',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildTechnicianList(List<dynamic> techs, bool actable) {
    if (techs.isEmpty) {
      return const Center(child: Text('No technicians found', style: TextStyle(color: AppColors.textSecondary)));
    }
    
    return RefreshIndicator(
      onRefresh: _fetchTechnicians,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: techs.length,
        itemBuilder: (context, index) {
          final t = techs[index];
          final String status = t['verification_status'] ?? 'unknown';
          
          Color statusColor = Colors.grey;
          IconData statusIcon = Icons.help_outline;
          if (status == 'verified') {
            statusColor = Colors.green;
            statusIcon = Icons.verified;
          } else if (status == 'pending') {
            statusColor = Colors.orange;
            statusIcon = Icons.pending_actions;
          } else if (status == 'rejected') {
            statusColor = Colors.red;
            statusIcon = Icons.cancel;
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Prevents layout issues
              children: [
                ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(_getInitial(t['name']), 
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)
                    ),
                  ),
                  title: Text(t['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(status.toUpperCase(), style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  childrenPadding: const EdgeInsets.all(16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _infoRow(Icons.email_outlined, t['email'] ?? 'N/A'),
                    const SizedBox(height: 8),
                    _infoRow(Icons.phone_outlined, t['phone'] ?? 'N/A'),
                    const SizedBox(height: 8),
                    _infoRow(Icons.build_circle_outlined, 'Skills: ${t['skills'] ?? 'N/A'}'),
                    const SizedBox(height: 8),
                    _infoRow(Icons.work_history_outlined, 'Experience: ${t['experience'] ?? 0} years'),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    const Text('Verification Proofs:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    _buildDocVerificationRow(t, 'aadhar', 'Aadhaar Card'),
                    _buildDocVerificationRow(t, 'pan', 'PAN Card'),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(color: AppColors.textPrimary))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            const Tab(text: 'All Technicians'),
            Tab(text: 'Pending (${_pendingTechnicians.length})'),
          ],
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error.isNotEmpty
                  ? Center(child: Text(_error, style: const TextStyle(color: AppColors.error)))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTechnicianList(_allTechnicians, false),
                        _buildTechnicianList(_pendingTechnicians, true),
                      ],
                    ),
        ),
      ],
    );
  }
}
