import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'session_service.dart';

class ApiService {
  static const String _baseUrlKey = 'server_base_url';
  static const String defaultBaseUrl = 'http://127.0.0.1:8000';
  static const Duration _requestTimeout = Duration(seconds: 20);

  static Future<String> getBaseUrl() async {
    final storedBaseUrl = await SessionService.getPreference(_baseUrlKey);
    if (storedBaseUrl == null || storedBaseUrl.trim().isEmpty) {
      return defaultBaseUrl;
    }
    return storedBaseUrl.trim().replaceAll(RegExp(r'/$'), '');
  }

  static Future<void> saveBaseUrl(String baseUrl) async {
    final normalized = normalizeBaseUrl(baseUrl);
    await SessionService.savePreference(_baseUrlKey, normalized);
  }

  static String normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return defaultBaseUrl;
    }

    final withScheme =
        trimmed.startsWith('http://') || trimmed.startsWith('https://')
        ? trimmed
        : 'http://$trimmed';
    final sanitized = withScheme.replaceAll(RegExp(r'/$'), '');
    final parsed = Uri.tryParse(sanitized);

    if (parsed == null || parsed.host.isEmpty) {
      return defaultBaseUrl;
    }

    final typoMatch = RegExp(r'^(.*)\.(\d{2,5})$').firstMatch(parsed.host);
    final correctedHost = typoMatch?.group(1) ?? parsed.host;
    final correctedPort = parsed.hasPort
        ? parsed.port
        : int.tryParse(typoMatch?.group(2) ?? '');
    final defaultPort =
        correctedPort == null ||
        correctedPort <= 0 ||
        correctedPort == 80 ||
        correctedPort == 443;

    return Uri(
      scheme: parsed.scheme.isEmpty ? 'http' : parsed.scheme,
      host: correctedHost,
      port: defaultPort ? null : correctedPort,
      path: parsed.path,
      query: parsed.hasQuery ? parsed.query : null,
    ).toString().replaceAll(RegExp(r'/$'), '');
  }

  static Future<Uri> uri(String path) async {
    final baseUrl = await getBaseUrl();
    return Uri.parse('$baseUrl$path');
  }

  static Future<Map<String, String>> authHeaders() async {
    final token = await SessionService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(String path) async {
    return http.get(await uri(path)).timeout(_requestTimeout);
  }

  static Future<http.Response> getAuthenticated(String path) async {
    return http.get(
      await uri(path),
      headers: await authHeaders(),
    ).timeout(_requestTimeout);
  }

  static Future<http.Response> postAuthenticated(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return http.post(
      await uri(path),
      headers: await authHeaders(),
      body: body == null ? null : jsonEncode(body),
    ).timeout(_requestTimeout);
  }

  static Future<http.Response> putAuthenticated(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    return http.put(
      await uri(path),
      headers: await authHeaders(),
      body: jsonEncode(body),
    ).timeout(_requestTimeout);
  }

  static Future<http.Response> patchAuthenticated(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    return http.patch(
      await uri(path),
      headers: await authHeaders(),
      body: jsonEncode(body),
    ).timeout(_requestTimeout);
  }

  static Future<http.Response> deleteAuthenticated(String path) async {
    return http.delete(
      await uri(path),
      headers: await authHeaders(),
    ).timeout(_requestTimeout);
  }

  static Future<bool> canReachServer() async {
    try {
      final response = await get('/api/services/categories/');
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }
}
