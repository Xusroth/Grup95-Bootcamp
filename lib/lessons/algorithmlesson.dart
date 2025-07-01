import 'package:flutter/material.dart';

class AlgorithmLesson extends StatelessWidget {
  const AlgorithmLesson({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D213B),
      appBar: AppBar(
        backgroundColor: Colors.yellow,
        title: const Text("Algoritmalar"),
      ),
      body: const Center(
        child: Text(
          "Algoritmalar Dersi",
          style: TextStyle(
            fontSize: 28,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}