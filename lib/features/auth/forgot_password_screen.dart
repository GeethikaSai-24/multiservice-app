import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool isEmailVerified = false;

  void verifyEmail() async {
    setState(() => isLoading = true);

    try {
      final response = await AuthService.verifyEmail(emailController.text);

      if (response != null && response.containsKey("message")) {
        setState(() => isEmailVerified = true);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response["message"] ?? "Something went wrong")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => isLoading = false);
  }

  void resetPassword() async {
    setState(() => isLoading = true);

    try {
      final response = await AuthService.resetPassword(
        emailController.text,
        passwordController.text,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response["message"] ?? "Error")));

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Forgot Password")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),

              const SizedBox(height: 20),

              if (!isEmailVerified)
                ElevatedButton(
                  onPressed: isLoading ? null : verifyEmail,
                  child: const Text("Verify Email"),
                ),

              if (isEmailVerified) ...[
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "New Password"),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isLoading ? null : resetPassword,
                  child: const Text("Reset Password"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
