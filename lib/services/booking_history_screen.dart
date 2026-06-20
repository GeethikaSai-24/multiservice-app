import 'dart:convert';

import 'package:flutter/material.dart';

import 'api_service.dart';
import 'notification_service.dart';
import 'session_service.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  static const String _snapshotKey = 'booking_status_snapshot';
  List bookings = [];
  bool isLoading = true;
  final List<String> _slots = List<String>.generate(
    9,
    (index) => '${(index + 9).toString().padLeft(2, '0')}:00',
  );

  String _shortTime(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) return 'Time not set';
    return text.length >= 5 ? text.substring(0, 5) : text;
  }

  String? _cancellationLabel(Map booking) {
    if (booking['status'] != 'cancelled') return null;
    final source = (booking['cancellation_source'] ?? '').toString().toLowerCase();
    switch (source) {
      case 'customer':
        return 'Cancelled by you';
      case 'provider':
        return 'Cancelled by provider';
      case 'admin':
        return 'Cancelled by admin';
      default:
        return 'Cancelled';
    }
  }

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    try {
      final response = await ApiService.getAuthenticated('/api/bookings/user/');

      if (response.statusCode == 200) {
        final decodedBookings = List<Map<String, dynamic>>.from(
          jsonDecode(response.body),
        );
        await _notifyBookingUpdates(decodedBookings);
        setState(() {
          bookings = decodedBookings;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _notifyBookingUpdates(
    List<Map<String, dynamic>> currentBookings,
  ) async {
    final rawSnapshot = await SessionService.getPreference(_snapshotKey);
    final Map<String, dynamic> previousSnapshot = rawSnapshot == null || rawSnapshot.isEmpty
        ? {}
        : Map<String, dynamic>.from(jsonDecode(rawSnapshot));

    if (previousSnapshot.isNotEmpty) {
      for (final booking in currentBookings) {
        final bookingId = booking['id']?.toString();
        if (bookingId == null) continue;

        final currentState = {
          'status': booking['status'],
          'refund_status': booking['refund_status'],
          'cancellation_source': booking['cancellation_source'],
        };
        final previousState = previousSnapshot[bookingId];
        if (previousState is! Map) continue;

        if (previousState['status'] != currentState['status']) {
          if (currentState['status'] == 'cancelled' &&
              currentState['cancellation_source'] == 'provider') {
            await NotificationService.showNotification(
              title: 'Booking Cancelled',
              body:
                  '${booking['provider_name'] ?? 'Your provider'} cancelled your booking.',
            );
          } else if (currentState['status'] == 'confirmed') {
            await NotificationService.showNotification(
              title: 'Booking Confirmed',
              body:
                  '${booking['provider_name'] ?? 'Your provider'} confirmed your booking.',
            );
          } else if (currentState['status'] == 'completed') {
            await NotificationService.showNotification(
              title: 'Service Completed',
              body:
                  'Your booking with ${booking['provider_name'] ?? 'the provider'} is marked completed.',
            );
          }
        }

        if (previousState['refund_status'] != currentState['refund_status'] &&
            currentState['refund_status'] == 'processed') {
          await NotificationService.showNotification(
            title: 'Refund Completed',
            body:
                'Refund for your booking with ${booking['provider_name'] ?? 'the provider'} has been marked completed.',
          );
        }
      }
    }

    final nextSnapshot = <String, Map<String, dynamic>>{};
    for (final booking in currentBookings) {
      final bookingId = booking['id']?.toString();
      if (bookingId == null) continue;
      nextSnapshot[bookingId] = {
        'status': booking['status'],
        'refund_status': booking['refund_status'],
        'cancellation_source': booking['cancellation_source'],
      };
    }
    await SessionService.savePreference(_snapshotKey, jsonEncode(nextSnapshot));
  }

  Future<void> cancelBooking(int bookingId) async {
    final response = await ApiService.postAuthenticated(
      '/api/bookings/$bookingId/cancel/',
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Booking cancelled")));
      fetchBookings();
    } else {
      final body = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(body['error'] ?? 'Unable to cancel booking')),
      );
    }
  }

  Future<void> removeFromHistory(int bookingId) async {
    final response = await ApiService.postAuthenticated(
      '/api/bookings/$bookingId/hide/',
    );

    if (response.statusCode == 200) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking removed from history')),
      );
      fetchBookings();
    } else {
      final body = jsonDecode(response.body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(body['error'] ?? 'Unable to remove booking history'),
        ),
      );
    }
  }

  Future<void> confirmRemoveFromHistory(int bookingId) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove booking from history?'),
          content: const Text(
            'This will hide the booking from your history list, but it will stay in the system records.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep it'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (shouldRemove == true) {
      await removeFromHistory(bookingId);
    }
  }

  Future<List<String>> _fetchBookedSlots(int providerId, String date) async {
    final response = await ApiService.get(
      '/api/bookings/slots/?provider=$providerId&date=$date',
    );
    if (response.statusCode != 200) {
      return [];
    }
    final data = jsonDecode(response.body);
    return List<String>.from(data['slots'] ?? const []);
  }

  Future<void> rescheduleBooking(Map booking) async {
    DateTime? selectedDate = DateTime.tryParse(booking['date']?.toString() ?? '');
    String? selectedSlot = _shortTime(booking['time']);
    List<String> bookedSlots = [];
    String? infoMessage;
    bool isSaving = false;

    Future<void> loadSlots(StateSetter setModalState) async {
      if (selectedDate == null) return;
      final formattedDate = selectedDate!.toIso8601String().split('T')[0];
      final slots = await _fetchBookedSlots(booking['provider'], formattedDate);
      if (!mounted) return;
      setModalState(() {
        bookedSlots = slots;
        if (selectedSlot != null &&
            bookedSlots.contains(selectedSlot) &&
            selectedSlot != _shortTime(booking['time'])) {
          selectedSlot = null;
        }
      });
    }

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> chooseDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2030),
              );
              if (picked == null) return;
              setModalState(() {
                selectedDate = picked;
                infoMessage = null;
                selectedSlot = null;
              });
              await loadSlots(setModalState);
            }

            Future<void> saveReschedule() async {
              if (selectedDate == null || selectedSlot == null) {
                setModalState(() {
                  infoMessage = 'Choose a new date and slot';
                });
                return;
              }

              setModalState(() {
                isSaving = true;
                infoMessage = null;
              });

              final formattedDate = selectedDate!.toIso8601String().split('T')[0];
              final response = await ApiService.postAuthenticated(
                '/api/bookings/${booking['id']}/reschedule/',
                body: {
                  'date': formattedDate,
                  'time': '$selectedSlot:00',
                },
              );

              final body = jsonDecode(response.body);
              if (!mounted) return;

              if (response.statusCode == 200) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Booking rescheduled')),
                );
                fetchBookings();
              } else {
                setModalState(() {
                  infoMessage = body['error'] ?? 'Unable to reschedule booking';
                  isSaving = false;
                });
              }
            }

            return AlertDialog(
              title: const Text('Reschedule Booking'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current: ${booking['date']} - ${_shortTime(booking['time'])}'),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: chooseDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        selectedDate == null
                            ? 'Choose new date'
                            : selectedDate!.toIso8601String().split('T')[0],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _slots.map((slot) {
                        final isCurrentSlot =
                            slot == _shortTime(booking['time']) &&
                            selectedDate?.toIso8601String().split('T')[0] ==
                                booking['date'];
                        final isBooked =
                            bookedSlots.contains(slot) && !isCurrentSlot;
                        return ChoiceChip(
                          label: Text(slot),
                          selected: selectedSlot == slot,
                          onSelected: isBooked
                              ? null
                              : (_) {
                                  setModalState(() {
                                    selectedSlot = slot;
                                  });
                                },
                        );
                      }).toList(),
                    ),
                    if (infoMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        infoMessage!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : saveReschedule,
                  child: Text(isSaving ? 'Saving...' : 'Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking['provider_name'] ?? "Provider",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "${booking['date']} - ${_shortTime(booking['time'])}",
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Payment: ${booking['payment_status'] ?? 'pending'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              if ((booking['refund_status'] ?? 'not_applicable') !=
                                  'not_applicable')
                                Text(
                                  'Refund: ${booking['refund_status']}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange,
                                  ),
                                ),
                              if (_cancellationLabel(booking) != null)
                                Text(
                                  _cancellationLabel(booking)!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 130),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
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
                              const SizedBox(height: 8),
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
                              if (booking['status'] != 'cancelled')
                                const SizedBox(height: 6),
                              if (booking['status'] != 'cancelled' &&
                                  booking['status'] != 'completed')
                                GestureDetector(
                                  onTap: () {
                                    rescheduleBooking(booking);
                                  },
                                  child: const Text(
                                    "Reschedule",
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              if (booking['status'] != 'cancelled' &&
                                  booking['status'] != 'completed')
                                const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () {
                                  confirmRemoveFromHistory(booking['id']);
                                },
                                child: const Text(
                                  "Remove",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
