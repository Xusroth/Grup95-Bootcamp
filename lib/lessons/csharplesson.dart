import 'package:flutter/material.dart';

class CsharpLesson extends StatelessWidget {
  const CsharpLesson({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D213B),
      appBar: AppBar(
        backgroundColor: Colors.yellow,
        title: const Text("C#"),
      ),
      body: const Center(
        child: Text(
          "C# Dersi",
          style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}