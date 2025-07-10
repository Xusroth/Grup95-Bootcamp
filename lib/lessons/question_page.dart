import 'package:flutter/material.dart';

class QuestionPage extends StatefulWidget {
  final int sectionIndex;
  final int levelIndex;
  final VoidCallback onCompleted;
  final bool isLevelCompleted;

  const QuestionPage({
    super.key,
    required this.sectionIndex,
    required this.levelIndex,
    required this.onCompleted,
    required this.isLevelCompleted,
  });

  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> with SingleTickerProviderStateMixin {
  String selectedAnswer = '';
  bool answered = false;
  bool isCorrect = false;
  int currentQuestionIndex = 0;
  double progress = 0.0;

  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  final List<Map<String, dynamic>> questions = [
    {
      'question': "Aşağıdakilerden hangisi python kütüphanesi değildir?",
      'options': {
        "A": "pandas",
        "B": "numpy",
        "C": "matplotlib",
        "D": "sockpp"
      },
      'correct': "D"
    },
    {
      'question': "Python'da liste elemanlarını sıralamak için hangi fonksiyon kullanılır?",
      'options': {
        "A": "sort()",
        "B": "map()",
        "C": "filter()",
        "D": "list()"
      },
      'correct': "A"
    },
    {
      'question': "Python'da sözlük (dictionary) tanımlamak için kullanılan sembol nedir?",
      'options': {
        "A": "()",
        "B": "[]",
        "C": "{}",
        "D": "<>"
      },
      'correct': "C"
    },
    {
      'question': "Python'da yorum satırı hangi karakterle başlar?",
      'options': {
        "A": "//",
        "B": "/*",
        "C": "#",
        "D": "--"
      },
      'correct': "C"
    },
    {
      'question': "Hangi veri tipi sadece True veya False değerini alır?",
      'options': {
        "A": "int",
        "B": "bool",
        "C": "float",
        "D": "str"
      },
      'correct': "B"
    },
  ];

  @override
  void initState() {
    super.initState();

    // Eğer zaten tamamlandıysa sayfadan çıkar.
    if (widget.isLevelCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
      });
    }

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
      isCorrect = key == questions[currentQuestionIndex]['correct'];
    });

    _controller.forward();
  }

  Color getButtonColor(String key) {
    if (!answered) return Colors.white.withOpacity(0.1);
    if (key == questions[currentQuestionIndex]['correct']) return Colors.green;
    if (key == selectedAnswer) return Colors.red;
    return Colors.white.withOpacity(0.1);
  }

  void goToNextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswer = '';
        answered = false;
        isCorrect = false;
        _controller.reset();
        progress += 0.2;
      });
    } else {
      // Tüm sorular bitince
      widget.onCompleted(); // 3/3 artışı için
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = questions[currentQuestionIndex];

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

          // Kullanıcı barı
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
                    // Profil
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

                    // Progress Bar
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
                                  colors: [Colors.purpleAccent, Colors.deepPurple],
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
                        Image.asset('assets/report.png', height: 24),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Soru kısmı
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
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(horizontal: 80, vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          question['question'],
                          style: const TextStyle(fontSize: 14, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(
                        width: 260,
                        child: GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: 2,
                          mainAxisSpacing: 30,
                          crossAxisSpacing: 30,
                          childAspectRatio: 2.7,
                          physics: const NeverScrollableScrollPhysics(),
                          children: question['options'].entries.map<Widget>((entry) {
                            return ElevatedButton(
                              onPressed: () => handleAnswer(entry.key),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: getButtonColor(entry.key),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                "${entry.key}) ${entry.value}",
                                style: const TextStyle(color: Colors.white, fontSize: 14),
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

          // Alttan çıkan panel
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
                        if (isCorrect) {
                          goToNextQuestion(); // sonraki soruya geç
                        } else {
                          setState(() {
                            answered = false;
                            selectedAnswer = '';
                            isCorrect = false;
                            _controller.reset();
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
                      child: Text(isCorrect ? "Sonraki Soru" : "Tekrar Dene"),
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
