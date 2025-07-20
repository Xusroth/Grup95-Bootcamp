import 'package:flutter/material.dart';

class StreakPage2 extends StatelessWidget {
  const StreakPage2({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // 🌌 Arka Plan
          Positioned.fill(
            child: Image.asset(
              'assets/arkaplan.png',
              fit: BoxFit.cover,
            ),
          ),

          // 🔥 Üst Alev - düz, tam ekran, tam görünür
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/level2.png',
              width: screenWidth,
              height: 150, // büyütüldü
              fit: BoxFit.fitWidth,
            ),
          ),

          // ✏️ Ortadaki Yazılar
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  "GÜZEL GİDİYORSUN 😎",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Streak büyümeye başladı!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // 🔥 Alt Alev - ters, tam ekran, tam görünür
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/level2_reverse.png',
              width: screenWidth,
              height: 150, // büyütüldü
              fit: BoxFit.fitWidth,
            ),
          ),
        ],
      ),
    );
  }
}
