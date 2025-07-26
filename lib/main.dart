import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:app_links/app_links.dart';

import 'package:android_studio/constants.dart';
import 'package:android_studio/auth_service.dart';

import 'package:android_studio/screens/welcome_screen1.dart';
import 'package:android_studio/screens/home_screen.dart';
import 'package:android_studio/screens/password_reset_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Codebite',
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? token;
  bool isLoading = true;
  final AppLinks _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _handleIncomingLinks();
    _checkToken();
  }

  Future<void> _checkToken() async {
    final prefs = AuthService();
    String? storedToken = await prefs.getString('token');

    setState(() {
      token = storedToken;
      isLoading = false;
    });

    if (token != null && token!.isNotEmpty) {
      try {
        final userInfo = await _fetchUserInfo(token!);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              userName: userInfo['username'] ?? "Kullanıcı",
              userMail: userInfo['email'] ?? "bilinmiyor@mail.com",
            ),
          ),
        );
      } catch (e) {
        debugPrint("Kullanıcı bilgisi alınamadı: $e");
      }
    }
  }

  Future<Map<String, dynamic>> _fetchUserInfo(String token) async {
    final response = await http.get(
      Uri.parse('$baseURL/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Kullanıcı bilgisi alınamadı');
    }
  }

  void _handleIncomingLinks() async {
    // Uygulama açıkken gelen bağlantılar
    _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null && uri.path == '/reset-password') {
        final token = uri.queryParameters['token'];
        if (token != null && token.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PasswordResetScreen(token: token),
            ),
          );
        }
      }
    }, onError: (err) {
      debugPrint('App link error: $err');
    });

    // Uygulama kapalıyken ilk açılış bağlantısı
    final Uri? initialUri = await _appLinks.getInitialAppLink();
    if (initialUri != null && initialUri.path == '/reset-password') {
      final token = initialUri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PasswordResetScreen(token: token),
            ),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return const WelcomeScreen1();
  }
}
