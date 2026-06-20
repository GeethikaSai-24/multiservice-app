import 'dart:convert';

import 'package:flutter/material.dart';

import 'api_service.dart';
import 'booking_screen.dart';
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
  List filteredProviders = [];
  bool isLoading = true;
  String? infoMessage;
  String searchQuery = '';
  String sortMode = 'rating';
  bool showAvailableOnly = false;

  @override
  void initState() {
    super.initState();
    fetchProviders();
  }

  Future<void> fetchProviders() async {
    setState(() {
      isLoading = true;
      infoMessage = null;
    });

    try {
      final encodedLocation = Uri.encodeQueryComponent(widget.location);
      final response = await ApiService.get(
        '/api/providers/?service=${widget.serviceId}&location=$encodedLocation',
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is List &&
            decoded.isEmpty &&
            widget.location.trim().isNotEmpty) {
          final fallbackResponse = await ApiService.get(
            '/api/providers/?service=${widget.serviceId}',
          );

          if (fallbackResponse.statusCode == 200) {
            final fallbackProviders = jsonDecode(fallbackResponse.body);
            setState(() {
              providers = fallbackProviders;
              _applyFilters();
              infoMessage = fallbackProviders.isEmpty
                  ? null
                  : 'No providers matched "${widget.location}". Showing all available providers for this service instead.';
              isLoading = false;
            });
            return;
          }
        }

        setState(() {
          providers = decoded;
          _applyFilters();
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

  void _applyFilters() {
    final query = searchQuery.trim().toLowerCase();
    var results = providers.where((provider) {
      final name = (provider['name'] ?? '').toString().toLowerCase();
      final location = (provider['location'] ?? '').toString().toLowerCase();
      final description = (provider['description'] ?? '')
          .toString()
          .toLowerCase();
      final matchesQuery =
          query.isEmpty ||
          name.contains(query) ||
          location.contains(query) ||
          description.contains(query);
      final matchesAvailability =
          !showAvailableOnly || provider['is_available'] == true;
      return matchesQuery && matchesAvailability;
    }).toList();

    results.sort((a, b) {
      switch (sortMode) {
        case 'price':
          return ((a['price'] ?? 0) as num).compareTo((b['price'] ?? 0) as num);
        case 'experience':
          return ((b['experience_years'] ?? 0) as num).compareTo(
            (a['experience_years'] ?? 0) as num,
          );
        case 'name':
          return (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString());
        case 'rating':
        default:
          return ((b['rating'] ?? 0) as num).compareTo((a['rating'] ?? 0) as num);
      }
    });

    filteredProviders = results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.serviceName)),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search providers by name or location',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                            _applyFilters();
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: sortMode,
                              decoration: InputDecoration(
                                labelText: 'Sort by',
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'rating',
                                  child: Text('Top rated'),
                                ),
                                DropdownMenuItem(
                                  value: 'price',
                                  child: Text('Lowest price'),
                                ),
                                DropdownMenuItem(
                                  value: 'experience',
                                  child: Text('Most experienced'),
                                ),
                                DropdownMenuItem(
                                  value: 'name',
                                  child: Text('Name'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  sortMode = value;
                                  _applyFilters();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilterChip(
                            label: const Text('Available only'),
                            selected: showAvailableOnly,
                            onSelected: (value) {
                              setState(() {
                                showAvailableOnly = value;
                                _applyFilters();
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredProviders.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.store_mall_directory_outlined, size: 52),
                    const SizedBox(height: 12),
                    const Text(
                      'No providers found for this service',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.location.trim().isEmpty
                          ? 'Try another service or refresh the page.'
                          : 'Try a different location or clear the location field.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              itemCount: filteredProviders.length + (infoMessage == null ? 0 : 1),
              itemBuilder: (context, index) {
                if (infoMessage != null && index == 0) {
                  return Container(
                    margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(infoMessage!),
                  );
                }

                final provider =
                    filteredProviders[infoMessage == null ? index : index - 1];
                final isDoctor = (provider['category_name'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains('doctor');

                return GestureDetector(
                  onTap: () {
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  provider['name'] ?? 'Provider',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${provider['location'] ?? 'Location not available'} - ${provider['experience_years'] ?? 0} yrs',
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
                                    Text('${provider['rating'] ?? '0'}'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Rs.${provider['price'] ?? '0'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              SizedBox(
                                width: 96,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BookingScreen(
                                          providerId: provider['id'],
                                          providerName:
                                              provider['name'] ?? 'Provider',
                                          isDoctor: isDoctor,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('Book'),
                                ),
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
                ),
              ],
            ),
    );
  }
}
