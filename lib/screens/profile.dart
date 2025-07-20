import 'package:android_studio/screens/welcome_screen2.dart';
import 'package:flutter/material.dart';
import 'package:android_studio/screens/home_screen.dart';
import 'package:android_studio/screens/dersec_screen.dart';
import 'package:android_studio/auth_service.dart';

class ProfilePage extends StatelessWidget {
  final String userName;

  const ProfilePage({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/arkaplan.png"),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset("assets/upper_bar.png", width: double.infinity, fit: BoxFit.cover),
                      const Positioned(
                        top: 60,
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage: AssetImage("assets/profile_pic.png"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(userName, style: const TextStyle(color: Colors.white, fontSize: 18)),
                  const Text("Turkey", style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 20),

                  _buildGradientButton("Profili Düzenle", () {}),
                  const SizedBox(height: 15),
                  _buildGradientButton("Devam Eden Eğitimler", () {}),
                  const SizedBox(height: 15),
                  _buildGradientButton("Ayarlar", () {}),
                  const SizedBox(height: 15),

                  GestureDetector(
                    onTap: () async {
                      AuthService authService = AuthService();
                      authService.clearString('token');
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => WelcomeScreen2()),
                      );
                    },
                    child: Container(
                      height: 46,
                      width: 272,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.transparent,
                        border: Border.all(color: Colors.redAccent, width: 1.5),
                      ),
                      child: const Center(
                        child: Text(
                          "Çıkış Yap",
                          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 30),
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: AssetImage("assets/hedef_kart.png"),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Görev Tamamlama",
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "1/3 tamamlandı",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Container(
                            height: 5,
                            width: 300,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: 0.33,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(3),
                                ),
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
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 350,
                  child: Image.asset(
                    "assets/alt_bar.png",
                    fit: BoxFit.fill,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60.0, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HomeScreen(
                                userMail: '',
                                userName: userName,
                              ),
                            ),
                          );
                        },
                        child: Image.asset("assets/home.png", height: 28),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DersSec(
                                userMail: '',
                                userName: userName,
                              ),
                            ),
                          );
                        },
                        child: Image.asset("assets/ders.png", height: 28),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProfilePage(
                                userName: userName,
                              ),
                            ),
                          );
                        },
                        child: Image.asset("assets/profile.png", height: 28),
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

  Widget _buildGradientButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        width: 272,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFFBC52FC), Color(0xFF857BFB)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
