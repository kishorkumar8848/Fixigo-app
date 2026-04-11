import 'dart:convert';
import 'package:http/http.dart' as http;
import 'session.dart';

class Api {
  // change this if backend runs on different host or port
  static const String baseUrl = 'http://10.0.2.2:3000';

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
    );
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
    
    final streamedResponse = await request.send();
    final resp = await http.Response.fromStream(streamedResponse);
    
    final data = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
    return {'status': resp.statusCode, 'data': data};
  }

  static Future<Map<String, dynamic>> get(String path) async {
    final url = Uri.parse(baseUrl + path);
    final resp = await http.get(url, headers: _getHeaders());
    final data = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
    return {'status': resp.statusCode, 'data': data};
  }

  static Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    final url = Uri.parse(baseUrl + path);
    final resp = await http.put(url, headers: _getHeaders(), body: jsonEncode(body));
    final data = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
    return {'status': resp.statusCode, 'data': data};
  }
  
  static Future<Map<String, dynamic>> delete(String path) async {
    final url = Uri.parse(baseUrl + path);
    final resp = await http.delete(url, headers: _getHeaders());
    final data = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
    return {'status': resp.statusCode, 'data': data};
  }

  static Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    final url = Uri.parse(baseUrl + path);
    final resp = await http.patch(url, headers: _getHeaders(), body: jsonEncode(body));
    final data = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
    return {'status': resp.statusCode, 'data': data};
  }
}
