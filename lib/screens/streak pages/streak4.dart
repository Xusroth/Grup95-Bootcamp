import 'package:flutter/material.dart';

class StreakPage4 extends StatelessWidget {
  const StreakPage4({super.key});

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
                'assets/level4.png',
                width: 180,
                height: 180,
              ),
              const SizedBox(height: 20),
              const Text(
                "HER YER YANIYOR🔥🔥🔥🔥🔥\nSen bir efsanesin",
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
