import 'package:flutter/material.dart';
import 'package:multiservice_frontend/services/provider_list_screen.dart';

class ServiceListScreen extends StatelessWidget {
  final String categoryName;
  final List services;
  final String location;

  const ServiceListScreen({
    super.key,
    required this.categoryName,
    required this.services,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(categoryName)),
      body: ListView.builder(
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];

          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text(service['name']),
              subtitle: Text(service['description']),
              trailing: Text("Rs ${service['base_price']}"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProviderListScreen(
                      serviceId: service['id'],
                      serviceName: service['name'],
                      location: location,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
