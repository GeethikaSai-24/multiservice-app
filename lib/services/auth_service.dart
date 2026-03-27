import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = "http://localhost:8000/api/users";

  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    final url = Uri.parse("$baseUrl/login/");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
    String phone,
  ) async {
    final url = Uri.parse("$baseUrl/register/");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "email": email,
        "password": password,
        "phone": phone,
      }),
    );

    return jsonDecode(response.body);
  }

  // Step 1: Verify Email
  static Future<Map<String, dynamic>> verifyEmail(String email) async {
    final url = Uri.parse("$baseUrl/forgot-password/");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    return jsonDecode(response.body);
  }

  // Step 2: Reset Password
  static Future<Map<String, dynamic>> resetPassword(
    String email,
    String newPassword,
  ) async {
    final url = Uri.parse("$baseUrl/reset-password/");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "new_password": newPassword}),
    );

    return jsonDecode(response.body);
  }
}
