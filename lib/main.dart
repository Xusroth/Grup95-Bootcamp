import 'dart:convert';

import 'package:android_studio/constants.dart';
import 'package:android_studio/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:android_studio/screens/dersec_screen.dart';
import 'package:android_studio/screens/welcome_screen1.dart';
import 'package:android_studio/auth_service.dart';
import 'package:android_studio/screens/login_screen.dart';
import 'package:http/http.dart' as http;


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

  @override
  void initState() {
    super.initState();
    checkToken();
  }

  Future<void> checkToken() async {
    final prefs = AuthService();
    String? storedToken = await prefs.getString('token');

    setState(() {
      token = storedToken;
      isLoading = false;
    });

    if (token != null && token != ''){
    final userInfo = await fetchUserInfo(token!);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            userName: userInfo['username'] ?? "Kullanıcı",
            userMail: userInfo['email'] ?? "bilinmiyor@mail.com",
          ),
        ),
      );
    }
  }

  Future<Map<String, dynamic>> fetchUserInfo(String token) async {
    final response = await http.get(
      Uri.parse('$baseURL/auth/me'), // kendi backend IP'n
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final msg = jsonDecode(response.body)['detail'] ?? 'Kullanıcı bilgisi alınamadı';
      throw Exception(msg);
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