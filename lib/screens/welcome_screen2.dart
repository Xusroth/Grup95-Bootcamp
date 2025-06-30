import 'package:flutter/material.dart';
import 'package:android_studio/screens/welcome_screen3.dart';

class WelcomeScreen2 extends StatelessWidget {
  const WelcomeScreen2({super.key});

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
                  height: 550,
                ),

                // Konuşma metni
                const Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Merhaba! 👋\nCodebite'a hoş geldin!\nSenin için kodlama öğrenmeyi eğlenceli,\netkili ve sürdürülebilir hale getirmek \nistiyoruz.\n\nGünlük mini görevlerle pratik yapabilir,\nKısa testlerle seviyeni görebilir,\nHedeflerini belirleyip ilerlemeni takip edebilirsin.",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                // Devam Et butonu
                Positioned(
                  bottom: 150,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const WelcomeScreen3()),
                        );

                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Devam Et",
                        style: TextStyle(fontSize: 16),
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
            'assets/selamveren_maskot.png',
            height: 200,
          ),
        ),
          ],
        ),
      ),
    );
  }
}