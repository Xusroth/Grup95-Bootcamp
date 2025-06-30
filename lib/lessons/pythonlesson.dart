import 'package:flutter/material.dart';

class PythonLesson extends StatelessWidget {
  const PythonLesson({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D213B),
      appBar: AppBar(
        backgroundColor: Colors.yellow,
        title: const Text("Python"),
      ),
      body: const Center(
        child: Text(
          "Python Dersi",
          style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}