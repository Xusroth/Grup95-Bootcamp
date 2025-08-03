import 'package:android_studio/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:android_studio/constants.dart';
import 'package:android_studio/auth_service.dart';

class LevelTestPage extends StatefulWidget {
  final int lessonId;

  const LevelTestPage({
    super.key,
    required this.lessonId,
  });

  @override
  State<LevelTestPage> createState() => _LevelTestPageState();
}

class _LevelTestPageState extends State<LevelTestPage>
    with SingleTickerProviderStateMixin {
  
  List<Map<String, dynamic>> questions = [];
  Map<int, String> userAnswers = {}; 
  int currentQuestionIndex = 0;
  bool isLoading = true;
  bool isSubmitting = false;
  double progress = 0.0;
  
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    
    fetchLevelTestQuestions();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Future<void> fetchLevelTestQuestions() async {
    final token = await AuthService().getString('token');
    final userId = await AuthService().getString('user_id');

    try {
      final response = await http.post(
        Uri.parse('$baseURL/lesson/users/$userId/level-test/${widget.lessonId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          questions = List<Map<String, dynamic>>.from(data['questions']);
          isLoading = false;
        });
        _slideController.forward();
      } else {
        throw Exception('Seviye testi soruları yüklenemedi');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> submitLevelTest() async {
    if (userAnswers.length != questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm soruları cevaplayın')),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    final token = await AuthService().getString('token');
    final userId = await AuthService().getString('user_id');

  
    List<Map<String, dynamic>> answers = userAnswers.entries
        .map((entry) => {
              'question_id': entry.key,
              'selected_answer': entry.value,
            })
        .toList();

    try {
      final response = await http.post(
        Uri.parse('$baseURL/lesson/users/$userId/level_test/submit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'answers': answers,
        }),
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        final userLevel = userData['level'];
        
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LevelTestResultPage(
              userLevel: userLevel,
              totalQuestions: questions.length,
              correctCount: _calculateCorrectAnswers(),
            ),
          ),
        );
      } else {
        throw Exception('Seviye testi gönderilemedi');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  int _calculateCorrectAnswers() {
    int correct = 0;
    for (var question in questions) {
      final questionId = question['id'];
      final userAnswer = userAnswers[questionId];
      final correctAnswer = question['correct_answer'];
      if (userAnswer == correctAnswer) {
        correct++;
      }
    }
    return correct;
  }

  Future<void> navigateToHome() async {
    try {
      final token = await AuthService().getString('token');
      final response = await http.get(
        Uri.parse('$baseURL/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        final userName = userData['username'] ?? '';
        final userEmail = userData['email'] ?? '';
        
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              userName: userName,
              userMail: userEmail,
            ),
          ),
          (route) => false, 
        );
      } else {
        
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              userName: '',
              userMail: '',
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            userName: '',
            userMail: '',
          ),
        ),
        (route) => false,
      );
    }
  }

  void handleAnswer(String answer) {
    setState(() {
      userAnswers[questions[currentQuestionIndex]['id']] = answer;
      progress = userAnswers.length / questions.length;
    });
  }

  void nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
      _slideController.reset();
      _slideController.forward();
    }
  }

  void previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
      });
      _slideController.reset();
      _slideController.forward();
    }
  }

  Color getAnswerColor(String option, int optionIndex) {
    final questionId = questions[currentQuestionIndex]['id'];
    final selectedAnswer = userAnswers[questionId];
    
    if (selectedAnswer == null) {
      return Colors.white.withOpacity(0.1);
    }
    
    String optionKey = String.fromCharCode(65 + optionIndex); 
    if (selectedAnswer == optionKey) {
      return Colors.amber; 
    }
    
    return Colors.white.withOpacity(0.1);
  }

  Widget buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Text(
            'Soru ${currentQuestionIndex + 1}/${questions.length}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'Poppins-Medium',
            ),
          ),
          const Spacer(),
          Expanded(
            flex: 3,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.purpleAccent, Colors.deepPurple],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "${(progress * 100).round()}%",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'Poppins-Medium',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Seviye Testi')),
        body: const Center(
          child: Text('Sorular yüklenemedi'),
        ),
      );
    }

    final currentQuestion = questions[currentQuestionIndex];
    final questionId = currentQuestion['id'];
    final isQuestionAnswered = userAnswers.containsKey(questionId);

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
            child: Column(
              children: [
                
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                      const Expanded(
                        child: Text(
                          'Seviye Belirleme Testi',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontFamily: 'Poppins-SemiBold',
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), 
                    ],
                  ),
                ),
                
              
                buildProgressIndicator(),
                
              
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          image: const DecorationImage(
                            image: AssetImage('assets/corner_gradient_rectangle_long.png'),
                            fit: BoxFit.fill,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(30),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                          
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  currentQuestion['content'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontFamily: 'Poppins-Regular',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              
                              const SizedBox(height: 30),
                              
                       
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(4, (index) {
                                    String optionKey = String.fromCharCode(65 + index);
                                    String optionText = currentQuestion['options'][index];
                                    
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Container(
                                        width: double.infinity,
                                        height: 70,
                                        decoration: BoxDecoration(
                                          color: getAnswerColor(optionText, index),
                                          borderRadius: BorderRadius.circular(20),
                                          border: userAnswers[questionId] == optionKey
                                              ? Border.all(color: Colors.white, width: 2)
                                              : null,
                                        ),
                                        child: TextButton(
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                            alignment: Alignment.centerLeft,
                                          ),
                                          onPressed: () => handleAnswer(optionKey),
                                          child: Text(
                                            "$optionKey) $optionText",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontFamily: 'Poppins-Regular',
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
                      ),
                    ),
                  ),
                ),
                
          
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                 
                      if (currentQuestionIndex > 0)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: previousQuestion,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white24,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text('Önceki'),
                          ),
                        ),
                      
                      if (currentQuestionIndex > 0) const SizedBox(width: 15),
            
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: isQuestionAnswered
                              ? (currentQuestionIndex == questions.length - 1
                                  ? submitLevelTest
                                  : nextQuestion)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isQuestionAnswered
                                ? Colors.amber
                                : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  currentQuestionIndex == questions.length - 1
                                      ? 'Testi Bitir'
                                      : 'Sonraki',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins-SemiBold',
                                  ),
                                ),
                        ),
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
}


class LevelTestResultPage extends StatelessWidget {
  final String userLevel;
  final int totalQuestions;
  final int correctCount;

  const LevelTestResultPage({
    super.key,
    required this.userLevel,
    required this.totalQuestions,
    required this.correctCount,
  });

  String getLevelText(String level) {
    switch (level) {
      case 'beginner':
        return 'Başlangıç';
      case 'intermediate':
        return 'Orta';
      case 'advanced':
        return 'İleri';
      default:
        return level;
    }
  }

  Color getLevelColor(String level) {
    switch (level) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
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
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            size: 80,
                            color: Colors.amber,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Seviye Testi Tamamlandı!',
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontFamily: 'Poppins-Bold',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 15),
                            decoration: BoxDecoration(
                              color: getLevelColor(userLevel),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Seviyeniz: ${getLevelText(userLevel)}',
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontFamily: 'Poppins-SemiBold',
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            '$correctCount / $totalQuestions doğru cevap',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              fontFamily: 'Poppins-Regular',
                            ),
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color.fromARGB(255, 60, 138, 63), 
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: const Text(
                                'Ana Sayfaya Dön',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Poppins-SemiBold',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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