import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:multiservice_frontend/services/service_list_screen.dart';
import 'package:multiservice_frontend/services/booking_history_screen.dart';

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
  TextEditingController searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      print("=== API CALL START ===");

      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/services/categories/'),
      );

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (response.statusCode == 200) {
        setState(() {
          final data = jsonDecode(response.body);

          setState(() {
            allCategories = data;
            filteredCategories = data;
            isLoading = false;
          });
          isLoading = false;
        });
      } else {
        print("API FAILED");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("ERROR OCCURRED: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void filterCategories(String query) {
    final lowerQuery = query.toLowerCase();

    final results = allCategories.where((category) {
      // ✅ Check category name
      final categoryName = category['name'].toString().toLowerCase();
      if (categoryName.contains(lowerQuery)) {
        return true;
      }

      // ✅ Check inside services
      final services = category['services'] as List;

      for (var service in services) {
        final serviceName = service['name'].toString().toLowerCase();
        if (serviceName.contains(lowerQuery)) {
          return true; // 🔥 MATCH FOUND INSIDE SERVICE
        }
      }

      return false;
    }).toList();

    setState(() {
      filteredCategories = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text("Multi Service App"),
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
                  // 🔥 ADD THIS SEARCH BAR
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
                    child: GridView.builder(
                      itemCount: filteredCategories.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.9,
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
                                BoxShadow(color: Colors.black12, blurRadius: 6),
                              ],
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // 🔥 IMAGE BOX
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    height: 80,
                                    width: 80,
                                    color: Colors.grey.shade100,
                                    child: Image.network(
                                      category['icon'] ?? '',
                                      fit: BoxFit
                                          .contain, // 🔥 IMPORTANT (no stretch)

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

                                // 🔥 TEXT
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: Text(
                                    category['name'],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
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
