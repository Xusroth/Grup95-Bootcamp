import 'package:flutter/material.dart';
import 'package:android_studio/lessons/question_page.dart';
import 'package:android_studio/screens/home_screen.dart';
import 'package:android_studio/screens/dersec_screen.dart';
import 'package:android_studio/screens/profile.dart';
import 'package:android_studio/screens/ReportScreen1.dart';
import 'package:http/http.dart' as http;
import 'package:android_studio/constants.dart';
import 'dart:convert';
import 'package:android_studio/auth_service.dart';

class AlgorithmLessonOverview extends StatefulWidget {
  final String userName;
  final int lessonId;

  const AlgorithmLessonOverview({super.key, required this.userName, required this.lessonId});

  @override
  State<AlgorithmLessonOverview> createState() => _AlgorithmLessonOverviewState();
}

class _AlgorithmLessonOverviewState extends State<AlgorithmLessonOverview> {
  List<dynamic> allSections = [];
  int currentSectionOrder = 1;
  String currentSubsection = 'beginner';
  int subsectionCompletion = 0;
  Map<int, int> completedQuestionsMap = {};
  String avatarPath = 'profile_pic.png';
  int healthCount = 6;
  int streakCount = 0;
  List<dynamic> streakList = [];

  @override
  void initState() {
    super.initState();
    loadAvatar();
    fetchUserStatus();
    fetchSections();     
    fetchProgress();
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
    if (count <= 0) return 'assets/batteries/battery_empty.png';
    if (count == 1) return 'assets/batteries/battery_1.png';
    if (count == 2) return 'assets/batteries/battery_2.png';
    if (count == 3) return 'assets/batteries/battery_3.png';
    if (count == 4) return 'assets/batteries/battery_4.png';
    if (count == 5) return 'assets/batteries/battery_5.png';
    return 'assets/batteries/battery_full.png';
  }

  Future<void> fetchSections() async {
    final token = await AuthService().getString('token');

    final response = await http.get(
      Uri.parse('$baseURL/sections/lessons/${widget.lessonId}/sections'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        allSections = List.generate(30, (i) => {
          'order': i + 1,
          'title': data.firstWhere(
            (s) => s['order'] == i + 1,
            orElse: () => {'title': ''},
          )['title'],
        });
      });
    }
  }

  Future<void> fetchProgress() async {
    final token = await AuthService().getString('token');

    final progressRes = await http.get(
      Uri.parse('$baseURL/progress/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (progressRes.statusCode == 200) {
      final progressData = jsonDecode(progressRes.body);
      final lessonProgress = progressData.where((e) => e['lesson_id'] == widget.lessonId).toList();

      for (var item in lessonProgress) {
        completedQuestionsMap[item['section_id']] = item['completed_questions'];
      }

      final active = lessonProgress.firstWhere(
        (e) => e['current_subsection'] != 'completed',
        orElse: () => null,
      );

      if (active != null) {
        setState(() {
          currentSectionOrder = active['section_id'];
          currentSubsection = active['current_subsection'];
          subsectionCompletion = active['subsection_completion'];
        });
      } else {
        final maxSection = lessonProgress.map((e) => e['section_id'] as int).fold(0, (a, b) => a > b ? a : b);
        setState(() {
          currentSectionOrder = maxSection + 1;
          currentSubsection = 'beginner';
          subsectionCompletion = 0;
        });
      }
    }
  }

  String getImageAsset(int order) {
    if (order < currentSectionOrder) return 'assets/3-3_ders.png';
    if (order > currentSectionOrder) return 'assets/bos_ders.png';

    switch (currentSubsection) {
      case 'beginner': return 'assets/bos_ders.png';
      case 'intermediate': return 'assets/1-3_ders.png';
      case 'advanced': return 'assets/2-3_ders.png';
      case 'completed': return 'assets/3-3_ders.png';
      default: return 'assets/bos_ders.png';
    }
  }

  bool isUnlocked(int order) => order <= currentSectionOrder;
  bool isCompleted(int order) => order < currentSectionOrder;

  Widget getSubsectionWidget(int order) {
    if (order < currentSectionOrder) {
      return SizedBox(
        height: 90,
        child: Center(
          child: Image.asset('assets/tick.png', height: 80),
        ),
      );
    }
    if (order > currentSectionOrder) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 90,
      child: Center(
        child: Text(
          "$subsectionCompletion/3",
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontFamily: 'Poppins-Bold',
          ),
        ),
      ),
    );
  }

  bool hasIncompleteQuestions(int sectionOrder) {
    final completed = completedQuestionsMap[sectionOrder] ?? 0;
    return completed > 0 && completed % 10 != 0;
  }

  @override
  Widget build(BuildContext context) {
    final beginner = allSections.where((e) => e['order'] <= 10).toList();
    final intermediate = allSections.where((e) => e['order'] > 10 && e['order'] <= 20).toList();
    final advanced = allSections.where((e) => e['order'] > 20).toList();

    final List<Map<String, dynamic>> sectionGroups = [
      {'title': 'Beginner', 'items': beginner},
      {'title': 'Intermediate', 'items': intermediate},
      {'title': 'Advanced', 'items': advanced},
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/arkaplan.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
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
                            left: 65,
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
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: sectionGroups.length,
                      itemBuilder: (context, index) {
                        final group = sectionGroups[index];
                        final title = group['title'] as String;
                        final items = group['items'] as List<dynamic>;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontFamily: 'Poppins-SemiBold',
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: items.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 20,
                                  crossAxisSpacing: 20,
                                  childAspectRatio: 0.95,
                                ),
                                itemBuilder: (context, i) {
                                  final section = items[i];
                                  final order = section['order'];
                                  final unlocked = isUnlocked(order);
                                  final completed = isCompleted(order);
                                  final imageAsset = getImageAsset(order);

                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          if (order == currentSectionOrder) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => QuestionPage(
                                                  sectionIndex: order - 1,
                                                  levelIndex: 0,
                                                  sectionId: order,
                                                  isLevelCompleted: completed,
                                                  lessonId: widget.lessonId,
                                                  currentSubsection: currentSubsection,
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        child: SizedBox(
                                          width: 140,
                                          height: 140,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Image.asset(imageAsset, width: 140, height: 140),
                                              if (!unlocked && !completed)
                                                Image.asset('assets/kilitli_dosya.png', height: 60),
                                              if (order == currentSectionOrder || completed)
                                                Align(
                                                  alignment: Alignment.center,
                                                  child: getSubsectionWidget(order),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        section['title'] ?? '',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                          fontFamily: 'Poppins-SemiBold',
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        !unlocked && !completed
                                            ? "Kilitli Aşama"
                                            : completed
                                                ? "Tamamlandı"
                                                : hasIncompleteQuestions(order)
                                                    ? "Eksiklerini kontrol et"
                                                    : "Devam Ediyor",
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontFamily: 'Poppins-Regular',
                                          color: !unlocked && !completed
                                              ? const Color.fromARGB(226, 255, 255, 255)
                                              : completed
                                                  ? Colors.greenAccent
                                                  : hasIncompleteQuestions(order)
                                                      ? const Color.fromARGB(255, 255, 54, 54)
                                                      : Colors.yellowAccent,
                                        ),  
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(width: 350, child: Image.asset("assets/alt_bar.png", fit: BoxFit.fill)),
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
                                  builder: (_) => HomeScreen(userMail: '', userName: widget.userName),
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
                                  builder: (_) => DersSec(userMail: '', userName: widget.userName),
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
        ),
      ),
    );
  }
}
