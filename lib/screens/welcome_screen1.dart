import 'package:flutter/material.dart';
import 'package:android_studio/screens/welcome_screen2.dart';
import 'package:gradient_slide_to_act/gradient_slide_to_act.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class WelcomeScreen1 extends StatefulWidget {
  const WelcomeScreen1({super.key});

  @override
  State<WelcomeScreen1> createState() => _WelcomeScreen1State();
}

class _WelcomeScreen1State extends State<WelcomeScreen1> {
  bool showSpeechBubble = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/arkaplan.png',
            fit: BoxFit.fill,
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 50,
                    child: DefaultTextStyle(
                      style: const TextStyle(
                        fontFamily: 'Poppins-Bold',
                        fontSize: 30,
                        color: Colors.white,
                      ),
                      child: AnimatedTextKit(
                        animatedTexts: [
                          TypewriterAnimatedText(
                            "Codebite'la Tanışın!",
                            speed: const Duration(milliseconds: 100),
                          ),
                        ],
                        totalRepeatCount: 1,
                        pause: const Duration(milliseconds: 500),
                        displayFullTextOnTap: true,
                        stopPauseOnTap: true,
                        onFinished: () {
                          setState(() {
                            showSpeechBubble = true;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/konusmabaloncuklu_maskot.png',
                        height: 400,
                      ),
                      if (showSpeechBubble)
                        Positioned(
                          top: 45,
                          left: 15,
                          right: 0,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: DefaultTextStyle(
                              style: const TextStyle(
                                fontSize: 18,
                                fontFamily: 'Poppins-Medium',
                                color: Color.fromARGB(232, 255, 255, 255),
                              ),
                              textAlign: TextAlign.center,
                              child: AnimatedTextKit(
                                animatedTexts: [
                                  TypewriterAnimatedText(
                                    "Selam! \nCodebite'a Hoşgeldin.",
                                    speed: const Duration(milliseconds: 100),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                totalRepeatCount: 10,
                                pause: const Duration(milliseconds: 300),
                                displayFullTextOnTap: true,
                                stopPauseOnTap: true,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    "Sizin için kodlamayı\neğlenceli, etkili ve sürdürülebilir\nhale getirmek için buradayız.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins-Medium',
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 64),

                  GradientSlideToAct(
                    width: 300,
                    text: 'Hadi Başlayalım!',
                    textStyle: const TextStyle(
                      fontFamily: 'Poppins-Regular',
                      color: Colors.white,
                      fontSize: 18,
                    ),
                    backgroundColor: const Color(0x26F3E5FF),
                    dragableIcon: Icons.arrow_forward_ios,
                    onSubmit: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WelcomeScreen2(),
                        ),
                      );
                    },
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF8E2DE2),
                        Color(0xFF4A00E0),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
