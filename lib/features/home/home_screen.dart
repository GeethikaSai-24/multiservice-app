import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:multiservice_frontend/features/auth/login_screen.dart';
import 'package:multiservice_frontend/features/chatbot/chatbot_screen.dart';
import 'package:multiservice_frontend/features/notifications/notifications_screen.dart';
import 'package:multiservice_frontend/features/profile/profile_screen.dart';
import 'package:multiservice_frontend/features/settings/server_settings_screen.dart';
import 'package:multiservice_frontend/services/api_service.dart';
import 'package:multiservice_frontend/services/booking_history_screen.dart';
import 'package:multiservice_frontend/services/service_list_screen.dart';
import 'package:multiservice_frontend/services/session_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List allCategories = [];
  List filteredCategories = [];
  bool isLoading = true;
  String selectedLocation = "Hyderabad";
  String username = "User";
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadCurrentUser();
    fetchCategories();
  }

  Future<void> loadCurrentUser() async {
    final currentUser = await SessionService.getCurrentUser();
    if (currentUser == null || !mounted) return;

    setState(() {
      username = currentUser['username'] ?? 'User';
    });
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

  Future<void> fetchCategories() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiService.get('/api/services/categories/');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          allCategories = data;
          filteredCategories = data;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void filterCategories(String query) {
    final lowerQuery = query.toLowerCase();

    final results = allCategories.where((category) {
      final categoryName = category['name'].toString().toLowerCase();
      if (categoryName.contains(lowerQuery)) {
        return true;
      }

      final services = category['services'] as List;
      for (var service in services) {
        final serviceName = service['name'].toString().toLowerCase();
        if (serviceName.contains(lowerQuery)) {
          return true;
        }
      }

      return false;
    }).toList();

    setState(() {
      filteredCategories = results;
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Welcome, $username"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BookingHistoryScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatbotScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              }
              if (value == 'server') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ServerSettingsScreen(),
                  ),
                ).then((_) => fetchCategories());
              }
              if (value == 'logout') {
                logout();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'profile', child: Text('My Profile')),
              PopupMenuItem(
                value: 'server',
                child: Text('Server Settings'),
              ),
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "What are you looking for?",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Book trusted providers, manage appointments, and keep track of your upcoming services.",
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      hintText:
                          "Enter your location (e.g., Hyderabad, Madhapur)",
                      prefixIcon: const Icon(Icons.location_on),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        selectedLocation = value;
                      });
                    },
                  ),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red),
                      const SizedBox(width: 5),
                      Text(
                        selectedLocation.isEmpty
                            ? "Select Location"
                            : selectedLocation,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: searchController,
                    onChanged: filterCategories,
                    decoration: InputDecoration(
                      hintText: "Search services...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: filteredCategories.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off_outlined,
                                  size: 48,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No matching services found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Try a different keyword or location.',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            itemCount: filteredCategories.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.68,
                                ),
                            itemBuilder: (context, index) {
                              final category = filteredCategories[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ServiceListScreen(
                                        categoryName: category['name'],
                                        services: category['services'],
                                        location: selectedLocation,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          height: 80,
                                          width: 80,
                                          color: Colors.grey.shade100,
                                          child: Image.network(
                                            category['icon'] ?? '',
                                            fit: BoxFit.contain,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return const Icon(
                                                    Icons.home_repair_service,
                                                    size: 40,
                                                  );
                                                },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          child: Center(
                                            child: Text(
                                              category['name'],
                                              textAlign: TextAlign.center,
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
