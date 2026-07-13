import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'api.dart';
import 'common_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdminResellRequestsScreen extends StatefulWidget {
  const AdminResellRequestsScreen({super.key});

  @override
  State<AdminResellRequestsScreen> createState() => _AdminResellRequestsScreenState();
}

class _AdminResellRequestsScreenState extends State<AdminResellRequestsScreen> {
  bool _isLoading = true;
  String _error = '';
  List<dynamic> _allRequests = [];
  String _filterStatus = 'All';

  final List<String> _statuses = ['All', 'pending', 'approved', 'rejected', 'sold'];

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final response = await Api.get('/admin/resale-requests');
      if (response['status'] == 200) {
        setState(() {
          _allRequests = response['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['data']['message'] ?? 'Failed to load resale requests';
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

  Future<void> _updateStatus(int id, String status) async {
    try {
      final endpoint = status == 'approved' ? 'approve' : 'reject';
      final response = await Api.patch('/admin/resale-requests/$id/$endpoint', {});
      if (response['status'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request $status successfully.')),
        );
        _fetchRequests();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['data']['message'] ?? 'Failed to update request status.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _sendNotes(int id, String? currentNotes, String currentStatus) async {
    final notesController = TextEditingController(text: currentNotes);
    String selectedStatus = currentStatus;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: const Text('Update Resell Request Info'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Change Status:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: selectedStatus,
                    isExpanded: true,
                    items: ['pending', 'approved', 'rejected', 'sold'].map((st) {
                      return DropdownMenuItem<String>(
                        value: st,
                        child: Text(st.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedStatus = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Admin Notes / Send Info:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Enter notes about pricing, pickup details, valuation, etc.',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogCtx);
                    // Show progress
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const Center(child: CircularProgressIndicator()),
                    );

                    try {
                      final response = await Api.patch('/admin/resale-requests/$id', {
                        'admin_notes': notesController.text.trim(),
                        'status': selectedStatus,
                      });
                      
                      if (mounted) Navigator.pop(context); // Pop progress

                      if (response['status'] == 200) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Resale details updated successfully.')),
                        );
                        _fetchRequests();
                      } else {
                        final msg = response['data']?['message'] ?? 'Failed to update details';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $msg')),
                        );
                      }
                    } catch (e) {
                      if (mounted) Navigator.pop(context); // Pop progress
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Connection error: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Submit', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'sold':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredRequests = _filterStatus == 'All'
        ? _allRequests
        : _allRequests.where((r) => r['status'] == _filterStatus).toList();

    return Column(
      children: [
        // Status filter bar
        Container(
          height: 50,
          color: Colors.white,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _statuses.length,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemBuilder: (ctx, i) {
              final status = _statuses[i];
              final isSelected = _filterStatus == status;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(status.toUpperCase()),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _filterStatus = status;
                    });
                  },
                  selectedColor: AppColors.primarySurface,
                  backgroundColor: Colors.grey.shade100,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_error, style: const TextStyle(color: AppColors.error)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _fetchRequests,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : filteredRequests.isEmpty
                      ? const Center(
                          child: Text(
                            'No resale requests found.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchRequests,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredRequests.length,
                            itemBuilder: (ctx, idx) {
                              final r = filteredRequests[idx];
                              final isApproved = r['status'] == 'approved';
                              final isRejected = r['status'] == 'rejected';
                              final isSold = r['status'] == 'sold';
                              
                              final showApproveReject = r['status'] == 'pending';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${r['appliance_type']} (${r['brand'] ?? 'Unknown Brand'})',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(r['status']).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              r['status'].toString().toUpperCase(),
                                              style: TextStyle(
                                                color: _getStatusColor(r['status']),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // Image display if available
                                      if (r['image_url'] != null && r['image_url'].toString().isNotEmpty) ...[
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: CachedNetworkImage(
                                            imageUrl: Api.baseUrl + r['image_url'].toString(),
                                            height: 150,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            placeholder: (ctx, url) => Container(
                                              height: 150,
                                              color: Colors.grey.shade100,
                                              child: const Center(child: CircularProgressIndicator()),
                                            ),
                                            errorWidget: (ctx, url, err) => Container(
                                              height: 150,
                                              color: Colors.grey.shade100,
                                              child: const Center(
                                                child: Icon(Icons.broken_image_outlined, color: Colors.grey),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                      ],

                                      // Details section
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buildDetailCol('Expected Price', '₹${r['expected_price'] ?? 0}'),
                                          _buildDetailCol('Est. Value', '₹${r['estimated_value'] ?? 0}'),
                                          _buildDetailCol('Original Price', '₹${r['original_price'] ?? 0}'),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buildDetailCol('Age', '${r['age_years'] ?? 0} years'),
                                          _buildDetailCol('Working', r['working_status'] ?? 'N/A'),
                                          _buildDetailCol('Condition', r['cosmetic_condition'] ?? 'N/A'),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // Checklist (Bill, Box, Accessories)
                                      Row(
                                        children: [
                                          _buildCheckIcon('Bill', r['has_bill']),
                                          const SizedBox(width: 12),
                                          _buildCheckIcon('Box', r['has_box']),
                                          const SizedBox(width: 12),
                                          _buildCheckIcon('Accessories', r['has_accessories']),
                                        ],
                                      ),
                                      const Divider(height: 24),

                                      // User and address info
                                      const Text('CONTACT DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textTertiary)),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Name: ${r['customer_name'] ?? 'Demo User'}\n'
                                        'Phone: ${r['customer_phone'] ?? '9999999999'}\n'
                                        'Address: ${r['address'] ?? 'Koramangala, Bengaluru'}',
                                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                                      ),

                                      // Admin notes if exist
                                      if (r['admin_notes'] != null && r['admin_notes'].toString().trim().isNotEmpty) ...[
                                        const Divider(height: 24),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.amber.shade200),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'ADMIN INFO / NOTES:',
                                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                r['admin_notes'],
                                                style: TextStyle(fontSize: 13, color: Colors.amber.shade900, height: 1.3),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],

                                      const Divider(height: 24),

                                      // Actions
                                      Row(
                                        children: [
                                          if (showApproveReject) ...[
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: () => _updateStatus(r['id'], 'rejected'),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.red,
                                                  side: const BorderSide(color: Colors.red),
                                                ),
                                                child: const Text('Reject'),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () => _updateStatus(r['id'], 'approved'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                ),
                                                child: const Text('Approve', style: TextStyle(color: Colors.white)),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () => _sendNotes(r['id'], r['admin_notes'], r['status']),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.primary,
                                              ),
                                              child: const Text('Send Info', style: TextStyle(color: Colors.white)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildDetailCol(String title, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildCheckIcon(String title, dynamic hasVal) {
    final bool yes = hasVal == true || hasVal == 1 || hasVal == '1';
    return Row(
      children: [
        Icon(
          yes ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: yes ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: yes ? Colors.green : Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
