import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;
  List categories = [];
  List services = [];
  List providers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    loadAll();
  }

  Future<void> loadAll() async {
    setState(() {
      isLoading = true;
    });

    final categoryResponse = await ApiService.getAuthenticated(
      '/api/services/admin/categories/',
    );
    final serviceResponse = await ApiService.getAuthenticated(
      '/api/services/admin/services/',
    );
    final providerResponse = await ApiService.getAuthenticated(
      '/api/providers/admin/manage/',
    );

    setState(() {
      categories = categoryResponse.statusCode == 200
          ? jsonDecode(categoryResponse.body)
          : [];
      services = serviceResponse.statusCode == 200
          ? jsonDecode(serviceResponse.body)
          : [];
      providers = providerResponse.statusCode == 200
          ? jsonDecode(providerResponse.body)
          : [];
      isLoading = false;
    });
  }

  Future<void> deleteItem(String path, String successMessage) async {
    final response = await ApiService.deleteAuthenticated(path);
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
      loadAll();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(body['error'] ?? 'Unable to delete item')),
      );
    }
  }

  Future<void> openCategoryDialog({Map<String, dynamic>? category}) async {
    final nameController = TextEditingController(text: category?['name'] ?? '');
    final iconController = TextEditingController(text: category?['icon'] ?? '');
    final isEdit = category != null;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Category' : 'Add Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Category Name'),
                ),
                TextField(
                  controller: iconController,
                  decoration: const InputDecoration(labelText: 'Icon URL'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final payload = {
                  'name': nameController.text.trim(),
                  'icon': iconController.text.trim(),
                };

                final response = isEdit
                    ? await ApiService.putAuthenticated(
                        '/api/services/admin/categories/${category['id']}/',
                        body: payload,
                      )
                    : await ApiService.postAuthenticated(
                        '/api/services/admin/categories/',
                        body: payload,
                      );

                if (!mounted) return;
                if (response.statusCode == 200 || response.statusCode == 201) {
                  Navigator.pop(dialogContext);
                  loadAll();
                } else {
                  final body = jsonDecode(response.body);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(body.toString())),
                  );
                }
              },
              child: Text(isEdit ? 'Save' : 'Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> openServiceDialog({Map<String, dynamic>? service}) async {
    final nameController = TextEditingController(text: service?['name'] ?? '');
    final descriptionController = TextEditingController(
      text: service?['description'] ?? '',
    );
    final priceController = TextEditingController(
      text: service?['base_price']?.toString() ?? '',
    );
    final durationController = TextEditingController(
      text: service?['duration_minutes']?.toString() ?? '',
    );
    int? selectedCategory =
        service?['category'] ?? (categories.isNotEmpty ? categories.first['id'] : null);
    bool isActive = service?['is_active'] ?? true;
    final isEdit = service != null;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Service' : 'Add Service'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: categories.map<DropdownMenuItem<int>>((categoryItem) {
                        return DropdownMenuItem<int>(
                          value: categoryItem['id'],
                          child: Text(categoryItem['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() {
                          selectedCategory = value;
                        });
                      },
                    ),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Service Name'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Base Price'),
                    ),
                    TextField(
                      controller: durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Duration (minutes)'),
                    ),
                    SwitchListTile(
                      value: isActive,
                      onChanged: (value) {
                        setModalState(() {
                          isActive = value;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final payload = {
                      'category': selectedCategory,
                      'name': nameController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'base_price': priceController.text.trim(),
                      'duration_minutes': durationController.text.trim(),
                      'is_active': isActive,
                    };

                    final response = isEdit
                        ? await ApiService.putAuthenticated(
                            '/api/services/admin/services/${service['id']}/',
                            body: payload,
                          )
                        : await ApiService.postAuthenticated(
                            '/api/services/admin/services/',
                            body: payload,
                          );

                    if (!mounted) return;
                    if (response.statusCode == 200 || response.statusCode == 201) {
                      Navigator.pop(dialogContext);
                      loadAll();
                    } else {
                      final body = jsonDecode(response.body);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(body.toString())),
                      );
                    }
                  },
                  child: Text(isEdit ? 'Save' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> openProviderDialog(Map<String, dynamic> provider) async {
    final nameController = TextEditingController(text: provider['name'] ?? '');
    final priceController = TextEditingController(
      text: provider['price']?.toString() ?? '',
    );
    final locationController = TextEditingController(
      text: provider['location'] ?? '',
    );
    final phoneController = TextEditingController(
      text: provider['phone_number'] ?? '',
    );
    final descriptionController = TextEditingController(
      text: provider['description'] ?? '',
    );
    bool isAvailable = provider['is_available'] ?? true;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Edit Provider'),
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
                      controller: locationController,
                      decoration: const InputDecoration(labelText: 'Location'),
                    ),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    SwitchListTile(
                      value: isAvailable,
                      onChanged: (value) {
                        setModalState(() {
                          isAvailable = value;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Available'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final payload = {
                      'name': nameController.text.trim(),
                      'price': priceController.text.trim(),
                      'location': locationController.text.trim(),
                      'phone_number': phoneController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'is_available': isAvailable,
                    };

                    final response = await ApiService.patchAuthenticated(
                      '/api/providers/admin/${provider['id']}/',
                      body: payload,
                    );

                    if (!mounted) return;
                    if (response.statusCode == 200) {
                      Navigator.pop(dialogContext);
                      loadAll();
                    } else {
                      final body = jsonDecode(response.body);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(body.toString())),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget buildCategoriesTab() {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () => openCategoryDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Category'),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Card(
                child: ListTile(
                  title: Text(category['name']),
                  subtitle: Text(
                    '${(category['services'] as List?)?.length ?? 0} services',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => openCategoryDialog(
                          category: Map<String, dynamic>.from(category),
                        ),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        onPressed: () => deleteItem(
                          '/api/services/admin/categories/${category['id']}/',
                          'Category deleted',
                        ),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildServicesTab() {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: categories.isEmpty ? null : () => openServiceDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Service'),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return Card(
                child: ListTile(
                  title: Text(service['name']),
                  subtitle: Text(
                    '${service['category_name'] ?? 'No category'} • Rs ${service['base_price']} • ${service['duration_minutes']} mins',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => openServiceDialog(
                          service: Map<String, dynamic>.from(service),
                        ),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        onPressed: () => deleteItem(
                          '/api/services/admin/services/${service['id']}/',
                          'Service deleted',
                        ),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildProvidersTab() {
    return ListView.builder(
      itemCount: providers.length,
      itemBuilder: (context, index) {
        final provider = providers[index];
        return Card(
          child: ListTile(
            title: Text(provider['name']),
            subtitle: Text(
              '${provider['service_name'] ?? 'No service'} • ${provider['location'] ?? 'No location'}',
            ),
            trailing: ElevatedButton(
              onPressed: () => openProviderDialog(
                Map<String, dynamic>.from(provider),
              ),
              child: const Text('Edit'),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Categories'),
            Tab(text: 'Services'),
            Tab(text: 'Providers'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: TabBarView(
                controller: _tabController,
                children: [
                  buildCategoriesTab(),
                  buildServicesTab(),
                  buildProvidersTab(),
                ],
              ),
            ),
    );
  }
}
