import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:android_studio/constants.dart';
import 'package:android_studio/auth_service.dart';
import 'package:android_studio/lessons/algorithmlesson.dart';
import 'package:android_studio/screens/ReportScreen1.dart';

class SeviyeSecSayfasi extends StatefulWidget {
  final String userMail;
  final String userName;

  const SeviyeSecSayfasi({
    super.key,
    required this.userMail,
    required this.userName,
  });

  @override
  State<SeviyeSecSayfasi> createState() => _SeviyeSecSayfasiState();
}

class _SeviyeSecSayfasiState extends State<SeviyeSecSayfasi> {
  String userRole = 'guest';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserRole();
  }

  Future<void> fetchUserRole() async {
    final token = await AuthService().getString('token');
    if (token == null) {
      setState(() {
        userRole = 'guest';
        isLoading = false;
      });
      return;
    }

    final response = await http.get(
      Uri.parse('$baseURL/auth/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        userRole = data['role'] ?? 'guest';
        isLoading = false;
      });
    } else {
      print('auth/me başarısız: ${response.statusCode}');
      setState(() {
        userRole = 'guest';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isGuest = userRole == 'guest';

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/arkaplan.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
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
            ),
          ),
          Center(
            child: isLoading
                ? const CircularProgressIndicator()
                : Stack(
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
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
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
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AlgorithmLessonOverview(
                                    userName: widget.userName,
                                    lessonId: 1,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.1),
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
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
                          isGuest
                              ? Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
                                )
                              : ElevatedButton(
                                  onPressed: () {
                                    // Seviye testi başlat
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white.withOpacity(0.1),
                                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
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
