import 'package:flutter/material.dart';
import 'package:android_studio/screens/dersec_screen.dart';
import 'package:android_studio/screens/ReportScreen1.dart';

class WelcomeScreen3 extends StatelessWidget {
  final String userName;
  final String userNickname;
  final String userMail;
  final String userPassword;

  const WelcomeScreen3({
    super.key,
    required this.userName,
    required this.userNickname,
    required this.userMail,
    required this.userPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/arkaplan.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Üstteki butonlar (EKLEDİĞİM KISIM)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Geri Butonu
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),

                    // Report ikonu
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReportScreen1(),
                          ),
                        );
                      },
                      icon: Image.asset(
                        'assets/report.png',
                        width: 36,
                        height: 36,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Orjinal içerik
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/corner_gradient_rectangle.png',
                    height: 450,
                    width: 400,
                    fit: BoxFit.contain,
                  ),

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset("assets/bitingcode_maskot.png", height: 200),

                      const Text(
                        "Hadi keşfetmeye başlayalım!",
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'Poppins-SemiBold',
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Sana hızlıca nasıl kullanacağını\ngösterebiliriz",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Poppins-SemiBold',
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DersSec(
                                userName: userNickname,
                                userMail: userMail,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF8E2DE2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 14,
                          ),
                        ),
                        child: const Text(
                          "Keşfetmeye Başla",
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Poppins-SemiBold',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
