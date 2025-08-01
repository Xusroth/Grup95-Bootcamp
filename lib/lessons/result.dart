import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:android_studio/auth_service.dart';
import 'package:android_studio/constants.dart';
import 'package:android_studio/lessons/algorithmlesson.dart';
import 'package:android_studio/lessons/question_page.dart';

class ResultScreen extends StatefulWidget {
  final int correctAnswers;
  final int totalQuestions;
  final int lessonId;
  final int sectionId;
  final String currentSubsection;
  final int levelIndex;
  final int sectionIndex;

  const ResultScreen({
    super.key,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.lessonId,
    required this.sectionId,
    required this.currentSubsection,
    required this.levelIndex,
    required this.sectionIndex,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  String userName = "Yükleniyor...";

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final authService = AuthService();
    final storedName = await authService.getString('user_name');
    setState(() {
      userName = storedName ?? "Bilinmeyen";
    });
  }

  Future<void> fetchProgress() async {
    final token = await AuthService().getString('token');
    try {
      final response = await http.get(
        Uri.parse('$baseURL/progress/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print("İlerleme başarıyla güncellendi.");
      } else {
        print("İlerleme alınamadı: ${response.statusCode}");
      }
    } catch (e) {
      print("fetchProgress hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double successRate = (widget.correctAnswers / widget.totalQuestions) * 100;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            "assets/arkaplan.png",
            fit: BoxFit.cover,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Text(
                "${widget.correctAnswers} / ${widget.totalQuestions}  Doğru!",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Poppins-SemiBold',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Başarı: %${successRate.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontFamily: 'Poppins-SemiBold',
                ),
              ),
              const SizedBox(height: 40),
              Image.asset(
                "assets/anasayfa_maskot.png",
                height: 200,
              ),
              const SizedBox(height: 50),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await fetchProgress();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AlgorithmLessonOverview(
                              userName: userName,
                              lessonId: widget.lessonId,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 60, 138, 63),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Devam Et",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Poppins-SemiBold',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (successRate < 100)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuestionPage(
                                sectionIndex: widget.sectionIndex,
                                levelIndex: widget.levelIndex,
                                isLevelCompleted: false,
                                sectionId: widget.sectionId,
                                lessonId: widget.lessonId,
                                currentSubsection: widget.currentSubsection,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 167, 46, 37),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Hatalarını Gözden Geçir",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Poppins-SemiBold',
                          ),
                        ),
                      ),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
