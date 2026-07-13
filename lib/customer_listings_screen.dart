import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'common_widgets.dart';
import 'session.dart';
import 'api.dart';

class CustomerListingsScreen extends StatefulWidget {
  const CustomerListingsScreen({super.key});

  @override
  State<CustomerListingsScreen> createState() => _CustomerListingsScreenState();
}

class _CustomerListingsScreenState extends State<CustomerListingsScreen> {
  List<dynamic> _listings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchListings();
  }

  Future<void> _fetchListings() async {
    if (Session.userId == null) {
      setState(() {
        _isLoading = false;
        _error = 'User not logged in';
      });
      return;
    }

    try {
      final resp = await Api.get('/resale/${Session.userId}');
      if (resp['status'] == 200 && resp['data'] is List) {
        setState(() {
          _listings = resp['data'];
          _isLoading = false;
          _error = null;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load resale requests';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to connect to server';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const FixigoAppBar(
        title: 'My Resell Listings',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _isLoading = true);
                          _fetchListings();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _listings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sell_outlined, size: 64, color: AppColors.textTertiary),
                          const SizedBox(height: 16),
                          const Text(
                            'No resale requests yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'List your old appliances and get cash!',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchListings,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _listings.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (ctx, i) {
                          final item = _listings[i];
                          final status = item['status'] ?? 'pending';
                          final dateStr = item['created_at'] != null
                              ? DateTime.parse(item['created_at']).toLocal().toString().substring(0, 16)
                              : '';

                          Color statusColor = Colors.orange;
                          if (status == 'approved' || status == 'accepted') {
                            statusColor = AppColors.success;
                          } else if (status == 'rejected') {
                            statusColor = AppColors.error;
                          }

                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top header
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        item['appliance_type'] ?? 'Appliance',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          status.toString().toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: statusColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                                // Body info
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (item['image_url'] != null && item['image_url'].toString().isNotEmpty)
                                        Container(
                                          width: 70,
                                          height: 70,
                                          margin: const EdgeInsets.only(right: 16),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            image: DecorationImage(
                                              image: NetworkImage(
                                                Api.baseUrl + item['image_url'],
                                              ),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (item['brand'] != null)
                                              Text(
                                                'Brand: ${item['brand']}',
                                                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                              ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Expected Price: ₹${item['expected_price']}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.success,
                                              ),
                                            ),
                                            if (item['age_years'] != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                'Age: ${item['age_years']} years',
                                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                              ),
                                            ],
                                            if (dateStr.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                'Submitted: $dateStr',
                                                style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (item['admin_notes'] != null && item['admin_notes'].toString().isNotEmpty) ...[
                                  const Divider(height: 1),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    color: Colors.amber.shade50.withOpacity(0.4),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(Icons.info_outline_rounded, color: Colors.orange, size: 16),
                                            SizedBox(width: 6),
                                            Text(
                                              'Admin Notes',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          item['admin_notes'],
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                            height: 1.4,
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
    );
  }
}
