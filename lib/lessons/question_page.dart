import 'package:flutter/material.dart';
import 'package:android_studio/lessons/general_question_page.dart';

class QuestionPage extends StatefulWidget {
  const QuestionPage({super.key});

  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> with SingleTickerProviderStateMixin {
  String selectedAnswer = '';
  bool answered = false;
  bool isCorrect = false;

  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  final String questionText = "Aşağıdakilerden hangisi python kütüphanesi değildir? ";
  final Map<String, String> options = {
    "A": "pandas",
    "B": "numpy",
    "C": "matplotlib",
    "D": "sockpp"
  };
  final String correctAnswer = "D";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  void handleAnswer(String key) {
    if (answered) return;

    setState(() {
      selectedAnswer = key;
      answered = true;
      isCorrect = key == correctAnswer;
    });

    _controller.forward();
  }

  Color getButtonColor(String key) {
    if (!answered) return Colors.white.withOpacity(0.1);
    if (key == correctAnswer) return Colors.green;
    if (key == selectedAnswer) return Colors.red;
    return Colors.white.withOpacity(0.1);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Arka plan
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
                    // Profil fotoğrafı
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

                    // Progress bar
                    Expanded(
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          // Arka plan bar
                          Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          // Dolu kısım
                          FractionallySizedBox(
                            widthFactor: 0.2, // ilerleme belirleme değişkeni
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.purpleAccent, Colors.deepPurple],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          // Yüzde metni
                          const Positioned(
                            left: 10,
                            child: Text(
                              "%0",
                              style: TextStyle(
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

                        Image.asset('assets/report.png', height: 24),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Soru ve cevaplar
          Center(
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Image.asset(
                  'assets/corner_gradient_rectangle.png',
                  width: 400,
                  height: 430,
                ),

                Padding(
                  padding: const EdgeInsets.only(top: 40.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Soru metni
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(horizontal: 80, vertical:20 ),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          questionText,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),


                      // Cevap şıkları
                      SizedBox(
                        width: 260,
                        child: GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: 2,
                          mainAxisSpacing: 30,
                          crossAxisSpacing: 30,
                          childAspectRatio: 2.7,
                          physics: const NeverScrollableScrollPhysics(),
                          children: options.entries.map((entry) {
                            return ElevatedButton(
                              onPressed: () => handleAnswer(entry.key),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: getButtonColor(entry.key),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              child: Text(
                                "${entry.key}) ${entry.value}",
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Cevap sonrası çıkan alttan panel
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
                      isCorrect ? "Tebrikler!" : "Tekrar etmeye gelişmeye devam et",
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GeneralQuestionPage(),
                          ),
                        );
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
