import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_studio/constants.dart';
import 'package:android_studio/screens/profile.dart';
import 'package:android_studio/screens/home_screen.dart';
import 'package:android_studio/screens/dersec_screen.dart';

class DailyTask {
  final String taskType;
  final int target;
  final int currentProgress;
  final bool isCompleted;

  DailyTask({
    required this.taskType,
    required this.target,
    required this.currentProgress,
    required this.isCompleted,
  });

  factory DailyTask.fromJson(Map<String, dynamic> json) {
    return DailyTask(
      taskType: json['task_type'],
      target: json['target'],
      currentProgress: json['current_progress'],
      isCompleted: json['is_completed'],
    );
  }

  String displayText(Map<int, String> lessonMap) {
    switch (taskType) {
      case 'solve_questions':
        return '$target soru çöz';
      case 'learn_topic':
        return '$target yeni konu öğren';
      case 'complete_section':
        return '$target bölümü tamamla';
      case 'review_mistakes':
        return '$target hatayı gözden geçir';
      case 'take_level_test':
        return '$target leveli çöz';
      case 'maintain_streak':
        String lessonName = lessonMap[target] ?? 'bir derste';
        return '$lessonName dersindeki streakini koru';
      default:
        return 'Görev';
    }
  }
}

class QuestScreen extends StatefulWidget {
  const QuestScreen({super.key});

  @override
  State<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends State<QuestScreen> {
  String userName = "Kullanıcı";
  String userMail = "";
  List<DailyTask> tasks = [];
  bool isLoading = true;

  final Map<int, String> lessonIdMap = {
    1: "Algoritmalar",
    2: "Python",
    3: "Java",
    4: "C#",
  };

  @override
  void initState() {
    super.initState();
    loadUserInfo();
    loadTasks();
  }

  Future<void> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final response = await http.get(
      Uri.parse('$baseURL/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        userName = data['username'] ?? "Kullanıcı";
        userMail = data['email'] ?? "";
      });
    }
  }

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('$baseURL/tasks/daily'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          tasks = data.map((e) => DailyTask.fromJson(e)).toList();
          isLoading = false;
        });
      } else {
        print("Görev alınamadı: ${response.body}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Görev hatası: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          background(),
          SafeArea(child: mainContent()),
          bottomBar(context),
        ],
      ),
    );
  }

  Widget background() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/arkaplan.png"),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget mainContent() {
    return Column(
      children: [
        userBar(),
        const SizedBox(height: 12),
        progressGraph(),
        const SizedBox(height: 32),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : tasks.isEmpty
                  ? const Center(child: Text("Görev bulunamadı.", style: TextStyle(color: Colors.white)))
                  : ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return buildGorevCard(
                          imagePath: "assets/kart${(index % 3) + 1}.png",
                          gorevYazisi: task.displayText(lessonIdMap),
                          tamamlanan: task.currentProgress,
                          toplam: task.target,
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget userBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Image.asset('assets/user_bar.png', width: 400, height: 70),
          Positioned(left: 16, child: Image.asset('assets/profile_pic.png', height: 36)),
          Positioned(
            left: 60,
            child: Text(
              'Merhaba $userName',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Poppins-Regular'),
            ),
          ),
          Positioned(right: 48, child: Image.asset('assets/health_bar.png', height: 24)),
          Positioned(right: 20, child: Image.asset('assets/report.png', height: 22)),
        ],
      ),
    );
  }

  Widget progressGraph() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Stack(
        children: [
          Image.asset("assets/graph.png", fit: BoxFit.contain),
          const Positioned(
            top: 12,
            left: 16,
            child: Text(
              "Harika\nİlerliyorsun!",
              style: TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Poppins-SemiBold'),
            ),
          ),
          const Positioned(
            right: 12,
            top: 60,
            child: Text(
              "Günlük\nGörevler",
              style: TextStyle(color: Colors.white, fontSize: 15, fontFamily: 'Poppins-Regular'),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget bottomBar(BuildContext context) {
    return Positioned(
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
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HomeScreen(userMail: userMail, userName: userName))),
                  child: Image.asset("assets/home.png", height: 28),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DersSec(userMail: userMail, userName: userName))),
                  child: Image.asset("assets/ders.png", height: 28),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(userName: userName))),
                  child: Image.asset("assets/profile.png", height: 28),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildGorevCard({
    required String imagePath,
    required String gorevYazisi,
    required int tamamlanan,
    required int toplam,
  }) {
    double progress = toplam > 0 ? tamamlanan / toplam : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          width: 360,
          height: 155,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gorevYazisi,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'Poppins-Bold',
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  "$tamamlanan/$toplam Tamamlandı",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontFamily: 'Poppins-SemiBold',
                  ),
                ),
                const Spacer(),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 20,
                    backgroundColor: Colors.black26,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color.fromARGB(255, 28, 179, 28),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
