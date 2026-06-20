import 'package:flutter/material.dart';

import '../../services/chat_service.dart';
import '../../services/session_service.dart';

class ChatScreen extends StatefulWidget {
  final int providerId;
  final String providerName;
  final int customerId;
  final String customerName;

  const ChatScreen({
    super.key,
    required this.providerId,
    required this.providerName,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();
  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;
  Map<String, dynamic>? currentUser;

  @override
  void initState() {
    super.initState();
    loadThread();
  }

  Future<void> loadThread() async {
    final user = await SessionService.getCurrentUser();
    final items = await ChatService.getThreadMessages(
      providerId: widget.providerId,
      customerId: widget.customerId,
    );
    if (!mounted) return;
    setState(() {
      currentUser = user;
      messages = items;
      isLoading = false;
    });
  }

  Future<void> sendMessage() async {
    final text = controller.text.trim();
    if (text.isEmpty || currentUser == null) return;

    await ChatService.sendMessage(
      providerId: widget.providerId,
      providerName: widget.providerName,
      customerId: widget.customerId,
      customerName: widget.customerName,
      senderId: currentUser!['id'] ?? 0,
      senderRole: currentUser!['role']?.toString() ?? 'USER',
      text: text,
    );

    controller.clear();
    await loadThread();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = currentUser?['role']?.toString().toUpperCase() ?? 'USER';
    final isProviderSide = role == 'PROVIDER' || role == 'DOCTOR';
    final title = isProviderSide ? widget.customerName : widget.providerName;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            color: Colors.blue.withOpacity(0.06),
            child: Text(
              isProviderSide
                  ? 'Reply to customer messages and keep them updated.'
                  : 'Chat with your provider about booking details and timing.',
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                ? const Center(child: Text('No messages yet'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMine =
                          message['sender_id'] == currentUser?['id'];
                      return Align(
                        alignment: isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          constraints: const BoxConstraints(maxWidth: 300),
                          decoration: BoxDecoration(
                            color: isMine
                                ? const Color(0xFF0F6CBD)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: isMine
                                ? null
                                : const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message['text']?.toString() ?? '',
                                style: TextStyle(
                                  color: isMine ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                (message['created_at'] ?? '')
                                    .toString()
                                    .replaceFirst('T', ' ')
                                    .substring(0, 16),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isMine
                                      ? Colors.white70
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: sendMessage,
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
