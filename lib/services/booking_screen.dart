import 'dart:convert';

import 'package:flutter/material.dart';

import 'api_service.dart';
import 'notification_service.dart';
import 'payment_method_screen.dart';
import 'booking_success_screen.dart';
import 'session_service.dart';

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
  static const String _savedAddressesKey = 'saved_addresses';
  DateTime? selectedDate;
  String consultationType = "offline";
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  late List<String> slots;
  List<String> bookedSlots = [];
  String? selectedSlot;
  bool isDateUnavailable = false;
  String? availabilityMessage;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    slots = generateSlots();
    loadSavedAddresses();
  }

  List<String> savedAddresses = [];

  List<String> generateSlots() {
    final generatedSlots = <String>[];
    for (int hour = 9; hour < 18; hour++) {
      generatedSlots.add('${hour.toString().padLeft(2, '0')}:00');
    }
    return generatedSlots;
  }

  Future<void> loadSavedAddresses() async {
    final raw = await SessionService.getPreference(_savedAddressesKey);
    if (raw == null || raw.isEmpty || !mounted) return;
    final decoded = List<String>.from(jsonDecode(raw));
    setState(() {
      savedAddresses = decoded;
      if (decoded.isNotEmpty && addressController.text.trim().isEmpty) {
        addressController.text = decoded.first;
      }
    });
  }

  Future<void> saveAddressIfNeeded(String address) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return;
    final updated = [trimmed, ...savedAddresses.where((item) => item != trimmed)]
        .take(5)
        .toList();
    await SessionService.savePreference(
      _savedAddressesKey,
      jsonEncode(updated),
    );
    if (!mounted) return;
    setState(() {
      savedAddresses = updated;
    });
  }

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

  Future<void> fetchBookedSlots() async {
    if (selectedDate == null) return;

    final response = await ApiService.get(
      '/api/bookings/slots/?provider=${widget.providerId}&date=${selectedDate.toString().split(' ')[0]}',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        isDateUnavailable = data['unavailable'] == true;
        bookedSlots = List<String>.from(data['slots'] ?? const []);
        availabilityMessage = isDateUnavailable
            ? 'This provider marked the selected day as unavailable.'
            : null;
      });
    }
  }

  Future<bool> checkAvailability() async {
    final response = await ApiService.get(
      "/api/bookings/check-availability/?provider=${widget.providerId}&date=${selectedDate.toString().split(' ')[0]}",
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      availabilityMessage = data['message'];
      return data['available'];
    }

    return false;
  }

  Future<void> bookService() async {
    if (isDateUnavailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This date is marked unavailable")),
      );
      return;
    }

    if (selectedDate == null || selectedSlot == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Select date and slot")));
      return;
    }

    if (widget.isDoctor) {
      final available = await checkAvailability();
      if (!available) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              availabilityMessage ?? "Doctor not available on this date",
            ),
          ),
        );
        return;
      }
    }

    final paymentResult = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PaymentMethodScreen(
          bookingId: 0,
          amount: 500,
        ),
      ),
    );

    if (paymentResult is! Map<String, dynamic>) {
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    final response = await ApiService.postAuthenticated(
      '/api/bookings/',
      body: {
        "provider": widget.providerId,
        "date": selectedDate.toString().split(' ')[0],
        "time": "$selectedSlot:00",
        "address": addressController.text,
        "phone_number": phoneController.text,
        "description": descriptionController.text,
        "payment_method": paymentResult['payment_method'],
        "payment_status": paymentResult['payment_status'],
        "amount": 500,
        if (widget.isDoctor) "consultation_type": consultationType,
      },
    );

    if (response.statusCode == 201) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final booking = jsonDecode(response.body);
      await saveAddressIfNeeded(addressController.text);

      final bookingDateTime = DateTime.parse(
        "${selectedDate.toString().split(' ')[0]} $selectedSlot:00",
      );
      final reminderTime = bookingDateTime.subtract(const Duration(minutes: 30));

      await NotificationService.scheduleNotification(
        title: "Upcoming Booking",
        body: "Your booking at ${selectedSlot ?? 'the scheduled time'} starts in 30 minutes",
        scheduledTime: reminderTime,
        bookingTime: bookingDateTime,
      );

      await NotificationService.showNotification(
        title: "Booking Confirmed",
        body: "Your booking with ${widget.providerName} is confirmed.",
      );

      messenger.showSnackBar(
        const SnackBar(content: Text("Reminder scheduled")),
      );
      setState(() {
        isSubmitting = false;
      });

      messenger.showSnackBar(
        const SnackBar(content: Text("Booking confirmed")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
        builder: (_) => BookingSuccessScreen(
          booking: booking,
          providerName: widget.providerName,
          date: booking['date'] ?? selectedDate.toString().split(' ')[0],
          time: selectedSlot ?? 'Time not set',
        ),
        ),
      );
      return;
    } else {
      final error = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error['error'] ??
                error['detail'] ??
                "Booking failed. Please login again and retry.",
          ),
        ),
      );
    }

    if (mounted && response.statusCode != 201) {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    addressController.dispose();
    phoneController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.providerName)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    onSelected: isBooked || isDateUnavailable
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
              if (availabilityMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  availabilityMessage!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const Text(
                "Your Address",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (savedAddresses.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: savedAddresses.map((address) {
                    return ActionChip(
                      label: Text(
                        address,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () {
                        setState(() {
                          addressController.text = address;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
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
              const Text(
                "Add Instructions (Optional)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : bookService,
                  child: isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Confirm Booking"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
