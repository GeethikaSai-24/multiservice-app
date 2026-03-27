import 'package:flutter/material.dart';

class PaymentScreen extends StatelessWidget {
  final int bookingId;
  final double amount;

  const PaymentScreen({
    super.key,
    required this.bookingId,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            Text("Total Amount", style: TextStyle(fontSize: 18)),

            const SizedBox(height: 10),

            Text(
              "₹$amount",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                // 🔥 SIMULATE SUCCESS
                Navigator.pop(context, true);
              },
              child: const Text("Pay Now"),
            ),
          ],
        ),
      ),
    );
  }
}
