import 'dart:convert';

import 'package:flutter/material.dart';

import '../chat/chat_inbox_screen.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  String username = 'Provider';
  String currentRole = 'PROVIDER';
  bool isLoading = true;
  String? errorMessage;
  Map<String, dynamic>? dashboard;

  @override
  void initState() {
    super.initState();
    loadCurrentUser();
    fetchDashboard();
  }

  Future<void> loadCurrentUser() async {
    final currentUser = await SessionService.getCurrentUser();
    if (!mounted || currentUser == null) return;

    setState(() {
      username = currentUser['username'] ?? 'Provider';
      currentRole = currentUser['role']?.toString().toUpperCase() ?? 'PROVIDER';
    });
  }

  Future<void> fetchDashboard() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.getAuthenticated(
        '/api/providers/me/dashboard/',
      );
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          dashboard = Map<String, dynamic>.from(body);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = body['error'] ?? 'Unable to load provider dashboard';
          isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        errorMessage = 'Unable to load provider dashboard';
        isLoading = false;
      });
    }
  }

  Future<void> updateBookingStatus(int bookingId, String status) async {
    final response = await ApiService.patchAuthenticated(
      '/api/providers/bookings/$bookingId/status/',
      body: {'status': status},
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Booking marked as $status')));
      fetchDashboard();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(body['error'] ?? 'Unable to update booking')),
      );
    }
  }

  Future<void> markRefundProcessed(int bookingId) async {
    final response = await ApiService.patchAuthenticated(
      '/api/providers/bookings/$bookingId/status/',
      body: {'refund_status': 'processed'},
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refund marked as completed')),
      );
      fetchDashboard();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(body['error'] ?? 'Unable to update refund')),
      );
    }
  }

  Future<void> removeFromHistory(int bookingId) async {
    final response = await ApiService.postAuthenticated(
      '/api/providers/bookings/$bookingId/hide/',
    );

    if (response.statusCode == 200) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking removed from provider history')),
      );
      fetchDashboard();
    } else {
      final body = jsonDecode(response.body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            body['error'] ?? 'Unable to remove booking from provider history',
          ),
        ),
      );
    }
  }

  Future<void> confirmRemoveFromHistory(int bookingId) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove booking from history?'),
          content: const Text(
            'This hides the booking from your dashboard history, but keeps it in system records.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep it'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (shouldRemove == true) {
      await removeFromHistory(bookingId);
    }
  }

  Future<void> addUnavailableDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (selected == null || !mounted) return;

    final reasonController = TextEditingController();
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Mark Date Unavailable'),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
              hintText: 'Conference, leave, emergency...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final response = await ApiService.postAuthenticated(
                  '/api/providers/me/unavailable-dates/',
                  body: {
                    'date': selected.toIso8601String().split('T')[0],
                    'reason': reasonController.text.trim(),
                  },
                );

                if (!mounted) return;

                if (response.statusCode == 201) {
                  Navigator.pop(dialogContext);
                  fetchDashboard();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Date marked unavailable')),
                  );
                } else {
                  final body = jsonDecode(response.body);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        body['error'] ?? 'Unable to mark date unavailable',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> removeUnavailableDate(int itemId) async {
    final response = await ApiService.deleteAuthenticated(
      '/api/providers/me/unavailable-dates/$itemId/',
    );

    if (!mounted) return;
    if (response.statusCode == 200) {
      fetchDashboard();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unavailable date removed')));
    }
  }

  Future<void> openEditProfileDialog(Map<String, dynamic> provider) async {
    final nameController = TextEditingController(text: provider['name'] ?? '');
    final priceController = TextEditingController(
      text: provider['price']?.toString() ?? '',
    );
    final phoneController = TextEditingController(
      text: provider['phone_number'] ?? '',
    );
    final locationController = TextEditingController(
      text: provider['location'] ?? '',
    );
    final descriptionController = TextEditingController(
      text: provider['description'] ?? '',
    );
    final imageController = TextEditingController(
      text: provider['hero_image'] ?? '',
    );
    bool isAvailable = provider['is_available'] ?? true;
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> saveProfile() async {
              setModalState(() {
                isSaving = true;
              });

              final response = await ApiService.patchAuthenticated(
                '/api/providers/me/profile/',
                body: {
                  'name': nameController.text.trim(),
                  'price': priceController.text.trim(),
                  'phone_number': phoneController.text.trim(),
                  'location': locationController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'hero_image': imageController.text.trim(),
                  'is_available': isAvailable,
                },
              );

              final body = jsonDecode(response.body);
              if (!mounted) return;

              if (response.statusCode == 200) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Provider profile updated')),
                );
                fetchDashboard();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(body.toString())),
                );
              }

              setModalState(() {
                isSaving = false;
              });
            }

            return AlertDialog(
              title: const Text('Edit Provider Profile'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price'),
                    ),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                    ),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(labelText: 'Location'),
                    ),
                    TextField(
                      controller: imageController,
                      decoration: const InputDecoration(
                        labelText: 'Hero Image URL',
                      ),
                    ),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: isAvailable,
                      onChanged: (value) {
                        setModalState(() {
                          isAvailable = value;
                        });
                      },
                      title: const Text('Available'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : saveProfile,
                  child: Text(isSaving ? 'Saving...' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> logout() async {
    await SessionService.clearSession();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void openBookingList(String title, List<Map<String, dynamic>> bookings) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ProviderBookingListScreen(title: title, bookings: bookings),
      ),
    );
  }

  Widget metricCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }

  Widget bookingActionButton(String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(foregroundColor: color),
        child: Text(label),
      ),
    );
  }

  String _shortTime(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) return 'Time not set';
    return text.length >= 5 ? text.substring(0, 5) : text;
  }

  @override
  Widget build(BuildContext context) {
    final provider = dashboard?['provider'] as Map<String, dynamic>?;
    final summary = dashboard?['summary'] as Map<String, dynamic>?;
    final recentBookings =
        (dashboard?['recent_bookings'] as List?)?.cast<Map<String, dynamic>>() ??
        const [];
    final todayBookings = recentBookings
        .where((booking) => booking['date'] == DateTime.now().toIso8601String().split('T')[0])
        .toList();
    final pendingBookings = recentBookings
        .where((booking) => booking['status'] == 'pending')
        .toList();
    final completedBookings = recentBookings
        .where((booking) => booking['status'] == 'completed')
        .toList();
    final cancelledBookings = recentBookings
        .where((booking) => booking['status'] == 'cancelled')
        .toList();
    final unavailableDates =
        (dashboard?['unavailable_dates'] as List?)?.cast<Map<String, dynamic>>() ??
        const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Dashboard'),
        actions: [
          IconButton(
            onPressed: provider == null
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatInboxScreen(
                          providerId: provider['id'],
                          providerName:
                              provider['name']?.toString() ?? username,
                        ),
                      ),
                    );
                  },
            icon: const Icon(Icons.chat_bubble_outline),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            icon: const Icon(Icons.person_outline),
          ),
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.store_mall_directory_outlined, size: 52),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Create or link a provider account from the admin dashboard, then retry here.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: fetchDashboard,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: fetchDashboard,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Welcome, $username',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider == null
                        ? 'Manage your incoming bookings and provider profile.'
                        : '${provider['name']} - ${provider['location'] ?? 'Location not set'}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      metricCard(
                        'Today Bookings',
                        '${summary?['today_bookings'] ?? 0}',
                        Icons.calendar_today,
                        Colors.blue,
                        onTap: () => openBookingList('Today Bookings', todayBookings),
                      ),
                      const SizedBox(width: 12),
                      metricCard(
                        'Pending Requests',
                        '${summary?['pending_requests'] ?? 0}',
                        Icons.pending_actions,
                        Colors.orange,
                        onTap: () => openBookingList('Pending Requests', pendingBookings),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      metricCard(
                        'Rating',
                        '${summary?['rating'] ?? 0}',
                        Icons.star,
                        Colors.green,
                        onTap: () => openBookingList('Completed Bookings', completedBookings),
                      ),
                      const SizedBox(width: 12),
                      metricCard(
                        summary?['earnings_month_label']?.toString() ?? 'Monthly Earnings',
                        'Rs ${summary?['monthly_earnings'] ?? 0}',
                        Icons.account_balance_wallet,
                        Colors.purple,
                        onTap: () => openBookingList('Cancelled / Refund Cases', cancelledBookings),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      metricCard(
                        'Total Earnings',
                        'Rs ${summary?['total_earnings'] ?? 0}',
                        Icons.savings_outlined,
                        Colors.teal,
                        onTap: () => openBookingList('Completed Bookings', completedBookings),
                      ),
                      const SizedBox(width: 12),
                      metricCard(
                        'Cancelled Cases',
                        '${summary?['cancelled_bookings'] ?? 0}',
                        Icons.cancel_outlined,
                        Colors.redAccent,
                        onTap: () => openBookingList('Cancelled / Refund Cases', cancelledBookings),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (currentRole == 'DOCTOR') ...[
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Unavailable Dates',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: addUnavailableDate,
                          icon: const Icon(Icons.event_busy),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    if (unavailableDates.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No blocked dates',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Mark dates when you are not available for booking.',
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...unavailableDates.map((item) {
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.event_busy),
                            title: Text(item['date'] ?? ''),
                            subtitle: Text(
                              (item['reason'] ?? '').toString().isEmpty
                                  ? 'Unavailable'
                                  : item['reason'],
                            ),
                            trailing: IconButton(
                              onPressed: () => removeUnavailableDate(item['id']),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 20),
                  ],
                  if (provider != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.storefront),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    provider['name'] ?? 'Provider Profile',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Price: Rs ${provider['price'] ?? '0'} - Phone: ${provider['phone_number'] ?? 'Not added'}',
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () => openEditProfileDialog(provider),
                                child: const Text('Edit'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (provider != null) const SizedBox(height: 8),
                  const Text(
                    'Recent Bookings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (recentBookings.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No provider bookings yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'When users book your services, they will appear here.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ...recentBookings.map((booking) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking['user_name'] ?? 'Customer',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${booking['date']} - ${_shortTime(booking['time'])}',
                            ),
                            Text(
                              'Phone: ${booking['phone_number'] ?? booking['user_phone'] ?? 'Not added'}',
                            ),
                            if ((booking['address'] ?? '').toString().isNotEmpty)
                              Text('Address: ${booking['address']}'),
                            if ((booking['description'] ?? '').toString().isNotEmpty)
                              Text('Notes: ${booking['description']}'),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Chip(label: Text('Status: ${booking['status']}')),
                                Chip(
                                  label: Text(
                                    'Payment: ${booking['payment_status'] ?? 'pending'}',
                                  ),
                                ),
                                if ((booking['refund_status'] ??
                                        'not_applicable') !=
                                    'not_applicable')
                                  Chip(
                                    label: Text(
                                      'Refund: ${booking['refund_status']}',
                                    ),
                                  ),
                                if ((booking['consultation_type'] ?? '')
                                    .toString()
                                    .isNotEmpty)
                                  Chip(
                                    label: Text(
                                      booking['consultation_type'].toString(),
                                    ),
                                  ),
                              ],
                            ),
                            if ((booking['cancellation_source'] ?? '')
                                .toString()
                                .isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  booking['cancellation_source'] == 'customer'
                                      ? 'Cancelled by customer'
                                      : 'Cancelled by provider',
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 10),
                            if (booking['status'] != 'cancelled')
                              Row(
                                children: [
                                  bookingActionButton(
                                    'Confirm',
                                    Colors.green,
                                    () => updateBookingStatus(
                                      booking['id'],
                                      'confirmed',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  bookingActionButton(
                                    'Complete',
                                    Colors.blue,
                                    () => updateBookingStatus(
                                      booking['id'],
                                      'completed',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  bookingActionButton(
                                    'Cancel',
                                    Colors.red,
                                    () => updateBookingStatus(
                                      booking['id'],
                                      'cancelled',
                                    ),
                                  ),
                                ],
                              ),
                            if (booking['status'] == 'cancelled' &&
                                booking['payment_status'] == 'paid' &&
                                booking['refund_status'] == 'pending') ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Refund action required',
                                      style: TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Customer already paid Rs ${booking['amount'] ?? '0'}. Mark refund as completed after returning the payment.',
                                    ),
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton(
                                        onPressed: () => markRefundProcessed(booking['id']),
                                        child: const Text('Mark Refund Completed'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => confirmRemoveFromHistory(booking['id']),
                                icon: const Icon(Icons.delete_outline, size: 18),
                                label: const Text('Remove from History'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}

class _ProviderBookingListScreen extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> bookings;

  const _ProviderBookingListScreen({
    required this.title,
    required this.bookings,
  });

  String _shortTime(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) return 'Time not set';
    return text.length >= 5 ? text.substring(0, 5) : text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: bookings.isEmpty
          ? const Center(child: Text('No bookings in this section'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking['user_name'] ?? 'Customer',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('${booking['date']} - ${_shortTime(booking['time'])}'),
                        Text('Status: ${booking['status']}'),
                        if ((booking['payment_status'] ?? '').toString().isNotEmpty)
                          Text('Payment: ${booking['payment_status']}'),
                        if ((booking['refund_status'] ?? '').toString().isNotEmpty &&
                            booking['refund_status'] != 'not_applicable')
                          Text('Refund: ${booking['refund_status']}'),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
