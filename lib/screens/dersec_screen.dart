import 'dart:math';
import 'package:flutter/material.dart';
import 'package:android_studio/lessons/algorithmlesson.dart';
import 'package:android_studio/lessons/pythonlesson.dart';
import 'package:android_studio/lessons/javalesson.dart';
import 'package:android_studio/lessons/csharplesson.dart';
import 'package:android_studio/screens/user_mainpage.dart';

class DersSec extends StatefulWidget {
  const DersSec({super.key});

  @override
  State<DersSec> createState() => _DersSecState();
}

class _DersSecState extends State<DersSec> {
  int? flippedIndex;

  final bool algoritmaKilit = false;
  final bool pythonKilit = false;
  final bool javaKilit = true;
  final bool csharpKilit = true;

  void handleFlip(int index) {
    setState(() {
      if (flippedIndex == index) {
        flippedIndex = null;
      } else {
        flippedIndex = index;
      }
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
        'page': const AlgorithmLesson(),
      },
      {
        'title': 'Python',
        'icon': 'assets/python_icon.png',
        'description': 'Python programlamaya giriş.',
        'locked': pythonKilit,
        'page': const PythonLesson(),
      },
      {
        'title': 'Java',
        'icon': 'assets/java_icon.png',
        'description': 'Java ile nesne yönelimli programlama.',
        'locked': javaKilit,
        'page': const JavaLesson(),
      },
      {
        'title': 'C#',
        'icon': 'assets/python_icon.png',
        'description': 'C# ile Windows uygulamaları.',
        'locked': csharpKilit,
        'page': const CsharpLesson(),
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF2D213B),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 48),
        child: Column(
          children: [

            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: const Center(
                child: Text(
                  "Ders Seç",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 50,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            Expanded(
              child: GridView.builder(
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
                    onTap: () => handleFlip(index),
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
                      layoutBuilder: (currentChild, previousChildren) => currentChild!,
                      child: isFlipped
                          ? Card(
                        key: const ValueKey(true),
                        color: Colors.white10,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                course['description'],
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.white70,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () {
                                  if (course['locked']) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Bu ders kilitli 🔒",
                                          style: TextStyle(fontSize: 32),
                                          textAlign: TextAlign.center,
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => course['page'],
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.yellow,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text("Seç", style: TextStyle(fontSize: 20),),
                              ),
                            ],
                          ),
                        ),
                      )
                          : Card(
                        key: const ValueKey(false),
                        color: Colors.yellow,
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(course['icon'], height: 50),
                            const SizedBox(height: 16),
                            Text(
                              course['title'],
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Icon(
                              course['locked'] ? Icons.lock : Icons.lock_open,
                              color: Colors.black,
                              size: 35,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
