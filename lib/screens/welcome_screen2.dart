import 'dart:convert';
import 'dart:math';
import 'package:android_studio/auth_service.dart';
import 'package:android_studio/constants.dart';
import 'package:flutter/material.dart';
import 'package:android_studio/screens/welcome_screen3.dart';
import 'package:android_studio/screens/profile_creation.dart';
import 'package:android_studio/screens/login_screen.dart';
import 'package:android_studio/screens/ReportScreen1.dart';
import 'package:http/http.dart' as http;

class WelcomeScreen2 extends StatelessWidget {
  const WelcomeScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/arkaplan.png', fit: BoxFit.cover),
          Column(
            children: [
              // Üstteki butonlar
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Geri Butonu
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),

                      // Report ikonu - IconButton ile
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReportScreen1(),
                            ),
                          );
                        },
                        icon: Image.asset(
                          'assets/report.png',
                          width: 36,
                          height: 36,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
                  Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/anasayfa_maskot.png',
                        height: 200,
                      ),
                      const SizedBox(height: 36),
                      const Text(
                        "Hazırsan Başlayalım",
                        style: TextStyle(
                          fontFamily: 'Poppins-Bold',
                          fontSize: 22,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 36),
                      const Text(
                        "Birkaç basit adımda hesabını oluşturalım",
                        style: TextStyle(
                          fontFamily: 'Poppins-Regular',
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 36),

                      // Profil oluştur butonu
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ProfileCreation()),
                          );
                        },
                        child: Container(
                          width: 300,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              )
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              "Profil Oluştur",
                              style: TextStyle(
                                fontFamily: 'Poppins-Regular',
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // google ile giriş
                      GestureDetector(
                        onTap: () {
                          // Google ile giriş işlemleri burada olacak
                        },
                        child: Container(
                          width: 300,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7F95F1), Color(0xFFD1CFE3)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              )
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset('assets/google_icon.png', height: 24),
                              const SizedBox(width: 12),
                              const Text(
                                "Google ile giriş yap",
                                style: TextStyle(
                                  fontFamily: 'Poppins-Regular',
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // misafir girişi için değerlerin belirlenmesi
                      GestureDetector(
                      onTap: () async {
                        final response = await http.post(
                          Uri.parse('$baseURL/auth/guest'),
                          headers: {'Content-Type': 'application/json'},
                        );

                        if (response.statusCode == 200) {
                          final data = json.decode(response.body);
                          final token = data['access_token'];

                          
                          final authService = AuthService();
                          await authService.setString('token', token);

                          
                          final userResponse = await http.get(
                            Uri.parse('$baseURL/auth/me'),
                            headers: {
                              'Authorization': 'Bearer $token',
                              'Content-Type': 'application/json',
                            },
                          );

                          if (userResponse.statusCode == 200) {
                            final userData = json.decode(userResponse.body);
                            final username = userData['username'];

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WelcomeScreen3(
                                  userName: username,
                                  userNickname: username,
                                  userMail: '',
                                  userPassword: '',
                                ),
                              ),
                            );
                          } else {
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Kullanıcı bilgisi alınamadı")),
                            );
                          }
                        } else {
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Misafir girişi başarısız oldu")),
                          );
                        }
                      },
                        child: Container(
                          width: 300,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE3E9FF), Color(0xFF7F95F1)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              )
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset('assets/misafir_icon.png', height: 24),
                              const SizedBox(width: 12),
                              const Text(
                                "Misafir Girişi",
                                style: TextStyle(
                                  fontFamily: 'Poppins-Regular',
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),


                      // Zaten hesabım var 
                      GestureDetector(
                        onTap: () {
                        Navigator.push(context, 
                        MaterialPageRoute(builder: (_) => LoginScreen()));
                        },
                        child: const Text(
                          "Zaten hesabım var",
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Poppins-Regular',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
