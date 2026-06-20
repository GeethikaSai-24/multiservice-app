import 'package:flutter/material.dart';

class PaymentScreen extends StatefulWidget {
  final int bookingId;
  final double amount;
  final String paymentMethod;

  const PaymentScreen({
    super.key,
    required this.bookingId,
    required this.amount,
    required this.paymentMethod,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late String selectedMethod;
  final upiController = TextEditingController(text: 'customer@upi');
  final cardNumberController = TextEditingController(
    text: '4111 1111 1111 1111',
  );
  final cardNameController = TextEditingController(text: 'Sudha');
  final bankController = TextEditingController(text: 'State Bank Demo');
  final walletController = TextEditingController(text: 'Phone Wallet');
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    selectedMethod = widget.paymentMethod == 'online'
        ? 'UPI'
        : widget.paymentMethod.toUpperCase();
  }

  @override
  void dispose() {
    upiController.dispose();
    cardNumberController.dispose();
    cardNameController.dispose();
    bankController.dispose();
    walletController.dispose();
    super.dispose();
  }

  Widget _methodChip(String label, IconData icon) {
    final isSelected = selectedMethod == label;
    return ChoiceChip(
      selected: isSelected,
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? Colors.white : Colors.grey.shade700,
      ),
      label: Text(label),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey.shade800,
        fontWeight: FontWeight.w600,
      ),
      selectedColor: const Color(0xFF0F6CBD),
      onSelected: (_) {
        setState(() {
          selectedMethod = label;
        });
      },
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF4F7FB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _methodForm() {
    switch (selectedMethod) {
      case 'Card':
        return Column(
          children: [
            _field('Card Number', cardNumberController),
            Row(
              children: [
                Expanded(child: _field('Card Holder', cardNameController)),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    'Expiry / CVV',
                    TextEditingController(text: '12/29 123'),
                  ),
                ),
              ],
            ),
          ],
        );
      case 'Net Banking':
        return Column(
          children: [
            _field('Bank Name', bankController),
            _field('Account Holder', cardNameController),
          ],
        );
      case 'Wallet':
        return Column(
          children: [
            _field('Wallet Name', walletController),
            _field('Registered Mobile', TextEditingController(text: '9876543210')),
          ],
        );
      case 'UPI':
      default:
        return Column(
          children: [
            _field('UPI ID', upiController),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Demo mode: this simulates opening a UPI app and returns payment success securely inside the app.',
              ),
            ),
          ],
        );
    }
  }

  Future<void> _pay() async {
    setState(() {
      isProcessing = true;
    });
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F6CBD), Color(0xFF14B8A6)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Secure checkout',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Rs ${widget.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Booking #${widget.bookingId} - $selectedMethod',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Accepted methods',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _methodChip('UPI', Icons.qr_code_2),
                _methodChip('Card', Icons.credit_card),
                _methodChip('Net Banking', Icons.account_balance),
                _methodChip('Wallet', Icons.account_balance_wallet_outlined),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$selectedMethod details',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _methodForm(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'What happens next?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('1. Payment is marked successful in the demo app.'),
                    Text('2. Booking is sent to the provider with full details.'),
                    Text(
                      '3. If the provider cancels after payment, refund status is tracked.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isProcessing ? null : _pay,
                icon: isProcessing
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_outline),
                label: Text(isProcessing ? 'Processing Payment...' : 'Pay Securely'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
