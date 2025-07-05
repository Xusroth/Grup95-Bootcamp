import 'dart:math';
import 'package:flutter/material.dart';
import 'package:android_studio/lessons/algorithmlesson.dart';
import 'package:android_studio/lessons/pythonlesson.dart';
import 'package:android_studio/lessons/javalesson.dart';
import 'package:android_studio/lessons/csharplesson.dart';
import 'package:android_studio/screens/SifirdanBaslaSayfasi.dart';

class DersSec extends StatefulWidget {
  final String userName;
  final String userNickname;
  final String userMail;

  const DersSec({
    super.key,
    required this.userName,
    required this.userNickname,
    required this.userMail,
  });

  @override
  State<DersSec> createState() => _DersSecState();
}

class _DersSecState extends State<DersSec> {
  int? flippedIndex;

  final bool algoritmaKilit = false;
  final bool pythonKilit = false;
  final bool javaKilit = false;
  final bool csharpKilit = false;

  void handleFlip(int index, bool locked) {
    if (locked) return;
    setState(() {
      flippedIndex = flippedIndex == index ? null : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> courses = [
      {
        'title': 'Algoritmalar',
        'icon': 'assets/algoritma_icon.png',
        'description': 'Algoritmik düşünme temelleri.',
        'locked': algoritmaKilit,
        'page': SeviyeSecSayfasi(userMail: widget.userMail, userNickname: widget.userNickname,),
      },
      {
        'title': 'Python',
        'icon': 'assets/python_icon.png',
        'description': 'Python programlamaya giriş.',
        'locked': pythonKilit,
        'page': SeviyeSecSayfasi(userMail: widget.userMail, userNickname: widget.userNickname,),
      },
      {
        'title': 'Java',
        'icon': 'assets/java_icon.png',
        'description': 'Java ile nesne yönelimli programlama.',
        'locked': javaKilit,
        'page': SeviyeSecSayfasi(userMail: widget.userMail, userNickname: widget.userNickname,),
      },
      {
        'title': 'C#',
        'icon': 'assets/python_icon.png',
        'description': 'C# ile Windows uygulamaları.',
        'locked': csharpKilit,
        'page': SeviyeSecSayfasi(userMail: widget.userMail, userNickname: widget.userNickname,),
      },
    ];

    return Scaffold(
      body: Stack(
        children: [
          // Arkaplan
          SizedBox.expand(
            child: Image.asset(
              'assets/arkaplan.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Kullanıcı Barı
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/user_bar.png',
                        fit: BoxFit.contain,
                        width: 400,
                        height: 70,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 5),
                          Image.asset('assets/profile_pic.png', height: 48),
                          Text(
                            "Merhaba ${widget.userNickname}",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontFamily: 'Poppins-Regular',
                            ),
                          ),
                          Row(
                            children: [
                              Image.asset('assets/health_bar.png', height: 28),
                              const SizedBox(width: 3),
                              Image.asset('assets/report.png', height: 24),
                              const SizedBox(width: 12),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Text(
                  "Ders Seçin",
                  style: TextStyle(
                    fontSize: 36,
                    color: Colors.white,
                    fontFamily: 'Poppins-Regular',
                  ),
                ),
                const SizedBox(height: 15),

                // Kartlar ve maskot dahil tüm içeriği tek alana topluyoruz
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.only(bottom: 200),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 24,
                              crossAxisSpacing: 24,
                              childAspectRatio: 0.9,
                            ),
                            itemCount: courses.length,
                            itemBuilder: (context, index) {
                              final course = courses[index];
                              final isFlipped = flippedIndex == index;

                              return GestureDetector(
                                onTap: () => handleFlip(index, course['locked']),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 500),
                                  transitionBuilder: (child, animation) {
                                    final rotate = Tween(begin: pi, end: 0.0).animate(animation);
                                    return AnimatedBuilder(
                                      animation: rotate,
                                      child: child,
                                      builder: (context, child) {
                                        final isUnder = (ValueKey(isFlipped) != child!.key);
                                        final rotationY = isUnder ? pi : 0.0;
                                        return Transform(
                                          transform: Matrix4.rotationY(rotationY + rotate.value),
                                          alignment: Alignment.center,
                                          child: child,
                                        );
                                      },
                                    );
                                  },
                                  layoutBuilder: (currentChild, _) => currentChild!,
                                  child: isFlipped
                                      ? Container(
                                    key: const ValueKey(true),
                                    decoration: BoxDecoration(
                                      image: const DecorationImage(
                                        image: AssetImage('assets/ders_card.png'),
                                        fit: BoxFit.cover,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            course['description'],
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: Colors.white,
                                              fontFamily: 'Poppins-Regular',
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 12),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => course['page'],
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.yellow,
                                              foregroundColor: Colors.black,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                            ),
                                            child: const Text(
                                              "Seç",
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontFamily: 'Poppins-Regular',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                      : Container(
                                    key: const ValueKey(false),
                                    decoration: BoxDecoration(
                                      image: const DecorationImage(
                                        image: AssetImage('assets/ders_card.png'),
                                        fit: BoxFit.cover,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            course['title'],
                                            style: const TextStyle(
                                              fontSize: 22,
                                              color: Colors.white,
                                              fontFamily: 'Poppins-Regular',
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Image.asset(course['icon'], height: 50),
                                          const SizedBox(height: 20),
                                          Icon(
                                            course['locked'] ? Icons.lock : Icons.lock_open,
                                            color: Colors.black,
                                            size: 35,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Aşağıdaki maskot ve baloncuk
                        Stack(
                          children: [
                            SizedBox(
                              height: 220,
                              width: double.infinity,
                              child: Image.asset(
                                'assets/yan_konusmabaloncuklu_maskot.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const Positioned(
                              left: 30,
                              top: 0,
                              child: Text(
                                "İpucu!\nTemel seviye için \nalgoritmalar dersini\nöneriyoruz.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontFamily: 'Poppins-Regular',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
