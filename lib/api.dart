import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'session.dart';

class Api {
  // Platform-aware base URLs:
  // - Android emulator: 10.0.2.2
  // - iOS simulator: localhost (127.0.0.1)
  // - Web: localhost
  static const String _renderBaseUrl = 'https://fixigo-app.onrender.com';
  static const String _androidEmulatorBase = 'http://10.11.48.52:3000';
  static const String _iosSimulatorBase = 'http://10.11.48.52:3000';
  static const String _webBaseUrl = 'http://localhost:3000';

  // Toggle this to false to connect to your live Render backend,
  // or set it to true for local emulator debugging.
  static const bool useLocalBackend = false;

  static String resolveBaseUrl({String? override, required bool isWeb, required TargetPlatform platform}) {
    if (override != null && override.isNotEmpty) {
      return override;
    }

    if (!useLocalBackend) {
      return _renderBaseUrl;
    }

    if (isWeb) return _webBaseUrl;

    // Android emulator needs 10.0.2.2 to reach host machine
    if (platform == TargetPlatform.android) return _androidEmulatorBase;

    // iOS simulator and other platforms use localhost by default
    return _iosSimulatorBase;
  }

  static String get baseUrl {
    return resolveBaseUrl(
      isWeb: kIsWeb,
      platform: defaultTargetPlatform,
    );
  }

  static Map<String, String> _getHeaders() {
    final Map<String, String> headers = {'Content-Type': 'application/json'};
    if (Session.token != null) {
      headers['Authorization'] = 'Bearer ${Session.token}';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> post(String path, [Map<String, dynamic>? body]) async {
    final url = Uri.parse(baseUrl + path);
    final resp = await http.post(
      url,
      headers: _getHeaders(),
      body: body != null ? jsonEncode(body) : null,
    ).timeout(const Duration(seconds: 10));
    final data = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
    return {'status': resp.statusCode, 'data': data};
  }

  static Future<Map<String, dynamic>> multipartPost(
      String path, Map<String, String> fields, String fileField, String filePath) async {
    final url = Uri.parse(baseUrl + path);
    final request = http.MultipartRequest('POST', url);
    
    if (Session.token != null) {
      request.headers['Authorization'] = 'Bearer ${Session.token}';
    }
    
    request.fields.addAll(fields);
    request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
    
    final streamedResponse = await request.send().timeout(const Duration(seconds: 10));
    final resp = await http.Response.fromStream(streamedResponse);
    
    final data = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
    return {'status': resp.statusCode, 'data': data};
  }

  static Future<Map<String, dynamic>> get(String path) async {
    final url = Uri.parse(baseUrl + path);
    final resp = await http.get(url, headers: _getHeaders()).timeout(const Duration(seconds: 10));
    final data = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
    return {'status': resp.statusCode, 'data': data};
  }

  static Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    final url = Uri.parse(baseUrl + path);
    final resp = await http.put(url, headers: _getHeaders(), body: jsonEncode(body)).timeout(const Duration(seconds: 10));
    final data = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
    return {'status': resp.statusCode, 'data': data};
  }
  
  static Future<Map<String, dynamic>> delete(String path) async {
    final url = Uri.parse(baseUrl + path);
    final resp = await http.delete(url, headers: _getHeaders()).timeout(const Duration(seconds: 10));
    final data = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
    return {'status': resp.statusCode, 'data': data};
  }

  static Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    final url = Uri.parse(baseUrl + path);
    final resp = await http.patch(url, headers: _getHeaders(), body: jsonEncode(body)).timeout(const Duration(seconds: 10));
    final data = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
    return {'status': resp.statusCode, 'data': data};
  }
}
