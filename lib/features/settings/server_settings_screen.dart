import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  final TextEditingController baseUrlController = TextEditingController();
  bool isSaving = false;
  bool isTesting = false;

  String get normalizedPreview =>
      ApiService.normalizeBaseUrl(baseUrlController.text);

  @override
  void initState() {
    super.initState();
    loadBaseUrl();
  }

  Future<void> loadBaseUrl() async {
    final currentBaseUrl = await ApiService.getBaseUrl();
    if (!mounted) return;
    setState(() {
      baseUrlController.text = currentBaseUrl;
    });
  }

  Future<void> saveBaseUrl() async {
    setState(() {
      isSaving = true;
    });

    try {
      final normalized = ApiService.normalizeBaseUrl(baseUrlController.text);
      await ApiService.saveBaseUrl(normalized);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Server saved: $normalized')),
      );
      Navigator.pop(context, normalized);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save server address')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> testConnection() async {
    setState(() {
      isTesting = true;
    });

    try {
      final normalized = ApiService.normalizeBaseUrl(baseUrlController.text);
      await ApiService.saveBaseUrl(normalized);
      final canReach = await ApiService.canReachServer();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            canReach
                ? 'Connection successful'
                : 'Server saved, but backend is not reachable right now.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to test server connection')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isTesting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    baseUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Server Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Backend server address',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use your ngrok URL for demos, or your laptop IP on the same network. Common mistakes like missing http:// or typing .8000 instead of :8000 are corrected automatically.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: baseUrlController,
              keyboardType: TextInputType.url,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Base URL',
                border: OutlineInputBorder(),
                hintText: 'https://your-tunnel.ngrok-free.dev',
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Saved as: $normalizedPreview',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : saveBaseUrl,
                child: isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Server'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: isTesting ? null : testConnection,
                child: isTesting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Test Connection'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
