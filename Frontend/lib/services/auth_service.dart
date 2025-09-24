import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  final String id;
  final String email;
  final String? fullName;
  final String token;
  UserSession({
    required this.id,
    required this.email,
    required this.token,
    this.fullName,
  });
}

class AuthService with ChangeNotifier {
  static const _base = 'http://15.206.217.186:3000';

  UserSession? _session;
  UserSession? get currentUser => _session;
  String? get token => _session?.token;

  bool _initialized = false;
  bool get initialized => _initialized;

  final StreamController<bool> _authStateController =
      StreamController<bool>.broadcast();
  Stream<bool> get onAuthStateChange => _authStateController.stream;

  AuthService() {
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('auth_session');
    if (raw != null) {
      final m = jsonDecode(raw);
      _session = UserSession(
        id: m['id'],
        email: m['email'],
        fullName: m['fullName'],
        token: m['token'],
      );
      _authStateController.add(true);
    } else {
      _authStateController.add(false);
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_session == null) {
      await prefs.remove('auth_session');
    } else {
      await prefs.setString(
        'auth_session',
        jsonEncode({
          'id': _session!.id,
          'email': _session!.email,
          'fullName': _session!.fullName,
          'token': _session!.token,
        }),
      );
    }
  }

  Future<UserSession> signUp(
      String email, String password, String fullName,
      {String? phone}) async {
    final uri = Uri.parse('$_base/api/auth/register'); // ensure backend uses /register
    final r = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': fullName,
        if (phone != null) 'phone': phone,
      }),
    );
    if (r.statusCode != 201 && r.statusCode != 200) {
      throw Exception(r.body);
    }
    final data = jsonDecode(r.body);
    _session = UserSession(
      id: data['user']['id'],
      email: data['user']['email'],
      fullName: data['user']['name'],
      token: data['token'],
    );
    await _persist();
    _authStateController.add(true);
    notifyListeners();
    return _session!;
  }

  Future<UserSession> signInWithPassword(
      String email, String password) async {
    final uri = Uri.parse('$_base/api/auth/login');
    final r = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (r.statusCode != 200) {
      throw Exception(r.body);
    }
    final data = jsonDecode(r.body);
    _session = UserSession(
      id: data['user']['id'],
      email: data['user']['email'],
      fullName: data['user']['name'],
      token: data['token'],
    );
    await _persist();
    _authStateController.add(true);
    notifyListeners();
    return _session!;
  }

  // Optional placeholder (no backend endpoint yet)
  Future<void> signInWithGoogle() async {
    throw Exception('Google Sign-In not implemented');
  }

  Future<void> signOut() async {
    _session = null;
    await _persist();
    _authStateController.add(false);
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateController.close();
    super.dispose();
  }
}