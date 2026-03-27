import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'payment_screen.dart';
import 'payment_method_screen.dart';
import 'package:multiservice_frontend/services/notification_service.dart';
import 'booking_details_screen.dart';

class BookingScreen extends StatefulWidget {
  final int providerId;
  final String providerName;
  final bool isDoctor;
  const BookingScreen({
    super.key,
    required this.providerId,
    required this.providerName,
    required this.isDoctor,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? selectedDate;
  String consultationType = "offline";
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  // ✅ GENERATED SLOTS
  late List<String> slots;
  TextEditingController descriptionController = TextEditingController();
  List<String> generateSlots() {
    List<String> slots = [];

    for (int hour = 9; hour < 18; hour++) {
      String formatted = hour.toString().padLeft(2, '0') + ":00";
      slots.add(formatted);
    }

    return slots;
  }

  List<String> bookedSlots = [];
  String? selectedSlot;

  @override
  void initState() {
    super.initState();
    slots = generateSlots(); // ✅ FIXED
  }

  // 📅 Pick Date
  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
        selectedSlot = null;
      });

      fetchBookedSlots();
    }
  }

  // 🔥 Fetch booked slots
  Future<void> fetchBookedSlots() async {
    if (selectedDate == null) return;

    final response = await http.get(
      Uri.parse(
        'http://127.0.0.1:8000/api/bookings/slots/?provider=${widget.providerId}&date=${selectedDate.toString().split(' ')[0]}',
      ),
    );

    if (response.statusCode == 200) {
      setState(() {
        bookedSlots = List<String>.from(jsonDecode(response.body));
      });
    }
  }

  // 📦 Book Service
  Future<void> bookService() async {
    if (selectedDate == null || selectedSlot == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Select date & slot")));
      return;
    }
    if (widget.isDoctor) {
      final available = await checkAvailability();

      if (!available) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Doctor not available on this date")),
        );
        return;
      }
    }
    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/api/bookings/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "user": 1,
        "provider": widget.providerId,
        "date": selectedDate.toString().split(' ')[0],
        "time": "$selectedSlot:00",
        "address": addressController.text,
        "phone_number": phoneController.text,
        "description": descriptionController.text,
        if (widget.isDoctor) "consultation_type": consultationType,
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Booking Confirmed ✅")));

      final booking = jsonDecode(response.body);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingDetailsScreen(booking: booking),
        ),
      );
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentMethodScreen(
            bookingId: booking['id'],
            amount: booking['amount'] ?? 500,
          ),
        ),
      );

      if (result == true) {
        // 🔥 CREATE BOOKING DATETIME

        DateTime bookingDateTime = DateTime.parse(
          "${selectedDate.toString().split(' ')[0]} $selectedSlot:00",
        );

        // 🔥 SET REMINDER (10 minutes before)
        DateTime reminderTime = bookingDateTime.subtract(
          const Duration(minutes: 10),
        );

        // 🔥 SCHEDULE NOTIFICATION
        NotificationService.scheduleNotification(
          title: "Upcoming Booking",
          body: "Your service is in 10 minutes",
          scheduledTime: reminderTime,
        );

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Booking Confirmed")));

        Navigator.pop(context);
      }
    } else {
      final error = jsonDecode(response.body);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error['error'] ?? "Booking failed")),
      );
    }
  }

  Future<bool> checkAvailability() async {
    final response = await http.get(
      Uri.parse(
        "http://127.0.0.1:8000/api/bookings/check-availability/?provider=${widget.providerId}&date=${selectedDate.toString().split(' ')[0]}",
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['available'];
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.providerName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👤 Provider Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(radius: 25, child: Icon(Icons.person)),
                    const SizedBox(width: 12),
                    Text(
                      widget.providerName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // 📅 DATE
            const Text(
              "Select Date",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: pickDate,
              child: Text(
                selectedDate == null
                    ? "Choose Date"
                    : selectedDate.toString().split(' ')[0],
              ),
            ),

            const SizedBox(height: 25),

            // ⏰ SLOTS
            const Text(
              "Select Time Slot",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),
            if (widget.isDoctor) ...[
              const Text(
                "Consultation Type",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  ChoiceChip(
                    label: const Text("Offline"),
                    selected: consultationType == "offline",
                    onSelected: (_) {
                      setState(() {
                        consultationType = "offline";
                      });
                    },
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text("Online"),
                    selected: consultationType == "online",
                    onSelected: (_) {
                      setState(() {
                        consultationType = "online";
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: slots.map((slot) {
                final isBooked = bookedSlots.contains(slot);

                return ChoiceChip(
                  label: Text(slot),
                  selected: selectedSlot == slot,
                  onSelected: isBooked
                      ? null
                      : (_) {
                          setState(() {
                            selectedSlot = slot;
                          });
                        },
                  selectedColor: Colors.blue,
                  disabledColor: Colors.grey.shade300,
                );
              }).toList(),
            ),

            const Spacer(),
            const SizedBox(height: 20),

            const SizedBox(height: 8),

            const Text(
              "Your Address",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                hintText: "Enter your full address",
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              "Phone Number",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: "Enter your phone number",
              ),
            ),
            const SizedBox(height: 20),

            Text(
              "Add Instructions (Optional)",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                // hintText:
                // "E.g. Bring cleaning supplies, call before arriving...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            // ✅ BOOK BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: bookService,
                child: const Text("Confirm Booking"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
