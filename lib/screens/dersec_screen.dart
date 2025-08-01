import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:android_studio/constants.dart';
import 'package:android_studio/auth_service.dart';
import 'package:android_studio/screens/profile.dart';
import 'package:android_studio/screens/home_screen.dart';
import 'package:android_studio/screens/quest_screen.dart';
import 'package:android_studio/screens/ReportScreen1.dart';
import 'package:android_studio/screens/SifirdanBaslaSayfasi.dart';

import 'package:android_studio/lessons/algorithmlesson.dart';
import 'package:android_studio/lessons/pythonlesson.dart';
import 'package:android_studio/lessons/javalesson.dart';
import 'package:android_studio/lessons/csharplesson.dart';

class DersSec extends StatefulWidget {
  final String userName;
  final String userMail;

  const DersSec({super.key, required this.userName, required this.userMail});

  @override
  State<DersSec> createState() => _DersSecState();
}

class _DersSecState extends State<DersSec> {
  int? flippedIndex;
  final bool algoritmaKilit = false;
  final bool pythonKilit = false;
  final bool javaKilit = true;
  final bool csharpKilit = true;
  List<dynamic> streakList = [];

  String avatarPath = 'profile_pic.png';
  int healthCount = 6;
  int streakCount = 0;
  

  @override
  void initState() {
    super.initState();
    loadAvatar();
    fetchUserStatus();
  }

  Future<void> loadAvatar() async {
    final auth = AuthService();
    final avatar = await auth.getString('user_avatar');
    setState(() {
      avatarPath = avatar ?? 'profile_pic.png';
    });
  }

  Future<void> fetchUserStatus() async {
    final token = await AuthService().getString('token');
    try {
      final healthRes = await http.get(
        Uri.parse('$baseURL/auth/health_count'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final streakRes = await http.get(
        Uri.parse('$baseURL/auth/streaks'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (healthRes.statusCode == 200) {
        final healthData = json.decode(healthRes.body);
        healthCount = healthData['health_count'];
      }
      if (streakRes.statusCode == 200) {
      final List<dynamic> fetchedStreaks = json.decode(streakRes.body);

      if (fetchedStreaks.isNotEmpty) {
        
        streakList = fetchedStreaks;

        
        fetchedStreaks.sort((a, b) => b['streak_count'].compareTo(a['streak_count']));
        streakCount = fetchedStreaks[0]['streak_count'];
      } else {
        streakCount = 0;
      }
    }
      setState(() {});
    } catch (e) {
      print("Hata: $e");
    }
  }

  String getBatteryAsset(int count) {
    if (count <= 0) return 'assets/batteries/battery_0.png';
    if (count == 1) return 'assets/batteries/battery_1.png';
    if (count == 2) return 'assets/batteries/battery_2.png';
    if (count == 3) return 'assets/batteries/battery_3.png';
    if (count == 4) return 'assets/batteries/battery_4.png';
    if (count == 5) return 'assets/batteries/battery_5.png';
    return 'assets/batteries/battery_6.png';
  }

  Future<void> dersiSec(int lessonId) async {
    final authService = AuthService();
    final token = await authService.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Giriş yapılmamış.")));
      return;
    }

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
      final errorMessage =
          json.decode(dersKayitResponse.body)['detail'] ?? "Bir hata oluştu";
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Ders seçilemedi: $errorMessage")));
    }
  }

  void handleFlip(int index, bool locked) {
    if (locked) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color.fromARGB(181, 45, 33, 59),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.hourglass_bottom,
                  color: Color(0xFFFFC107),
                  size: 48,
                ),
                SizedBox(height: 16),
                Text(
                  "ÇOK YAKINDA!!!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins-Bold',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              Center(
                child: TextButton(
                  child: const Text(
                    "Tamam",
                    style: TextStyle(color: Colors.amber),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          );
        },
      );
      return;
    }

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
            child: Image.asset('assets/arkaplan.png', fit: BoxFit.cover),
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
                        width: 400,
                        height: 70,
                        fit: BoxFit.contain,
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
                                image: DecorationImage(
                                  image: AssetImage(
                                    avatarPath.startsWith('avatar_')
                                        ? 'assets/avatars/$avatarPath'
                                        : 'assets/$avatarPath',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                                border: Border.all(
                                  color: const Color.fromARGB(255, 59, 59, 59),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                widget.userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Poppins-Regular',
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Row(
                                children: [
                                  Image.asset(
                                    getBatteryAsset(healthCount),
                                    height: 55,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$healthCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Poppins-Bold',
                                      fontSize: 20,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Row(
                                children: [
                                  Image.asset('assets/streak.png', height: 36),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$streakCount',
                                    style: const TextStyle(
                                      color: Colors.deepOrange,
                                      fontFamily: 'Poppins-Bold',
                                      fontSize: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReportScreen1(),
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(top: 16, bottom: 24),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
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
                                  final rotate = Tween(
                                    begin: pi,
                                    end: 0.0,
                                  ).animate(animation);
                                  return AnimatedBuilder(
                                    animation: rotate,
                                    child: child,
                                    builder: (context, child) {
                                      final isUnder =
                                          (ValueKey(isFlipped) != child!.key);
                                      final rotationY = isUnder ? pi : 0.0;
                                      return Transform(
                                        transform: Matrix4.rotationY(
                                          rotationY + rotate.value,
                                        ),
                                        alignment: Alignment.center,
                                        child: child,
                                      );
                                    },
                                  );
                                },
                                layoutBuilder: (currentChild, _) =>
                                    currentChild!,
                                child: isFlipped
                                    ? dersCardFlipped(course)
                                    : dersCardFront(course),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        ipucuMaskot(),
                        const SizedBox(
                          height: 80,
                        ), // Alt bar için boşluk bıraktık
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sabit Alt Bar
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.transparent,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 350,
                    child: Image.asset("assets/alt_bar.png", fit: BoxFit.fill),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 60.0,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HomeScreen(
                                  userMail: '',
                                  userName: widget.userName,
                                ),
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
                                builder: (_) => DersSec(
                                  userMail: '',
                                  userName: widget.userName,
                                ),
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
                                builder: (_) =>
                                    ProfilePage(userName: widget.userName),
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
            Text(
              course['title'],
              style: const TextStyle(fontSize: 22, color: Colors.white),
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
            Text(
              course['description'],
              style: const TextStyle(fontSize: 18, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => dersiSec(course['lessonId']),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text("Seç", style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }

  Widget ipucuMaskot() {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 150,
              width: double.infinity,
              child: Image.asset('assets/kart1.png', fit: BoxFit.contain),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "İpucu!\nTemel seviye için algoritmalar dersini öneriyoruz.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color.fromARGB(206, 255, 255, 255),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black45,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}