import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../auth/login_screen.dart';
import '../dashboard/dashboard_router.dart';
import '../settings/server_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? user;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final cachedUser = await SessionService.getCurrentUser();
    if (cachedUser != null) {
      setState(() {
        user = cachedUser;
        isLoading = false;
      });
    }

    try {
      final freshUser = await AuthService.fetchCurrentUser();
      await SessionService.saveCurrentUser(freshUser);
      if (!mounted) return;
      setState(() {
        user = freshUser;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
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

  void openDashboard() {
    final role = user?['role']?.toString();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => DashboardRouter.screenForRole(role)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = user;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : profile == null
          ? const Center(child: Text('Unable to load profile'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            child: Text(
                              (profile['username'] ?? 'U')
                                  .toString()
                                  .substring(0, 1)
                                  .toUpperCase(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile['username'] ?? 'User',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(profile['email'] ?? 'No email'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Role: ${profile['role'] ?? 'USER'}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text('Phone: ${profile['phone'] ?? 'Not added'}'),
                  const SizedBox(height: 8),
                  Text(
                    'Name: ${((profile['name'] ?? '') as String).trim().isEmpty ? 'Not added' : profile['name']}',
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ServerSettingsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings_ethernet),
                      label: const Text('Server Settings'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: openDashboard,
                      icon: const Icon(Icons.dashboard_customize_outlined),
                      label: const Text('Open My Dashboard'),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
