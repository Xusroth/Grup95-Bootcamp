import 'dart:math';
import 'package:android_studio/constants.dart';
import 'package:android_studio/screens/profile.dart';
import 'package:flutter/material.dart';
import 'package:android_studio/lessons/algorithmlesson.dart';
import 'package:android_studio/lessons/pythonlesson.dart';
import 'package:android_studio/lessons/javalesson.dart';
import 'package:android_studio/lessons/csharplesson.dart';
import 'package:android_studio/screens/SifirdanBaslaSayfasi.dart';
import 'package:android_studio/screens/home_screen.dart';
import 'package:android_studio/screens/quest_screen.dart';
import 'package:android_studio/screens/profile.dart';
import 'package:android_studio/screens/ReportScreen1.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:android_studio/auth_service.dart';

class DersSec extends StatefulWidget {
  final String userName;
  final String userMail;

  const DersSec({
    super.key,
    required this.userName,
    required this.userMail,
  });

  @override
  State<DersSec> createState() => _DersSecState();
}

class _DersSecState extends State<DersSec> {
  int? flippedIndex;

  final bool algoritmaKilit = false;
  final bool pythonKilit = false;
  final bool javaKilit = true;
  final bool csharpKilit = true;
  
Future<void> dersiSec(int lessonId) async {
  final authService = AuthService();
  final token = await authService.getString('token');

  if (token == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Giriş yapılmamış.")),
    );
    return;
  }

  // Her zaman auth/me üzerinden user_id'yi al
  final response = await http.get(
    Uri.parse('$baseURL/auth/me'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode != 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Kullanıcı bilgisi alınamadı.")),
    );
    return;
  }

  final userData = json.decode(response.body);
  final userId = userData['id'];

  final dersKayitResponse = await http.post(
    Uri.parse('$baseURL/lesson/users/$userId/lessons/$lessonId'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (dersKayitResponse.statusCode == 200) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeviyeSecSayfasi(
          userName: widget.userName,
          userMail: widget.userMail,
        ),
      ),
    );
  } else {
    final errorMessage = json.decode(dersKayitResponse.body)['detail'] ?? "Bir hata oluştu";
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Ders seçilemedi: $errorMessage")),
    );
  }
}


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
        'lessonId': 1,
      },
      {
        'title': 'Python',
        'icon': 'assets/python_icon.png',
        'description': 'Python programlamaya giriş.',
        'locked': pythonKilit,
        'lessonId': 2,
      },
      {
        'title': 'Java',
        'icon': 'assets/java_icon.png',
        'description': 'Java ile nesne yönelimli programlama.',
        'locked': javaKilit,
        'lessonId': 3,
      },
      {
        'title': 'C#',
        'icon': 'assets/python_icon.png',
        'description': 'C# ile Windows uygulamaları.',
        'locked': csharpKilit,
        'lessonId': 4,
      },
    ];

    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              'assets/arkaplan.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
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
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProfilePage(userName: widget.userName),
                                ),
                              );
                            },
                            child: Container(
                              width: 55,
                              height: 55,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: const DecorationImage(
                                  image: AssetImage('assets/profile_pic.png'),
                                  fit: BoxFit.cover,
                                ),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            "Merhaba ${widget.userName}",
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
                        ],
                      ),
                    ],
                  ),
                ),
                const Text(
                  "Ders Seçin",
                  style: TextStyle(fontSize: 36, color: Colors.white, fontFamily: 'Poppins-Regular'),
                ),
                const SizedBox(height: 15),
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
                                      ? dersCardFlipped(course)
                                      : dersCardFront(course),
                                ),
                              );
                            },
                          ),
                        ),
                        ipucuMaskot(),
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

  Widget dersCardFront(Map<String, dynamic> course) {
    return Container(
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
            Text(course['title'], style: const TextStyle(fontSize: 22, color: Colors.white, fontFamily: 'Poppins-Regular')),
            const SizedBox(height: 12),
            Image.asset(course['icon'], height: 50),
            const SizedBox(height: 20),
            Icon(course['locked'] ? Icons.lock : Icons.lock_open, color: Colors.black, size: 35),
          ],
        ),
      ),
    );
  }

  Widget dersCardFlipped(Map<String, dynamic> course) {
    return Container(
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
            Text(course['description'], style: const TextStyle(fontSize: 18, color: Colors.white, fontFamily: 'Poppins-Regular'), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                dersiSec(course['lessonId']);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Seç", style: TextStyle(fontSize: 20, fontFamily: 'Poppins-Regular')),
            ),
          ],
        ),
      ),
    );
  }

  Widget ipucuMaskot() {
    return Stack(
      children: [
        SizedBox(
          height: 220,
          width: double.infinity,
          child: Image.asset('assets/yan_konusmabaloncuklu_maskot.png', fit: BoxFit.contain),
        ),
        const Positioned(
          left: 30,
          top: 0,
          child: Text(
            "İpucu!\nTemel seviye için \nalgoritmalar dersini\nöneriyoruz.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 17, fontFamily: 'Poppins-Regular'),
          ),
        ),
      ],
    );
  }
}