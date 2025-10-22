import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UserSession {
  final String id;
  final String email;
  final String? fullName;
  final String token;
  final String? displayName; // Added displayName property

  UserSession({
    required this.id,
    required this.email,
    required this.token,
    this.fullName,
    this.displayName, // Initialize displayName
  });
}

class AuthService with ChangeNotifier {
  static String get _base => dotenv.env['API_BASE_URL'] ?? 'http://15.206.217.186:3000';

  UserSession? _session;
  UserSession? get currentUser => _session;
  String? get token => _session?.token;

  bool _initialized = false;
  bool get initialized => _initialized;

  final StreamController<bool> _authStateController =
      StreamController<bool>.broadcast();
  Stream<bool> get onAuthStateChange => _authStateController.stream;

  late final GoogleSignIn _googleSignIn;

  AuthService() {
    _initializeGoogleSignIn();
    _restore();
  }

  void _initializeGoogleSignIn() {
    // Get client IDs from environment variables
    final iosClientId = dotenv.env['IOS_CLIENT_ID'];
    final webClientId = dotenv.env['WEB_CLIENT_ID'];

    if (kDebugMode) {
      print('iOS Client ID: $iosClientId');
      print('Web Client ID: $webClientId');
    }

    _googleSignIn = GoogleSignIn(
      clientId: Platform.isIOS ? iosClientId : webClientId,
      scopes: [
        'email',
        'profile',
      ],
    );
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

  Future<UserSession> signInWithGoogleAccount() async {
    try {
      // Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign-In was cancelled by user');
      }

      // Get authentication tokens
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.idToken == null || googleAuth.accessToken == null) {
        throw Exception('Failed to get Google authentication tokens');
      }

      // Call the existing signInWithGoogle method
      return await signInWithGoogle(
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken!,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Google Sign-In Error: $e');
      }
      rethrow;
    }
  }

  Future<UserSession> signInWithGoogle({required String idToken, required String accessToken}) async {
    final uri = Uri.parse('$_base/api/auth/google-login');
    final r = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idToken': idToken,
        'accessToken': accessToken,
      }),
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

  Future<void> signOut() async {
    _session = null;
    await _persist();
    
    // Also sign out from Google
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      if (kDebugMode) {
        print('Google Sign-Out Error: $e');
      }
    }
    
    _authStateController.add(false);
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateController.close();
    super.dispose();
  }
}