import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:android_studio/screens/profile.dart';
import 'package:android_studio/screens/quest_screen.dart';
import 'package:android_studio/screens/home_screen.dart';
import 'package:android_studio/screens/dersec_screen.dart';
import 'package:android_studio/lessons/algorithmlesson.dart';
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
  String avatarPath = 'profile_pic.png';
  int healthCount = 6;
  int streakCount = 0;
  int _selectedIndex = 0;
  List<Map<String, dynamic>> selectedLessons = [];
  List<dynamic> streakList = [];

  @override
  void initState() {
    super.initState();
    fetchDailyTasks();
    loadAvatar();
    fetchUserLessons();
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

  Future<void> fetchUserLessons() async {
    final prefs = AuthService();
    final token = await prefs.getString('token');
    final userId = await prefs.getString('user_id');
    if (userId == null) return;

    final response = await http.get(
      Uri.parse('$baseURL/lesson/users/$userId/lessons'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List lessons = body["lessons"];
      setState(() {
        selectedLessons = lessons
            .map<Map<String, dynamic>>((lesson) => {
                  "title": lesson["title"],
                  "id": lesson["id"],
                })
            .toList();
      });
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
                          Image.asset(
                            'assets/user_bar.png',
                            fit: BoxFit.contain,
                            width: 400,
                            height: 70,
                          ),
                          Positioned(
                            left: 0,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProfilePage(userName: widget.userName),
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
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 62,
                            child: Row(
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
                                    Image.asset(getBatteryAsset(healthCount), height: 55),
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
                              child: Image.asset(
                                'assets/report.png',
                                height: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Günlük Görevler",
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
                    const SizedBox(height: 64),
                    buildLessonSection(),
                    const SizedBox(height: 16),
                    buildLessonCard(
                      "Günlük\nGörev",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => QuestScreen()),
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
        ],
      ),
    );
  }

  Widget buildLessonSection() {
    if (selectedLessons.isEmpty) {
      return const SizedBox.shrink();
    }

    if (selectedLessons.length == 1) {
      final lesson = selectedLessons.first;
      return buildLessonCard(
        lesson["title"],
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AlgorithmLessonOverview(
                userName: widget.userName,
                lessonId: lesson["id"],
              ),
            ),
          );
        },
      );
    } else {
      return Wrap(
        spacing: 0,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: selectedLessons.map((lesson) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AlgorithmLessonOverview(
                    userName: widget.userName,
                    lessonId: lesson["id"],
                  ),
                ),
              );
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset("assets/card.png", width: 170, height: 170),
                Text(
                  lesson["title"],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Poppins-Bold',
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }
  }

  Widget buildLessonCard(String title, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset("assets/genis_card.png", width: 320, height: 200),
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