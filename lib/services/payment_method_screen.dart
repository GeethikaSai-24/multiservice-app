import 'package:flutter/material.dart';
import 'payment_screen.dart';

class PaymentMethodScreen extends StatelessWidget {
  final int bookingId;
  final double amount;

  const PaymentMethodScreen({
    super.key,
    required this.bookingId,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Choose Payment Method")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // 🔵 ONLINE PAYMENT
            Card(
              child: ListTile(
                leading: const Icon(Icons.payment),
                title: const Text("Online Payment"),
                subtitle: const Text("Pay now using card/UPI"),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PaymentScreen(bookingId: bookingId, amount: amount),
                    ),
                  );

                  if (result == true) {
                    Navigator.pop(context, true);
                  }
                },
              ),
            ),

            const SizedBox(height: 20),

            // 🟢 OFFLINE PAYMENT
            Card(
              child: ListTile(
                leading: const Icon(Icons.money),
                title: const Text("Pay at Service"),
                subtitle: const Text("Pay after service completion"),
                onTap: () {
                  Navigator.pop(context, true);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
