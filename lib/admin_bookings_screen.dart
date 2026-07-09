import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'api.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  bool _isLoading = true;
  String _error = '';
  List<dynamic> _allBookings = [];
  String _filterStatus = 'All';

  final List<String> _statuses = ['All', 'pending', 'assigned', 'in_progress', 'completed', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final response = await Api.get('/admin/bookings');
      if (response['status'] == 200) {
        setState(() {
          _allBookings = response['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['data']['message'] ?? 'Failed to load bookings';
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'assigned':
      case 'in_progress':
        return Colors.blue;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_error, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchBookings, child: const Text('Retry')),
          ],
        ),
      );
    }

    final filteredBookings = _filterStatus == 'All'
        ? _allBookings
        : _allBookings.where((b) => b['status'] == _filterStatus).toList();

    return Column(
      children: [
        // Filter Chips
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _statuses.length,
            itemBuilder: (context, index) {
              final status = _statuses[index];
              final isSelected = _filterStatus == status;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(status.toUpperCase(),
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      )),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.grey.shade200,
                  onSelected: (selected) {
                    setState(() {
                      _filterStatus = status;
                    });
                  },
                ),
              );
            },
          ),
        ),

        // List View
        Expanded(
          child: filteredBookings.isEmpty
              ? const Center(child: Text('No bookings found', style: TextStyle(color: AppColors.textSecondary)))
              : RefreshIndicator(
                  onRefresh: _fetchBookings,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredBookings.length,
                    itemBuilder: (context, index) {
                      final b = filteredBookings[index];
                      final status = b['status'] ?? 'unknown';
                      final color = _getStatusColor(status);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ExpansionTile(
                          iconColor: AppColors.primary,
                          title: Text(
                            b['appliance_type'] ?? 'Unknown Appliance',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('ID: #${b['id']}'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                          ),
                          childrenPadding: const EdgeInsets.all(16),
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                            _buildInfoRow(Icons.person, 'Customer: ${b['customer_name'] ?? 'N/A'}'),
                            const SizedBox(height: 8),
                            _buildInfoRow(Icons.engineering, 'Tech: ${b['technician_name'] ?? 'Unassigned'}'),
                            const SizedBox(height: 8),
                            _buildInfoRow(Icons.location_on, b['location'] ?? 'N/A'),
                            const SizedBox(height: 8),
                            _buildInfoRow(Icons.calendar_today, 'Preferred: ${b['preferred_date'] ?? 'N/A'}'),
                            
                            // Dynamic Estimate Range
                            if (b['estimated_price_min'] != null && b['estimated_price_max'] != null) ...[
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                Icons.price_change_rounded,
                                'Estimate: ₹${double.tryParse(b['estimated_price_min'].toString())?.toStringAsFixed(0)} – ₹${double.tryParse(b['estimated_price_max'].toString())?.toStringAsFixed(0)}',
                              ),
                            ],
                            
                            // Payment details
                            if (b['booking_fee'] != null) ...[
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                Icons.payment_rounded,
                                'Booking Fee: ₹${double.tryParse(b['booking_fee'].toString())?.toStringAsFixed(0)} (${b['payment_status'] ?? 'paid'})',
                              ),
                            ],
                            if (b['razorpay_payment_id'] != null) ...[
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                Icons.receipt_rounded,
                                'Razorpay ID: ${b['razorpay_payment_id']}',
                              ),
                            ],
                            
                            const SizedBox(height: 12),
                            const Text('Issue Description:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(b['issue_description'] ?? 'No description provided',
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                
                            // Cancellation details
                            if (status == 'cancelled' && b['cancellation_reason'] != null && b['cancellation_reason'].toString().isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.shade100),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Cancellation Reason: ${b['cancellation_reason']}',
                                        style: TextStyle(color: Colors.red.shade900, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
