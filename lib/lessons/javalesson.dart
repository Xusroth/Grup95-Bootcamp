import 'package:flutter/material.dart';

class JavaLesson extends StatelessWidget {
  const JavaLesson({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D213B),
      appBar: AppBar(
        backgroundColor: Colors.yellow,
        title: const Text("Java"),
      ),
      body: const Center(
        child: Text(
          "Java Dersi",
          style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}