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
          _pendingTechnicians = data.where((t) => t['verification_status'] == 'pending').toList();
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

  Future<void> _updateStatus(int technicianId, String newStatus) async {
    try {
      final endpoint = newStatus == 'verified' 
          ? '/admin/technicians/$technicianId/verify'
          : '/admin/technicians/$technicianId/reject';
          
      final response = await Api.patch(endpoint, {});
      
      if (response['status'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Technician $newStatus successfully')),
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
                  ],
                ),
                if (status == 'pending') ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                            icon: const Icon(Icons.close),
                            label: const Text('Reject'),
                            onPressed: () => _updateStatus(t['id'], 'rejected'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            icon: const Icon(Icons.check, color: Colors.white),
                            label: const Text('Approve', style: TextStyle(color: Colors.white)),
                            onPressed: () => _updateStatus(t['id'], 'verified'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]
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
