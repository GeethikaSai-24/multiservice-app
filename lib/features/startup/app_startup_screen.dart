import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../dashboard/dashboard_router.dart';
import '../settings/server_settings_screen.dart';

class AppStartupScreen extends StatefulWidget {
  const AppStartupScreen({super.key});

  @override
  State<AppStartupScreen> createState() => _AppStartupScreenState();
}

class _AppStartupScreenState extends State<AppStartupScreen> {
  bool isChecking = true;
  String? serverUrl;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    bootstrap();
  }

  Future<void> bootstrap() async {
    final resolvedServer = await ApiService.getBaseUrl();
    if (!mounted) return;

    setState(() {
      isChecking = true;
      serverUrl = resolvedServer;
      errorMessage = null;
    });

    final reachable = await ApiService.canReachServer();
    final isLoggedIn = await SessionService.isLoggedIn();
    final user = await SessionService.getCurrentUser();

    if (!mounted) return;

    if (reachable) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => isLoggedIn
              ? DashboardRouter.screenForRole(user?['role']?.toString())
              : const LoginScreen(),
        ),
      );
      return;
    }

    setState(() {
      isChecking = false;
      errorMessage =
          'Unable to reach the backend server. Check the address or restart your backend/ngrok tunnel.';
    });
  }

  Future<void> openServerSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ServerSettingsScreen()),
    );

    if (!mounted) return;
    bootstrap();
  }

  Future<void> continueAnyway() async {
    final isLoggedIn = await SessionService.isLoggedIn();
    final user = await SessionService.getCurrentUser();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => isLoggedIn
            ? DashboardRouter.screenForRole(user?['role']?.toString())
            : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      errorMessage == null
                          ? Icons.home_repair_service_rounded
                          : Icons.wifi_off_rounded,
                      size: 42,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    errorMessage == null
                        ? 'Preparing your workspace'
                        : 'Server connection needed',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    errorMessage ??
                        'Checking backend availability before opening the app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Server: ${serverUrl ?? ApiService.defaultBaseUrl}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isChecking)
                    const CircularProgressIndicator()
                  else ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: bootstrap,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry Connection'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: openServerSettings,
                        icon: const Icon(Icons.settings_ethernet),
                        label: const Text('Open Server Settings'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: continueAnyway,
                        child: const Text('Continue Anyway'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
