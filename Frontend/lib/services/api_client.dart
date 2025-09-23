import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  static const String _base = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  final AuthService auth;

  ApiClient(this.auth);

  Uri _u(String path, [Map<String, dynamic>? q]) =>
      Uri.parse('$_base$path').replace(queryParameters: q?.map((k, v) => MapEntry(k, '$v')));

  Map<String, String> _headers({Map<String, String>? extra}) {
    final h = <String, String>{'Content-Type': 'application/json'};
    final token = auth.token;
    if (token != null) h['Authorization'] = 'Bearer $token';
    if (extra != null) h.addAll(extra);
    return h;
  }

  Future<dynamic> getJson(String path, {Map<String, dynamic>? query}) async {
    if (path.isEmpty) {
      debugPrint('ApiClient getJson called with EMPTY path\n${StackTrace.current}');
      throw Exception('Empty API path');
    }
    debugPrint('GET $path');
    final r = await http.get(_u(path, query), headers: _headers());
    return _handle(r);
  }

  Future<dynamic> postJson(String path, Map body) async {
    if (path.isEmpty) {
      debugPrint('ApiClient postJson called with EMPTY path\n${StackTrace.current}');
      throw Exception('Empty API path');
    }
    debugPrint('POST $path');
    final r = await http.post(_u(path), headers: _headers(), body: jsonEncode(body));
    return _handle(r);
  }

  Future<dynamic> putJson(String path, Map body) async {
    final r = await http.put(_u(path), headers: _headers(), body: jsonEncode(body));
    return _handle(r);
  }

  Future<dynamic> patchJson(String path, Map body) async {
    final r = await http.patch(_u(path),
        headers: _headers(), body: jsonEncode(body));
    return _handle(r);
  }

  Future<dynamic> multipart(String path,
      {Map<String, String>? fields, String fileField = 'file', String? filename, List<int>? fileBytes}) async {
    if (path.isEmpty) {
      debugPrint('ApiClient multipart called with EMPTY path\n${StackTrace.current}');
      throw Exception('Empty API path');
    }
    debugPrint('MULTIPART $path');
    final uri = _u(path);
    final req = http.MultipartRequest('POST', uri);
    final token = auth.token;
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    fields?.forEach((k, v) => req.fields[k] = v);
    if (fileBytes != null) {
      req.files.add(http.MultipartFile.fromBytes(
        fileField,
        fileBytes,
        filename: filename ?? 'upload.xlsx',
      ));
    }
    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);
    return _handle(resp);
  }

  dynamic _handle(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) {
      if (r.body.isEmpty) return null;
      try { return jsonDecode(r.body); } catch (_) { return r.body; }
    }
    String msg = r.body;
    try {
      final m = jsonDecode(r.body);
      if (m is Map && m['message'] is String) msg = m['message'];
    } catch (_) {}
    throw Exception('HTTP ${r.statusCode}: $msg');
  }
}