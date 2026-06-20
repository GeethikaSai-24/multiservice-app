import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

class AuthService {
  static Future<Uri> _usersUri(String path) async {
    return ApiService.uri('/api/users$path');
  }

  static Map<String, dynamic> _decodeResponse(http.Response response) {
    dynamic body;

    try {
      body = jsonDecode(response.body);
    } on FormatException {
      body = {
        'error': response.body.trim().isEmpty
            ? 'Unexpected server response'
            : response.body.trim(),
      };
    }

    final payload = body is Map<String, dynamic>
        ? Map<String, dynamic>.from(body)
        : <String, dynamic>{'data': body};
    payload['_statusCode'] = response.statusCode;
    return payload;
  }

  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    final response = await http.post(
      await _usersUri('/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    ).timeout(const Duration(seconds: 20));

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
    String phone,
    String role,
    Map<String, dynamic> extraFields,
  ) async {
    final response = await http.post(
      await _usersUri('/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role,
        ...extraFields,
      }),
    ).timeout(const Duration(seconds: 20));

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> verifyEmail(String email) async {
    final response = await http.post(
      await _usersUri('/forgot-password/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    ).timeout(const Duration(seconds: 20));

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> resetPassword(
    String email,
    String newPassword,
  ) async {
    final response = await http.post(
      await _usersUri('/reset-password/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'new_password': newPassword}),
    ).timeout(const Duration(seconds: 20));

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> fetchCurrentUser() async {
    final response = await http.get(
      await _usersUri('/me/'),
      headers: await ApiService.authHeaders(),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Unable to load user profile');
    }

    return Map<String, dynamic>.from(jsonDecode(response.body));
  }
}
