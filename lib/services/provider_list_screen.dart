import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:multiservice_frontend/services/booking_screen.dart';
import 'provider_detail_screen.dart';

class ProviderListScreen extends StatefulWidget {
  final int serviceId;
  final String serviceName;

  final String location;

  const ProviderListScreen({
    super.key,
    required this.serviceId,
    required this.serviceName,
    required this.location,
  });

  @override
  State<ProviderListScreen> createState() => _ProviderListScreenState();
}

class _ProviderListScreenState extends State<ProviderListScreen> {
  List providers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProviders();
  }

  Future<void> fetchProviders() async {
    try {
      final response = await http.get(
        Uri.parse(
          "http://127.0.0.1:8000/api/providers/?service=${widget.serviceId}&location=${widget.location}",
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          providers = jsonDecode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.serviceName)),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: providers.length,
              itemBuilder: (context, index) {
                final provider = providers[index];
                print("CATEGORY: ${provider['category_name']}");
                final isDoctor = (provider['category_name'] ?? "")
                    .toString()
                    .toLowerCase()
                    .contains("doctor");
                print("isDoctor: $isDoctor");
                return GestureDetector(
                  onTap: () {
                    // 👉 CLICK ON CARD → DETAIL PAGE
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProviderDetailScreen(provider: provider),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.all(10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // LEFT SIDE
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  provider['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 5),

                                Text(
                                  "${provider['location']} • ${provider['experience_years']} yrs",
                                ),

                                const SizedBox(height: 5),

                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.orange,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${provider['rating']} (${provider['reviews_count']})",
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 10),

                          // RIGHT SIDE
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "₹${provider['price']}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),

                              // 🔥 IMPORTANT: BOOK BUTTON
                              ElevatedButton(
                                onPressed: () {
                                  // 👉 ONLY BOOK BUTTON → BOOKING PAGE
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BookingScreen(
                                        providerId: provider['id'],
                                        providerName: provider['name'],
                                        isDoctor: isDoctor,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text("Book"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
