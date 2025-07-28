import 'package:android_studio/lessons/result.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:android_studio/constants.dart';
import 'package:android_studio/auth_service.dart';
import 'package:android_studio/screens/ReportScreen1.dart';
import 'package:android_studio/lessons/result.dart'; 

class QuestionPage extends StatefulWidget {
  final int sectionIndex;
  final int levelIndex;
  final bool isLevelCompleted;
  final int sectionId;
  final int lessonId;
  final String currentSubsection;

  const QuestionPage({
    super.key,
    required this.sectionIndex,
    required this.levelIndex,
    required this.isLevelCompleted,
    required this.sectionId,
    required this.lessonId,
    required this.currentSubsection,
  });

  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage>
    with SingleTickerProviderStateMixin {
  String selectedAnswer = '';
  String correctAnswer = '';
  bool answered = false;
  bool isCorrect = false;
  int currentQuestionIndex = 0;
  int correctAnswers = 0;
  double progress = 0.0;

  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  List<Map<String, dynamic>> questions = [];

  Future<void> fetchQuestions() async {
    final token = await AuthService().getString('token');

    final response = await http.get(
      Uri.parse('$baseURL/lesson/questions?lesson_id=${widget.lessonId}&section_id=${widget.sectionId}&current_subsection=${widget.currentSubsection}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        questions = data.cast<Map<String, dynamic>>().take(10).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sorular yüklenemedi')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> sendAnswer(String answer) async {
    final token = await AuthService().getString('token');
    final question = questions[currentQuestionIndex];

    try {
      final response = await http.post(
        Uri.parse('$baseURL/progress/answer_question'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'question_id': question['id'],
          'user_answer': answer,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          correctAnswer = question['correct_answer'];
          isCorrect = true;
          correctAnswers++;
          progress = correctAnswers / questions.length;
        });
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        setState(() {
          correctAnswer = question['correct_answer'];
          isCorrect = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['detail'] ?? 'Yanlış cevap')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cevap gönderilemedi.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bir hata oluştu.')),
      );
    }

    _controller.forward();
  }

  void handleAnswer(String key) {
    if (answered) return;

    setState(() {
      selectedAnswer = key;
      answered = true;
    });

    sendAnswer(key);
  }

  Color getAnswerColor(String key) {
    if (!answered) return Colors.white.withOpacity(0.1);
    if (key == selectedAnswer && isCorrect) return Colors.green;
    if (key == selectedAnswer && !isCorrect) return Colors.red;
    if (key == correctAnswer && !isCorrect) return Colors.green.withOpacity(0.6);
    return Colors.white.withOpacity(0.1);
  }

  @override
  void initState() {
    super.initState();

    if (widget.isLevelCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
      });
    }

    fetchQuestions();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final question = questions[currentQuestionIndex];

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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Container(
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: const DecorationImage(
                          image: AssetImage('assets/profile_pic.png'),
                          fit: BoxFit.cover,
                        ),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: progress,
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Colors.purpleAccent,
                                    Colors.deepPurple,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 10,
                            child: Text(
                              "%${(progress * 100).round()}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontFamily: 'Poppins-Bold',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Image.asset('assets/health_bar.png', height: 24),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReportScreen1(),
                              ),
                            );
                          },
                          child: Image.asset('assets/report.png', height: 24),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Image.asset('assets/corner_gradient_rectangle_long.png', height: 570),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(horizontal: 80, vertical: 30),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          question['content'],
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontFamily: 'Poppins-Regular',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(
                        width: 260,
                        child: Column(
                          children: List.generate(4, (index) {
                            String key = String.fromCharCode(65 + index);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10.0),
                              child: Container(
                                width: double.infinity,
                                height: 75,
                                decoration: BoxDecoration(
                                  color: getAnswerColor(key),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    alignment: Alignment.centerLeft,
                                  ),
                                  onPressed: () => handleAnswer(key),
                                  child: Text(
                                    "$key) ${question['options'][index]}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _offsetAnimation,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green.withOpacity(0.9) : Colors.red.withOpacity(0.9),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isCorrect ? "Tebrikler!" : "Yanıt yanlış",
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () {
                        _controller.reset();

                        if (currentQuestionIndex == questions.length - 1) {
                          Future.delayed(const Duration(milliseconds: 300), () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ResultScreen(
                                  correctAnswers: correctAnswers,
                                  totalQuestions: questions.length,
                                  lessonId: widget.lessonId,
                                  sectionId: widget.sectionId,
                                  currentSubsection: widget.currentSubsection,
                                  levelIndex: widget.levelIndex,
                                  sectionIndex: widget.sectionIndex,
                                ),
                              ),
                            );
                          });
                        } else {
                          setState(() {
                            currentQuestionIndex++;
                            answered = false;
                            selectedAnswer = '';
                            correctAnswer = '';
                            isCorrect = false;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text("Sonraki Soru"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
