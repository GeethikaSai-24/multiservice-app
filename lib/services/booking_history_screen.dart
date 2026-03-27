import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  List bookings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  // 🔥 FETCH BOOKINGS
  Future<void> fetchBookings() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/bookings/user/?user=1'),
      );

      if (response.statusCode == 200) {
        setState(() {
          bookings = jsonDecode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      print(e);
      setState(() {
        isLoading = false;
      });
    }
  }

  // 🔥 CANCEL BOOKING
  Future<void> cancelBooking(int bookingId) async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/api/bookings/$bookingId/cancel/'),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Booking Cancelled ❌")));

      fetchBookings(); // refresh
    }
  }

  // 🎨 STATUS COLOR
  Color getStatusColor(String status) {
    switch (status) {
      case "confirmed":
        return Colors.green;
      case "cancelled":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Bookings")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : bookings.isEmpty
          ? const Center(child: Text("No bookings yet"))
          : ListView.builder(
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),

                    // ✅ PROVIDER NAME
                    title: Text(
                      booking['provider_name'] ?? "Provider",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    // 📅 DATE + TIME
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        "${booking['date']} • ${booking['time'].substring(0, 5)}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),

                    // 🔥 STATUS + CANCEL
                    trailing: SizedBox(
                      width: 90, // 👈 prevents overflow
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Status
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: getStatusColor(
                                booking['status'],
                              ).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              booking['status'],
                              style: TextStyle(
                                color: getStatusColor(booking['status']),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),

                          const SizedBox(height: 4),

                          // Cancel button
                          if (booking['status'] != 'cancelled')
                            GestureDetector(
                              onTap: () {
                                cancelBooking(booking['id']);
                              },
                              child: const Text(
                                "Cancel",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
