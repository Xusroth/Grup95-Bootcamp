import 'package:flutter/material.dart';
import 'package:android_studio/screens/welcome_screen2.dart';

void main() {
  runApp(const CodebiteApp());
}

class CodebiteApp extends StatelessWidget {
  const CodebiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Codebite',
      debugShowCheckedModeBanner: false,
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D213B), // koyu mor arka plan #2D213B
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Maskot Eleman Resmi
              Image.asset(
                'assets/anasayfa_maskot.png',
                height: 200,
              ),
              const SizedBox(height: 36),

              // Hoş geldin yazısı
              const Text(
                "codebite’a hoşgeldin",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),

              // Profil oluştur butonu
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("PROFİL OLUŞTUR",
                  style: TextStyle(color: Colors.black ,fontSize: 20),),
              ),
              const SizedBox(height: 24),

              // Google ile giriş butonu
              TextButton.icon(
                onPressed: () {},
                icon: Image.asset('assets/google_icon.png', height: 32),
                label: const Text(
                  "Google ile giriş yap",
                  style: TextStyle(color: Colors.white ,fontSize: 20),
                ),
              ),
              const SizedBox(height: 8),

              // Misafir giriş butonu
              TextButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const WelcomeScreen2()),
                  );
                },
                icon: Image.asset('assets/misafir_icon.png', height: 32),
                label: const Text(
                  "Misafir olarak giriş yap",
                  style: TextStyle(color: Colors.white ,fontSize: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}