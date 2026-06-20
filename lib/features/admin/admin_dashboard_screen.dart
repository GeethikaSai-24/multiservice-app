import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/session_service.dart';
import 'admin_management_screen.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String username = 'Admin';
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
      username = currentUser['username'] ?? 'Admin';
    });
  }

  Future<void> fetchDashboard() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.getAuthenticated(
        '/api/users/admin/dashboard/',
      );
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          dashboard = Map<String, dynamic>.from(body);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = body['error'] ?? 'Unable to load admin dashboard';
          isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        errorMessage = 'Unable to load admin dashboard';
        isLoading = false;
      });
    }
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

  void openStatList(String title, List items, List<String> lines) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AdminStatListScreen(
          title: title,
          items: items,
          lines: lines,
        ),
      ),
    );
  }

  Widget summaryCard(
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> openCreateProviderAccountDialog(
    Map<String, dynamic> provider,
  ) async {
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController(text: 'provider123');
    final phoneController = TextEditingController(
      text: provider['phone_number']?.toString() ?? '',
    );
    String selectedRole = 'PROVIDER';
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> submit() async {
              if (usernameController.text.trim().isEmpty ||
                  emailController.text.trim().isEmpty ||
                  passwordController.text.trim().isEmpty) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Fill all required fields')),
                );
                return;
              }

              setModalState(() {
                isSubmitting = true;
              });

              final response = await ApiService.postAuthenticated(
                '/api/users/admin/providers/create-account/',
                body: {
                  'provider_id': provider['id'],
                  'username': usernameController.text.trim(),
                  'email': emailController.text.trim(),
                  'password': passwordController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'role': selectedRole,
                },
              );

              final body = jsonDecode(response.body);

              if (response.statusCode == 201) {
                if (!mounted) return;
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(
                      body['message'] ?? 'Provider account created',
                    ),
                  ),
                );
                fetchDashboard();
              } else {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(
                      body['error']?.toString() ??
                          body['username']?.toString() ??
                          body['email']?.toString() ??
                          'Unable to create provider account',
                    ),
                  ),
                );
              }

              if (mounted) {
                setModalState(() {
                  isSubmitting = false;
                });
              }
            }

            return AlertDialog(
              title: Text('Create Account for ${provider['name']}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(labelText: 'Username'),
                    ),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: const [
                        DropdownMenuItem(
                          value: 'PROVIDER',
                          child: Text('Provider'),
                        ),
                        DropdownMenuItem(
                          value: 'DOCTOR',
                          child: Text('Doctor'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() {
                          selectedRole = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : submit,
                  child: Text(isSubmitting ? 'Creating...' : 'Create Account'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> reviewRegistration(int userId, String decision) async {
    final response = await ApiService.postAuthenticated(
      '/api/users/admin/registrations/$userId/review/',
      body: {'decision': decision},
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 200) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(body['message'] ?? 'Registration updated')),
      );
      fetchDashboard();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(body['error'] ?? 'Unable to update registration'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = dashboard?['stats'] as Map<String, dynamic>?;
    final pendingRegistrations =
        (dashboard?['pending_registrations'] as List?)?.cast<Map<String, dynamic>>() ??
        const [];
    final linkedProviders =
        (dashboard?['linked_providers'] as List?)?.cast<Map<String, dynamic>>() ??
        const [];
    final unlinkedProviders =
        (dashboard?['unlinked_providers'] as List?)?.cast<Map<String, dynamic>>() ??
        const [];
    final users =
        (dashboard?['users'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final bookings =
        (dashboard?['bookings'] as List?)?.cast<Map<String, dynamic>>() ??
        const [];
    final pendingBookings =
        (dashboard?['pending_bookings_list'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
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
                    const Icon(Icons.admin_panel_settings_outlined, size: 52),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                    'Run the platform from here: monitor users, onboarding, and provider account creation.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      summaryCard(
                        'Users',
                        '${stats?['users'] ?? 0}',
                        Icons.people_alt,
                        Colors.blue,
                        onTap: () => openStatList(
                          'Users',
                          users,
                          const ['username', 'email', 'role', 'approval_status'],
                        ),
                      ),
                      const SizedBox(width: 12),
                      summaryCard(
                        'Providers',
                        '${stats?['providers'] ?? 0}',
                        Icons.store_mall_directory,
                        Colors.green,
                        onTap: () => openStatList(
                          'Providers',
                          [...linkedProviders, ...unlinkedProviders],
                          const ['name', 'service_name', 'location', 'username'],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      summaryCard(
                        'Bookings',
                        '${stats?['bookings'] ?? 0}',
                        Icons.event_note,
                        Colors.orange,
                        onTap: () => openStatList(
                          'Bookings',
                          bookings,
                          const [
                            'user_name',
                            'provider_name',
                            'date',
                            'time',
                            'status',
                            'payment_status',
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      summaryCard(
                        'Pending',
                        '${stats?['pending_bookings'] ?? 0}',
                        Icons.pending_actions,
                        Colors.purple,
                        onTap: () => openStatList(
                          'Pending Bookings',
                          pendingBookings,
                          const [
                            'user_name',
                            'provider_name',
                            'date',
                            'time',
                            'status',
                            'payment_status',
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      summaryCard(
                        'Approval Queue',
                        '${stats?['pending_provider_registrations'] ?? 0}',
                        Icons.verified_user_outlined,
                        Colors.teal,
                        onTap: () => openStatList(
                          'Approval Queue',
                          pendingRegistrations,
                          const [
                            'name',
                            'username',
                            'email',
                            'role',
                            'phone',
                            'provider_location',
                            'experience_years',
                            'provider_description',
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminManagementScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings_suggest_outlined),
                      label: const Text('Open Admin Management'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Pending Registration Requests',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (pendingRegistrations.isEmpty)
                    const Card(
                      child: ListTile(
                        title: Text('No pending provider registrations'),
                        subtitle: Text(
                          'New provider or doctor signups will appear here for approval.',
                        ),
                      ),
                    ),
                  ...pendingRegistrations.map((registration) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              registration['name'] ??
                                  registration['username'] ??
                                  'Applicant',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${registration['role'] ?? 'PROVIDER'} - ${registration['email'] ?? 'No email'}',
                            ),
                            if ((registration['phone'] ?? '').toString().isNotEmpty)
                              Text('Phone: ${registration['phone']}'),
                            if ((registration['provider_location'] ?? '').toString().isNotEmpty)
                              Text('Location: ${registration['provider_location']}'),
                            if ((registration['experience_years'] ?? '').toString().isNotEmpty)
                              Text('Experience: ${registration['experience_years']} years'),
                            if ((registration['provider_description'] ?? '').toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  registration['provider_description'].toString(),
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      reviewRegistration(
                                        registration['id'],
                                        'REJECTED',
                                      );
                                    },
                                    child: const Text('Reject'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      reviewRegistration(
                                        registration['id'],
                                        'APPROVED',
                                      );
                                    },
                                    child: const Text('Approve'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  const Text(
                    'Provider Onboarding',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (unlinkedProviders.isEmpty)
                    const Card(
                      child: ListTile(
                        title: Text('All providers are linked'),
                        subtitle: Text(
                          'No pending provider account creation is required.',
                        ),
                      ),
                    ),
                  ...unlinkedProviders.map((provider) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person_add_alt_1),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    provider['name'] ?? 'Provider',
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
                              '${provider['service_name'] ?? 'Service not set'} - ${provider['location'] ?? 'Location not set'}',
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () {
                                  openCreateProviderAccountDialog(provider);
                                },
                                child: const Text('Create Login'),
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

class _AdminStatListScreen extends StatelessWidget {
  final String title;
  final List items;
  final List<String> lines;

  const _AdminStatListScreen({
    required this.title,
    required this.items,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: items.isEmpty
          ? const Center(child: Text('No records available'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = Map<String, dynamic>.from(items[index]);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: lines.map((line) {
                        final value = (item[line] ?? '').toString();
                        if (value.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${line.replaceAll('_', ' ')}: $value',
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
