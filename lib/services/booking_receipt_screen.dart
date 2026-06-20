import 'package:flutter/material.dart';

class BookingReceiptScreen extends StatelessWidget {
  final Map booking;

  const BookingReceiptScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final providerName = booking['provider_name'] ?? booking['provider']?.toString() ?? 'Provider';
    final amount = booking['amount']?.toString() ?? '0';
    final paymentMethod = booking['payment_method']?.toString().toUpperCase() ?? 'N/A';
    final paymentStatus = booking['payment_status']?.toString().toUpperCase() ?? 'PENDING';
    final date = booking['date']?.toString() ?? 'Not set';
    final time = booking['time']?.toString() ?? 'Not set';

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Receipt')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F6CBD),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Receipt',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rs $amount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    paymentStatus,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _receiptRow('Booking ID', '#${booking['id'] ?? '--'}'),
                    _receiptRow('Provider', providerName),
                    _receiptRow('Date', date),
                    _receiptRow('Time', time),
                    _receiptRow('Payment Method', paymentMethod),
                    _receiptRow('Payment Status', paymentStatus),
                    _receiptRow(
                      'Address',
                      booking['address']?.toString().isNotEmpty == true
                          ? booking['address'].toString()
                          : 'Not added',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
