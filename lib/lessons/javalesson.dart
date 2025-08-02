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

class JavaLessonOverview extends StatefulWidget {
  final String userName;
  final int lessonId;

  const JavaLessonOverview({super.key, required this.userName, required this.lessonId});

  @override
  State<JavaLessonOverview> createState() => _JavaLessonOverviewState();
}

class _JavaLessonOverviewState extends State<JavaLessonOverview> {
  List<Map<String, dynamic>> accessibleSections = [];
  String avatarPath = 'profile_pic.png';
  int healthCount = 6;
  int streakCount = 0;
  List<dynamic> streakList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAvatar();
    fetchUserStatus();
    fetchAccessibleSections();
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

  Future<void> fetchAccessibleSections() async {
    final token = await AuthService().getString('token');
    final userId = await AuthService().getUserIdFromToken(); 

    if (userId == null) {
      print("Kullanıcı ID bulunamadı");
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseURL/progress/users/$userId/lessons/${widget.lessonId}/accessible-sections'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          accessibleSections = data.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      } else {
        print("Hata: ${response.statusCode} - ${response.body}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Bağlantı hatası: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  String getImageAsset(Map<String, dynamic> section) {
    if (!section['is_accessible']) return 'assets/bos_ders.png';
    if (section['is_completed']) return 'assets/3-3_ders.png';
    
    final currentSubsection = section['current_subsection'] as String?;
    switch (currentSubsection) {
      case 'beginner': return 'assets/bos_ders.png';
      case 'intermediate': return 'assets/1-3_ders.png';
      case 'advanced': return 'assets/2-3_ders.png';
      case 'completed': return 'assets/3-3_ders.png';
      default: return 'assets/bos_ders.png';
    }
  }

  Widget getSubsectionWidget(Map<String, dynamic> section) {
    if (section['is_completed']) {
      return SizedBox(
        height: 90,
        child: Center(
          child: Image.asset('assets/tick.png', height: 80),
        ),
      );
    }
    if (!section['is_accessible']) {
      return const SizedBox.shrink();
    }
    
    final subsectionCompletion = section['subsection_completion'] as int? ?? 0;
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

  String getStatusText(Map<String, dynamic> section) {
    if (!section['is_accessible']) return "Kilitli Aşama";
    if (section['is_completed']) return "Tamamlandı";
    
    final currentSubsection = section['current_subsection'] as String?;
    if (currentSubsection == null) return "Devam Ediyor";
    
    return "Devam Ediyor";
  }

  Color getStatusColor(Map<String, dynamic> section) {
    if (!section['is_accessible']) return const Color.fromARGB(226, 255, 255, 255);
    if (section['is_completed']) return Colors.greenAccent;
    return Colors.yellowAccent;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/arkaplan.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final beginner = accessibleSections.where((e) => e['order'] <= 10).toList();
    final intermediate = accessibleSections.where((e) => e['order'] > 10 && e['order'] <= 20).toList();
    final advanced = accessibleSections.where((e) => e['order'] > 20).toList();

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
                      children: [
                        Image.asset(
                          'assets/user_bar.png',
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: 70,
                        ),
                        Positioned.fill(
                          child: Row(
                            children: [
                              
                              GestureDetector(
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
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
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

                              
                              Expanded(
                                child: Text(
                                  widget.userName,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Poppins-Regular',
                                    fontSize: 16,
                                  ),
                                ),
                              ),

                            
                              Row(
                                children: [
                                  Image.asset(getBatteryAsset(healthCount), height: 48),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$healthCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Poppins-Bold',
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),

                              
                              Row(
                                children: [
                                  Image.asset('assets/streak.png', height: 32),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$streakCount',
                                    style: const TextStyle(
                                      color: Colors.deepOrange,
                                      fontFamily: 'Poppins-Bold',
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),

                           
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => ReportScreen1()),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Image.asset('assets/report.png', height: 28),
                                ),
                              ),
                            ],
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
                        final items = group['items'] as List<Map<String, dynamic>>;

                        if (items.isEmpty) return const SizedBox.shrink();

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
                                  final imageAsset = getImageAsset(section);

                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          if (section['is_accessible'] && !section['is_completed']) {
                                            final currentSubsection = section['current_subsection'] as String? ?? 'beginner';
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => QuestionPage(
                                                  sectionIndex: section['order'] - 1,
                                                  levelIndex: 0,
                                                  sectionId: section['id'],
                                                  isLevelCompleted: section['is_completed'],
                                                  lessonId: widget.lessonId,
                                                  currentSubsection: currentSubsection,
                                                ),
                                              ),
                                            ).then((_) {
                                             
                                              fetchAccessibleSections();
                                              fetchUserStatus();
                                            });
                                          }
                                        },
                                        child: SizedBox(
                                          width: 140,
                                          height: 140,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Image.asset(imageAsset, width: 140, height: 140),
                                              if (!section['is_accessible'])
                                                Image.asset('assets/kilitli_dosya.png', height: 60),
                                              if (section['is_accessible'])
                                                Align(
                                                  alignment: Alignment.center,
                                                  child: getSubsectionWidget(section),
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
                                        getStatusText(section),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontFamily: 'Poppins-Regular',
                                          color: getStatusColor(section),
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