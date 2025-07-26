import 'dart:convert';
import 'package:android_studio/screens/profile.dart';
import 'package:android_studio/screens/quest_screen.dart';
import 'package:flutter/material.dart';
import 'package:android_studio/screens/home_screen.dart';
import 'package:android_studio/screens/dersec_screen.dart';
import 'package:android_studio/lessons/algorithmlesson.dart';
import 'package:http/http.dart' as http;
import 'package:android_studio/constants.dart';
import 'package:android_studio/auth_service.dart';
import 'package:android_studio/screens/ReportScreen1.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final String userMail;

  const HomeScreen({super.key, required this.userName, required this.userMail});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int completedTaskCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDailyTasks();
  }

  Future<void> fetchDailyTasks() async {
    final prefs = AuthService();
    final token = await prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseURL/tasks/daily'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final tasks = jsonDecode(response.body);
      setState(() {
        completedTaskCount = tasks.where((task) => task['is_completed'] == true).length;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = completedTaskCount / 3.0;

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
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProfilePage(userName: widget.userName),
                                  ),
                                );
                              },
                              child: Image.asset('assets/profile_pic.png', height: 36),
                            ),
                          ),
                          Positioned(
                            left: 60,
                            child: Text(
                              'Merhaba ${widget.userName}',
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
                                  MaterialPageRoute(
                                    builder: (context) => ReportScreen1(),
                                  ),
                                );
                              },
                              child: Image.asset('assets/report.png', height: 22),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Günlük Hedefler",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontFamily: 'Poppins-Regular',
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 300,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: isLoading ? 0 : progress,
                          minHeight: 20,
                          backgroundColor: Colors.green.shade900,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color.fromARGB(255, 18, 167, 50),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isLoading ? "Yükleniyor..." : "$completedTaskCount/3 Tamamlandı",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3F3F80),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "Devam Et",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    buildLessonCard(
                      "Python",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AlgorithmLessonOverview(userName: widget.userName),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    buildLessonCard(
                      "Günlük\nGörev",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuestScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
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
                              builder: (_) => ProfilePage(userName: widget.userName),
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

  Widget buildLessonCard(String title, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset("assets/genis_card.png", width: 280, height: 180),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontFamily: 'Poppins-Bold',
            ),
          ),
        ],
      ),
    );
  }
}
