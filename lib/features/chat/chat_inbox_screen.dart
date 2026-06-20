import 'package:flutter/material.dart';

import '../../services/chat_service.dart';
import 'chat_screen.dart';

class ChatInboxScreen extends StatefulWidget {
  final int providerId;
  final String providerName;

  const ChatInboxScreen({
    super.key,
    required this.providerId,
    required this.providerName,
  });

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  List<Map<String, dynamic>> threads = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadThreads();
  }

  Future<void> loadThreads() async {
    final items = await ChatService.getProviderInbox(widget.providerId);
    if (!mounted) return;
    setState(() {
      threads = items;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Messages')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : threads.isEmpty
          ? const Center(child: Text('No customer messages yet'))
          : RefreshIndicator(
              onRefresh: loadThreads,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: threads.length,
                itemBuilder: (context, index) {
                  final thread = threads[index];
                  return Card(
                    child: ListTile(
                      title: Text(thread['customer_name']?.toString() ?? 'Customer'),
                      subtitle: Text(
                        thread['text']?.toString() ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        (thread['created_at'] ?? '')
                            .toString()
                            .replaceFirst('T', '\n')
                            .substring(0, 16),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 11),
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              providerId: widget.providerId,
                              providerName: widget.providerName,
                              customerId: thread['customer_id'] ?? 0,
                              customerName:
                                  thread['customer_name']?.toString() ??
                                  'Customer',
                            ),
                          ),
                        );
                        loadThreads();
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
