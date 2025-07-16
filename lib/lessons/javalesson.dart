import 'package:flutter/material.dart';

class JavaLessonOverview extends StatefulWidget {
  final String userNickname;

  const JavaLessonOverview({super.key, required this.userNickname});

  @override
  State<JavaLessonOverview> createState() => _JavaLessonOverviewState();
}

class _JavaLessonOverviewState extends State<JavaLessonOverview> {
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

      // Kart tamamlandıysa sıradaki açılıyor
      if (level['completedContent'] == 3 && levelIndex < 5) {
        // Bir sonraki kartı açmak için hiçbir işlem gerekmiyor çünkü zaten build içinde kontrol var
      }

      // Eğer tüm kartlar tamamlandıysa, bir sonraki section açılır
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
          child: Column(
            children: [
              // Kullanıcı Barı
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
                        'Merhaba ${widget.userNickname}',
                        style: const TextStyle(fontFamily: 'Poppins-Regular', color: Colors.white, fontSize: 14),
                      ),
                    ),
                    Positioned(right: 48, child: Image.asset('assets/health_bar.png', height: 24)),
                    Positioned(right: 20, child: Image.asset('assets/report.png', height: 22)),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Ders içerikleri
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
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
                            style: const TextStyle(fontFamily: 'Poppins-SemiBold', fontSize: 18, color: Colors.white),
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

                              // ilk kart açık, diğerleri bir önceki 3/3 ise açık
                              final isUnlocked = section['unlocked'] &&
                                  (levelIndex == 0 ||
                                      levels[levelIndex - 1]['completedContent'] == 3);

                              String imageAsset;
                              if (completedContent == 3) {
                                imageAsset = 'assets/3-3_ders.png';
                              } else if (completedContent ==1) {
                                imageAsset = 'assets/1-3_ders.png';
                              }  else if (completedContent ==2) {
                                imageAsset = 'assets/2-3_ders.png';
                              } else {
                                imageAsset = 'assets/bos_ders.png';
                              }

                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (isUnlocked) {
                                        onContentCompleted(sectionIndex, levelIndex);
                                      }
                                    },
                                    child: SizedBox(
                                      width: 140,
                                      height: 140,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Image.asset(
                                            imageAsset,
                                            width: 140,
                                            height: 140,
                                          ),
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
                                  if (!isUnlocked)
                                    const Text(
                                      "Kilitli Aşama",
                                      style: TextStyle(fontSize: 14, fontFamily: 'Poppins-Regular', color: Colors.white70),
                                      textAlign: TextAlign.center,
                                    )
                                  else if (completedContent < 3)
                                    const Text(
                                      "Devam Ediyor",
                                      style: TextStyle(fontSize: 14, fontFamily: 'Poppins-Regular', color: Colors.white70),
                                      textAlign: TextAlign.center,
                                    )
                                  else
                                    const Text(
                                      "Tamamlandı",
                                      style: TextStyle(fontSize: 14, fontFamily: 'Poppins-Regular', color: Colors.white70),
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
        ),
      ),
    );
  }
}
