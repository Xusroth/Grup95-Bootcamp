import 'package:android_studio/lessons/algorithmlesson.dart';
import 'package:android_studio/lessons/question_page.dart';
import 'package:flutter/material.dart';
import 'package:android_studio/screens/ReportScreen1.dart';

class SeviyeSecSayfasi extends StatelessWidget {
  final String userMail; // mail kontrolü için
  final String userName; // kullanıcı adını taşımak için
  const SeviyeSecSayfasi({
    super.key,
    required this.userMail,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final bool isRegistered = userMail.isNotEmpty;

    return Scaffold(
      body: Stack(
        children: [
          // Arka plan
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/arkaplan.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Üstteki butonlar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Geri Butonu
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),

                  // Report ikonu - IconButton ile
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

          // Ortadaki içerik kutusu ve elemanlar
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/corner_gradient_rectangle.png',
                  width: 310,
                  height: 420,
                ),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/selamveren_maskot.png', width: 120),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 30,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'Hadi seviyeni öğrenelim!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Sıfırdan Başla butonu
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AlgorithmLessonOverview(
                              userName: userName,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Sıfırdan Başla',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Seviyeni Belirle butonu (aktif/pasif kontrolü)
                    isRegistered
                        ? ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.1),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text(
                              'Seviyeni Belirle',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Column(
                              children: [
                                Text(
                                  'Seviyeni Belirle',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '(Kayıtlı Kullanıcılar için Geçerli)',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
