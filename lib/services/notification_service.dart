import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'session_service.dart';

class NotificationService {
  static const String _historyKey = 'notification_history';
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(settings);

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'instant_channel',
      'Instant Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);
    await _notifications.show(0, title, body, details);
    await _saveNotificationRecord(title: title, body: body, type: 'instant');
  }

  static Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    DateTime? bookingTime,
  }) async {
    await _notifications.zonedSchedule(
      0,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    await _saveNotificationRecord(
      title: title,
      body: body,
      type: 'scheduled',
      scheduledTime: scheduledTime,
      bookingTime: bookingTime,
    );
  }

  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  static Future<List<Map<String, dynamic>>> getNotificationHistory() async {
    final raw = await SessionService.getPreference(_historyKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final decoded = List<dynamic>.from(jsonDecode(raw));
    return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  static Future<void> clearHistory() async {
    await SessionService.savePreference(_historyKey, jsonEncode(<Map<String, dynamic>>[]));
  }

  static Future<void> _saveNotificationRecord({
    required String title,
    required String body,
    required String type,
    DateTime? scheduledTime,
    DateTime? bookingTime,
  }) async {
    final items = await getNotificationHistory();
    items.insert(0, {
      'title': title,
      'body': body,
      'type': type,
      'created_at': DateTime.now().toIso8601String(),
      if (scheduledTime != null) 'scheduled_for': scheduledTime.toIso8601String(),
      if (bookingTime != null) 'booking_time': bookingTime.toIso8601String(),
    });
    final trimmed = items.take(40).toList();
    await SessionService.savePreference(_historyKey, jsonEncode(trimmed));
  }
}
