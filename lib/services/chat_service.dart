import 'dart:convert';

import 'notification_service.dart';
import 'session_service.dart';

class ChatService {
  static const String _chatMessagesKey = 'chat_messages';

  static Future<List<Map<String, dynamic>>> _allMessages() async {
    final raw = await SessionService.getPreference(_chatMessagesKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final decoded = List<dynamic>.from(jsonDecode(raw));
    return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  static Future<void> _saveAllMessages(List<Map<String, dynamic>> items) async {
    await SessionService.savePreference(_chatMessagesKey, jsonEncode(items));
  }

  static String threadId(int providerId, int customerId) {
    return 'provider_${providerId}_customer_$customerId';
  }

  static Future<List<Map<String, dynamic>>> getThreadMessages({
    required int providerId,
    required int customerId,
  }) async {
    final items = await _allMessages();
    final id = threadId(providerId, customerId);
    final filtered = items.where((item) => item['thread_id'] == id).toList();
    filtered.sort(
      (a, b) => (a['created_at'] ?? '').toString().compareTo(
        (b['created_at'] ?? '').toString(),
      ),
    );
    return filtered;
  }

  static Future<List<Map<String, dynamic>>> getProviderInbox(int providerId) async {
    final items = await _allMessages();
    final filtered = items
        .where((item) => item['provider_id'] == providerId)
        .toList();

    final Map<String, Map<String, dynamic>> latestByThread = {};
    for (final item in filtered) {
      final key = item['thread_id']?.toString() ?? '';
      final existing = latestByThread[key];
      if (existing == null ||
          (existing['created_at'] ?? '').toString().compareTo(
                (item['created_at'] ?? '').toString(),
              ) <
              0) {
        latestByThread[key] = item;
      }
    }

    final results = latestByThread.values.toList();
    results.sort(
      (a, b) => (b['created_at'] ?? '').toString().compareTo(
        (a['created_at'] ?? '').toString(),
      ),
    );
    return results;
  }

  static Future<void> sendMessage({
    required int providerId,
    required String providerName,
    required int customerId,
    required String customerName,
    required int senderId,
    required String senderRole,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final items = await _allMessages();
    items.add({
      'thread_id': threadId(providerId, customerId),
      'provider_id': providerId,
      'provider_name': providerName,
      'customer_id': customerId,
      'customer_name': customerName,
      'sender_id': senderId,
      'sender_role': senderRole,
      'text': trimmed,
      'created_at': DateTime.now().toIso8601String(),
    });
    await _saveAllMessages(items);

    final isProviderSender = senderRole.toUpperCase() == 'PROVIDER' ||
        senderRole.toUpperCase() == 'DOCTOR';
    await NotificationService.showNotification(
      title: isProviderSender ? 'Message from $providerName' : 'New customer message',
      body: isProviderSender
          ? trimmed
          : '$customerName: $trimmed',
    );
  }
}
