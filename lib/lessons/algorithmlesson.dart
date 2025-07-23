import 'package:flutter/material.dart';
import 'package:android_studio/lessons/question_page.dart';
import 'package:android_studio/screens/home_screen.dart';
import 'package:android_studio/screens/dersec_screen.dart';
import 'package:android_studio/screens/quest_screen.dart';
import 'package:android_studio/screens/profile.dart';




class AlgorithmLessonOverview extends StatefulWidget {
  final String userName;

  const AlgorithmLessonOverview({super.key, required this.userName});

  @override
  State<AlgorithmLessonOverview> createState() => _AlgorithmLessonOverviewState();
}

class _AlgorithmLessonOverviewState extends State<AlgorithmLessonOverview> {
  List<Map<String, dynamic>> lessonSections = [
    {   
      'title': "Beginner",
      'unlocked': true,
      'levels': List.generate(10, (_) => {'completedContent': 0}),
    },
    {
      'title': 'Intermediate',
      'unlocked': false,
      'levels': List.generate(10, (_) => {'completedContent': 0}),
    },
    {
      'title': 'Advanced',
      'unlocked': false,
      'levels': List.generate(10, (_) => {'completedContent': 0}),
    },
  ];

  void onContentCompleted(int sectionIndex, int levelIndex) {
    setState(() {
      final level = lessonSections[sectionIndex]['levels'][levelIndex];
      if (level['completedContent'] < 3) {
        level['completedContent']++;
      }

      final allCompleted = lessonSections[sectionIndex]['levels']
          .every((lvl) => lvl['completedContent'] == 3);

      if (allCompleted && sectionIndex + 1 < lessonSections.length) {
        lessonSections[sectionIndex + 1]['unlocked'] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
              // Sayfanın üst kısmı: Kullanıcı barı + içerikler
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Image.asset('assets/user_bar.png', fit: BoxFit.contain, width: 400, height: 70),
                        Positioned(left: 16, child: Image.asset('assets/profile_pic.png', height: 36)),
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
                        Positioned(right: 48, child: Image.asset('assets/health_bar.png', height: 24)),
                        Positioned(right: 20, child: Image.asset('assets/report.png', height: 22)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // İçerik: ders kartları
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: lessonSections.length,
                      itemBuilder: (context, sectionIndex) {
                        final section = lessonSections[sectionIndex];
                        final levels = section['levels'];

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                section['title'],
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
                                itemCount: levels.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 20,
                                  crossAxisSpacing: 20,
                                  childAspectRatio: 1,
                                ),
                                itemBuilder: (context, levelIndex) {
                                  final level = levels[levelIndex];
                                  final completedContent = level['completedContent'];

                                  final isUnlocked = section['unlocked'] &&
                                      (levelIndex == 0 ||
                                          levels[levelIndex - 1]['completedContent'] == 3);

                                  final isCompleted = completedContent == 3;

                                  String imageAsset;
                                  if (completedContent == 3) {
                                    imageAsset = 'assets/3-3_ders.png';
                                  } else if (completedContent == 2) {
                                    imageAsset = 'assets/2-3_ders.png';
                                  } else if (completedContent == 1) {
                                    imageAsset = 'assets/1-3_ders.png';
                                  } else {
                                    imageAsset = 'assets/bos_ders.png';
                                  }

                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          if (isUnlocked && !isCompleted) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => QuestionPage(
                                                  sectionIndex: sectionIndex,
                                                  levelIndex: levelIndex,
                                                  isLevelCompleted: isCompleted,
                                                  onCompleted: () {
                                                    onContentCompleted(sectionIndex, levelIndex);
                                                  },
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
                                              if (!isUnlocked)
                                                Image.asset('assets/kilitli_dosya.png', height: 60)
                                              else
                                                Positioned(
                                                  bottom: 54,
                                                  child: Text(
                                                    "$completedContent/3",
                                                    style: const TextStyle(
                                                      fontSize: 20,
                                                      color: Colors.white,
                                                      fontFamily: 'Poppins-Bold',
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        !isUnlocked
                                            ? "Kilitli Aşama"
                                            : isCompleted
                                                ? "Tamamlandı"
                                                : "Devam Ediyor",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Poppins-Regular',
                                          color: Colors.white70,
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

              // Alt Bar (Stack içinde ve Positioned ile)
              Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 350,
                  child: Image.asset(
                    "assets/alt_bar.png",
                    fit: BoxFit.fill,
                  ),
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
                              builder: (_) => ProfilePage(
                                userName: widget.userName,
                              ),
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
          )
            ],
          ),
        ),
      ),
    );
  }
}
