import 'package:flutter/material.dart';
import 'package:android_studio/screens/welcome_screen2.dart';
import 'package:android_studio/screens/dersec_screen.dart';
import 'package:gradient_slide_to_act/gradient_slide_to_act.dart'; //kaydırmalı buton için

class WelcomeScreen1 extends StatelessWidget {
  const WelcomeScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Arkaplan görseli
          Image.asset(
            'assets/arkaplan.png',
            fit: BoxFit.fill,
          ),

          // Üstündeki içerikler
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Codebite'la Tanışın!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins-Bold',
                      fontSize: 30,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // alttaki masokt
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/konusmabaloncuklu_maskot.png',
                        height: 400,
                      ),
                      const Positioned(
                        top: 45,
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "Selam! \n Codebite'a Hoşgeldin.",
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: 'Poppins-Medium',
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
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

                  // Slide buton
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