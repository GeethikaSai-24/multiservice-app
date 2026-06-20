import 'package:flutter/material.dart';

import '../admin/admin_dashboard_screen.dart';
import '../home/home_screen.dart';
import '../provider/provider_dashboard_screen.dart';

class DashboardRouter {
  static Widget screenForRole(String? role) {
    switch ((role ?? 'USER').toUpperCase()) {
      case 'ADMIN':
        return const AdminDashboardScreen();
      case 'PROVIDER':
      case 'DOCTOR':
        return const ProviderDashboardScreen();
      case 'USER':
      default:
        return const HomeScreen();
    }
  }
}
