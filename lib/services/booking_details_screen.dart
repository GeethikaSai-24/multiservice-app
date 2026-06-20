import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BookingDetailsScreen extends StatelessWidget {
  final Map booking;

  const BookingDetailsScreen({super.key, required this.booking});

  Future<void> callNumber(String phone) async {
    final uri = Uri.parse("tel:$phone");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _cancellationLabel() {
    final source = (booking['cancellation_source'] ?? '').toString().toLowerCase();
    if (source == 'customer') return 'Cancelled by you';
    if (source == 'provider') return 'Cancelled by provider';
    if (source == 'admin') return 'Cancelled by admin';
    return 'Cancelled';
  }

  @override
  Widget build(BuildContext context) {
    final providerName = booking['provider_name'] ?? "Provider";
    final address = booking['address'] ?? "No address";
    final phone = booking['phone_number'] ?? "";
    final date = booking['date'] ?? '';
    final time = booking['time'] ?? '';
    final isCancelled = (booking['status'] ?? '') == 'cancelled';

    return Scaffold(
      appBar: AppBar(title: const Text("Booking Details")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              providerName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text("Date: $date"),
            Text("Time: $time"),
            if (isCancelled)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _cancellationLabel(),
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              "Address",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(address),
            const SizedBox(height: 20),
            const Text(
              "Contact",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(phone),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: phone.isEmpty ? null : () => callNumber(phone),
                icon: const Icon(Icons.call),
                label: const Text("Call Provider"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
