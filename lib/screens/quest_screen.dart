
import 'package:flutter/material.dart';
import 'package:android_studio/screens/home_screen.dart';
import 'package:android_studio/screens/dersec_screen.dart';
import 'package:android_studio/screens/ReportScreen1.dart';

class QuestScreen extends StatelessWidget {
  final String userName;

  const QuestScreen({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/arkaplan.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Image.asset('assets/user_bar.png', fit: BoxFit.contain, width: 400, height: 70),
                      Positioned(
                        left: 16,
                        child: Image.asset('assets/profile_pic.png', height: 36),
                      ),
                      Positioned(
                        left: 60,
                        child: Text(
                          'Merhaba $userName',
                          style: const TextStyle(
                            fontFamily: 'Poppins-Regular',
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 48,
                        child: Image.asset('assets/health_bar.png', height: 24),
                      ),
                      Positioned(
                        right: 20,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ReportScreen1()),
                            );
                          },
                          child: Image.asset('assets/report.png', height: 22),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Stack(
                    children: [
                      Image.asset("assets/graph.png", fit: BoxFit.contain),
                      const Positioned(
                        top: 12,
                        left: 16,
                        child: Text(
                          "Harika\nİlerliyorsun!",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Poppins-SemiBold',
                          ),
                        ),
                      ),
                      const Positioned(
                        right: 12,
                        top: 60,
                        child: Text(
                          "1/3\nTamamlandı",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontFamily: 'Poppins-Regular',
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    children: [
                      buildGorevCard("assets/kart1.png", "5 Python Sorusu Çöz", 2, 5),
                      const SizedBox(height: 10),
                      buildGorevCard("assets/kart2.png", "1 Yeni Konu Öğren", 1, 1),
                      const SizedBox(height: 10),
                      buildGorevCard("assets/kart3.png", "3 Dersi Hatasız Tamamla", 1, 3),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 350,
                  child: Image.asset("assets/alt_bar.png", fit: BoxFit.fill),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60.0, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HomeScreen(userMail: '', userName: userName),
                            ),
                          );
                        },
                        child: Image.asset("assets/home.png", height: 28),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DersSec(userMail: '', userName: userName),
                            ),
                          );
                        },
                        child: Image.asset("assets/ders.png", height: 28),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuestScreen(userName: userName),
                            ),
                          );
                        },
                        child: Image.asset("assets/profile.png", height: 28),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildGorevCard(String imagePath, String gorevYazisi, int tamamlanan, int toplam) {
    double progress = tamamlanan / toplam;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(imagePath, width: double.infinity, height: 130, fit: BoxFit.cover),
          ),
          Positioned(
            right: 220,
            top: 53,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "$tamamlanan/$toplam Tamamlandı",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontFamily: 'Poppins-SemiBold',
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gorevYazisi,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Poppins-Bold',
                    ),
                  ),
                  const Spacer(),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 20,
                      backgroundColor: Colors.black26,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 28, 179, 28)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}