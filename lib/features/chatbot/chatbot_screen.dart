import 'package:flutter/material.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController controller = TextEditingController();
  final List<Map<String, dynamic>> _faqLibrary = [
    {
      'keywords': ['book', 'booking', 'slot', 'appointment', 'schedule'],
      'answer':
          'To book a service, open a category, choose a service, open a provider, pick date and slot, add your address and phone number, then complete payment or choose pay at service.',
    },
    {
      'keywords': ['payment', 'upi', 'card', 'wallet', 'banking', 'checkout'],
      'answer':
          'The app uses a premium demo checkout. Users can select UPI, card, net banking, or wallet, fill the method details, and confirm payment securely inside the app.',
    },
    {
      'keywords': ['refund', 'refunded', 'refunds'],
      'answer':
          'If a paid booking is cancelled, the refund status is tracked. The provider sees the booking amount and can mark the refund as completed after returning the payment.',
    },
    {
      'keywords': ['cancel', 'cancellation', 'cancelled'],
      'answer':
          'Customers can cancel from My Bookings. Providers can cancel from their dashboard. The history screen also shows whether the booking was cancelled by you, by the provider, or by admin.',
    },
    {
      'keywords': ['reschedule', 'change date', 'change slot', 'move booking'],
      'answer':
          'Active bookings can be rescheduled from My Bookings. The app checks the provider availability again and updates the booking to a new date and time slot.',
    },
    {
      'keywords': ['provider', 'service provider', 'not shown', 'location'],
      'answer':
          'Providers are filtered by service and location. If the selected location has no matches, the app can fall back to showing all providers for that service.',
    },
    {
      'keywords': ['doctor', 'specialization', 'hospital', 'clinic'],
      'answer':
          'Doctors can register with specialization, hospital or clinic name, experience, and license details. They can also mark unavailable dates so customers cannot book those days.',
    },
    {
      'keywords': ['approval', 'approve', 'reject', 'admin'],
      'answer':
          'Admin reviews pending provider and doctor registrations, checks the submitted profile details, and can approve or reject them from the admin dashboard.',
    },
    {
      'keywords': ['earnings', 'income', 'monthly', 'total earnings', 'revenue'],
      'answer':
          'Provider dashboard shows current-month earnings and total earnings till date based on completed bookings. Refunded cancellations are excluded from earnings.',
    },
    {
      'keywords': ['history', 'remove history', 'delete booking'],
      'answer':
          'Both customers and providers can remove a booking from their visible history. This hides it from that user dashboard but keeps the record in the system.',
    },
    {
      'keywords': ['notification', 'reminder', 'alert'],
      'answer':
          'The app can show an instant booking confirmation notification and also schedule a reminder 30 minutes before the booking time. It can also alert the customer when a booking gets confirmed, cancelled by the provider, or marked refunded after the booking list refreshes.',
    },
    {
      'keywords': ['register', 'registration', 'sign up', 'signup'],
      'answer':
          'Registration now includes common account fields plus role-based fields. Customers see personal details, providers see service-related fields, and doctors see specialization and clinic details.',
    },
    {
      'keywords': ['chatbot', 'assistant', 'help', 'support'],
      'answer':
          'I can help with bookings, payments, cancellations, refunds, approvals, provider visibility, dashboards, reminders, and rescheduling.',
    },
    {
      'keywords': ['hello', 'hi', 'hey'],
      'answer':
          'Hi! Ask me anything about bookings, payments, refunds, approvals, providers, or dashboard features.',
    },
    {
      'keywords': ['contact', 'phone', 'call provider'],
      'answer':
          'Customers can view the provider contact number on booking-related screens and use the call button to contact the provider directly.',
    },
    {
      'keywords': ['available', 'unavailable', 'not available', 'leave'],
      'answer':
          'Providers and doctors can mark specific dates as unavailable. If you try to book on those dates, the app will show that the provider is unavailable for that day.',
    },
    {
      'keywords': ['service category', 'service', 'which service'],
      'answer':
          'The app follows category to service to provider flow. First choose a service category, then a service, and then see the providers linked to that service.',
    },
    {
      'keywords': ['customer', 'user account', 'my account', 'profile'],
      'answer':
          'Customers can register, browse services, book slots, pay, cancel, reschedule, track refunds, and manage booking history from their account.',
    },
    {
      'keywords': ['approval queue', 'pending approval', 'pending registration'],
      'answer':
          'The admin approval queue shows providers and doctors waiting for approval. Admin can inspect their submitted details and then approve or reject them.',
    },
    {
      'keywords': ['dashboard', 'admin dashboard', 'provider dashboard'],
      'answer':
          'The admin dashboard shows users, providers, bookings, pending items, and approval queue. The provider dashboard shows bookings, refunds, earnings, unavailable dates, and profile management.',
    },
    {
      'keywords': ['address', 'instructions', 'notes'],
      'answer':
          'When booking a service, the customer can add address, phone number, and additional instructions. Providers can view those details in their dashboard.',
    },
    {
      'keywords': ['review', 'rating', 'ratings'],
      'answer':
          'Customers can leave ratings and reviews for providers from the provider detail page, which helps build trust and improve service quality.',
    },
    {
      'keywords': ['login', 'role', 'customer login', 'provider login', 'doctor login'],
      'answer':
          'The selected login role must match the account role. Customer, provider, doctor, and admin accounts each follow their own dashboard or home flow.',
    },
    {
      'keywords': ['payment method', 'pay at service', 'cash'],
      'answer':
          'Customers can pay online in the demo checkout or choose pay at service. The payment method and payment status are stored with the booking.',
    },
  ];

  final List<Map<String, String>> messages = [
    {
      'role': 'bot',
      'text':
          'Hello! I am your booking assistant. Ask me about bookings, payments, providers, cancellations, refunds, or approvals.',
    },
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String _replyFor(String input) {
    final text = input.toLowerCase();
    int bestScore = 0;
    String? bestAnswer;

    for (final item in _faqLibrary) {
      final keywords = List<String>.from(item['keywords'] as List);
      final score = keywords.where((keyword) => text.contains(keyword)).length;
      if (score > bestScore) {
        bestScore = score;
        bestAnswer = item['answer'] as String;
      }
    }

    if (bestScore > 0 && bestAnswer != null) {
      return bestAnswer;
    }

    return 'I can help with bookings, rescheduling, payments, refunds, providers, doctors, approvals, earnings, notifications, and dashboard features. Try asking something like "How do I reschedule a booking?" or "Will I get a reminder before my booking?"';
  }

  void _sendMessage([String? preset]) {
    final text = (preset ?? controller.text).trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add({'role': 'user', 'text': text});
      messages.add({'role': 'bot', 'text': _replyFor(text)});
      controller.clear();
    });
  }

  Widget _bubble(Map<String, String> message) {
    final isBot = message['role'] == 'bot';
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: isBot ? Colors.white : const Color(0xFF0F6CBD),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isBot
              ? const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          message['text'] ?? '',
          style: TextStyle(color: isBot ? Colors.black87 : Colors.white),
        ),
      ),
    );
  }

  Widget _quickPrompt(String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () => _sendMessage(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: const Text('Help Assistant')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F6CBD), Color(0xFF14B8A6)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Support',
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 8),
                Text(
                  'Ask about bookings, reminders, refunds, approvals, or dashboards',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 54,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                _quickPrompt('How do I book a slot?'),
                const SizedBox(width: 8),
                _quickPrompt('How does payment work?'),
                const SizedBox(width: 8),
                _quickPrompt('How do provider approvals work?'),
                const SizedBox(width: 8),
                _quickPrompt('How do cancellations work?'),
                const SizedBox(width: 8),
                _quickPrompt('How do I reschedule a booking?'),
                const SizedBox(width: 8),
                _quickPrompt('How does refund work after cancellation?'),
                const SizedBox(width: 8),
                _quickPrompt('Why are providers not showing?'),
                const SizedBox(width: 8),
                _quickPrompt('How are monthly earnings calculated?'),
                const SizedBox(width: 8),
                _quickPrompt('Will I get a booking reminder?'),
                const SizedBox(width: 8),
                _quickPrompt('How do I contact the provider?'),
                const SizedBox(width: 8),
                _quickPrompt('What if the provider is unavailable?'),
                const SizedBox(width: 8),
                _quickPrompt('Can I pay at service instead?'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: messages.length,
              itemBuilder: (context, index) => _bubble(messages[index]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Ask something...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
