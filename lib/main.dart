import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 🔥 REQUIRED

  await NotificationService.init(); // 🔥 ADD THIS

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget? startScreen;

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  void checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("access");

    if (token != null) {
      setState(() {
        startScreen = const HomeScreen();
      });
    } else {
      setState(() {
        startScreen = const LoginScreen();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MultiService App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home:
          startScreen ??
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
