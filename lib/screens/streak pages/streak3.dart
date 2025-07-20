import 'package:flutter/material.dart';

class StreakPage3 extends StatelessWidget {
  const StreakPage3({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/arkaplan.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/level3.png',
                width: 180,
                height: 180,
              ),
              const SizedBox(height: 20),
              const Text(
                "ATEŞ GİBİSİN 🔥🔥🔥\nİstiktarını koruyorsun!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
