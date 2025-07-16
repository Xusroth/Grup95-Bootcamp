import 'package:flutter/material.dart';
import 'package:android_studio/screens/dersec_screen.dart';
import 'package:android_studio/screens/welcome_screen1.dart';
import 'package:android_studio/screens/auth_service.dart';

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
      home: const WelcomeScreen1(),
    );
  }
}

