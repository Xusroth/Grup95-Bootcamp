import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:app_links/app_links.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


import 'package:android_studio/constants.dart';
import 'package:android_studio/auth_service.dart';

import 'package:android_studio/screens/welcome_screen1.dart';
import 'package:android_studio/screens/home_screen.dart';
import 'package:android_studio/screens/password_reset_screen.dart';

void main() async{
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
    _checkTokenAndLoadUserData();
  }

  Future<void> _checkTokenAndLoadUserData() async {
    final prefs = AuthService();
    String? storedToken = await prefs.getString('token');

    setState(() {
      token = storedToken;
      isLoading = false;
    });

    if (token != null && token!.isNotEmpty) {
      try {
        final userInfo = await _fetchUserInfo(token!);

        await prefs.setString('user_id', userInfo['id'].toString());
        await prefs.setString('user_name', userInfo['username']);
        await prefs.setString('user_mail', userInfo['email']);

        final avatar = await _fetchUserAvatar(token!);
        await prefs.setString('user_avatar', avatar ?? 'profile_pic.png');

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              userName: userInfo['username'],
              userMail: userInfo['email'],
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

  Future<String?> _fetchUserAvatar(String token) async {
    final response = await http.get(
      Uri.parse('$baseURL/avatar/current'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['avatar'];
    } else {
      debugPrint("Avatar bilgisi alınamadı: ${response.statusCode}");
      return null;
    }
  }

  void _handleIncomingLinks() async {
    _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri?.scheme == 'codebite' && uri?.host == 'reset-password') {
        final token = uri?.queryParameters['token'];
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

    final Uri? initialUri = await _appLinks.getInitialAppLink();
    if (initialUri?.scheme == 'codebite' && initialUri?.host == 'reset-password') {
      final token = initialUri?.queryParameters['token'];
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
