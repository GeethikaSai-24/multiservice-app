import 'package:flutter/material.dart';

import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    final items = await NotificationService.getNotificationHistory();
    if (!mounted) return;
    setState(() {
      notifications = items;
      isLoading = false;
    });
  }

  Future<void> clearNotifications() async {
    await NotificationService.clearHistory();
    await loadNotifications();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification history cleared')),
    );
  }

  String _formatTime(String? value) {
    if (value == null || value.isEmpty) return 'Unknown time';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final date = parsed.toLocal();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _scheduledLabel(Map<String, dynamic> item) {
    final scheduledFor = item['scheduled_for']?.toString();
    final bookingTime = item['booking_time']?.toString();
    if (scheduledFor == null) return '';
    if (bookingTime != null && bookingTime.isNotEmpty) {
      return 'Reminder at ${_formatTime(scheduledFor)}';
    }
    return 'Scheduled for ${_formatTime(scheduledFor)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: clearNotifications,
              child: const Text('Clear'),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? const Center(child: Text('No notifications yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final item = notifications[index];
                final scheduledFor = item['scheduled_for']?.toString();
                final bookingTime = item['booking_time']?.toString();
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title']?.toString() ?? 'Notification',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(item['body']?.toString() ?? ''),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(
                              label: Text(
                                (item['type']?.toString() ?? 'instant').toUpperCase(),
                              ),
                            ),
                            if (scheduledFor != null)
                              Chip(
                                label: Text(_scheduledLabel(item)),
                              ),
                            if (bookingTime != null)
                              Chip(
                                label: Text(
                                  'Booking ${_formatTime(bookingTime)}',
                                ),
                              ),
                            Chip(
                              label: Text(
                                'Saved ${_formatTime(item['created_at']?.toString())}',
                              ),
                            ),
                          ],
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
