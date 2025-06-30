import 'package:android_studio/screens/dersec_screen.dart';
import 'package:flutter/material.dart';


class WelcomeScreen3 extends StatelessWidget {
  const WelcomeScreen3({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D213B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Konuşma baloncuğu
            Stack(
              alignment: Alignment.center,
              children: [
                // Baloncuk görseli
                Image.asset(
                  'assets/konusmabalonu.png',
                  height: 350,
                ),

                // Konuşma metni
                const Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Hadi keşfe çıkmaya başlayalım! ",
                      style: TextStyle(
                        fontSize: 28,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                // Devam Et butonu
                Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const DersSec()),
                        );

                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Keşfetmeye Başla",
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Maskot resmi
            Align(
              alignment: Alignment.centerRight,
              child: Image.asset(
                'assets/yakisikli_maskot.png',
                height: 250,
              ),
            ),
          ],
        ),
      ),
    );
  }
}