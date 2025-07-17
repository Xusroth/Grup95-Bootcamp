import 'package:flutter/material.dart';

class FeedbackThanksScreen extends StatelessWidget {
  const FeedbackThanksScreen({super.key});

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
              // Mascot image
              Image.asset(
                'assets/anasayfa_maskot.png',
                width: 300,
                height: 300,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),

              // Main thank you text
              const Text(
                'Geri Bildiriminiz\nİçin Teşekkürler!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Additional subtitle text
              const SizedBox(height: 8),
              const Text(
                'CodeBite ekibi olarak\ngörüşlerinizi önemsiyoruz.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 30),

              // OK button
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  width: 219,
                  height: 36,
                  decoration: BoxDecoration(
                    image: const DecorationImage(
                      image: AssetImage('assets/user_bar.png'),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'Tamam',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
