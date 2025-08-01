import 'dart:convert';
import 'package:android_studio/auth_service.dart';
import 'package:android_studio/constants.dart';
import 'package:android_studio/screens/change_password_inapp.dart';
import 'package:android_studio/screens/email_sent.dart';
import 'package:android_studio/screens/sss.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:android_studio/screens/ReportScreen1.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String userName = "Yükleniyor...";
  String avatarPath = 'profile_pic.png';

  final List<Map<String, dynamic>> settingsItems = [
    {"icon": "assets/user-circle-minus-fill.png", "text": "Hesabı Sil"},
    {"icon": "assets/globe-fill.png", "text": "Dil Tercihi"},
    {"icon": "assets/password.png", "text": "Şifreyi Değiştir"},
    {"icon": "assets/paper-plane-right.png", "text": "Öneri ve İstek"},
    {"icon": "assets/question.png", "text": "S.S.S\n(Sıkça Sorulan Sorular)"},
  ];

  @override
  void initState() {
    super.initState();
    fetchUserName();
    loadAvatar();
  }

  Future<void> fetchUserName() async {
    final token = await AuthService().getString('token');
    final response = await http.get(
      Uri.parse('$baseURL/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      setState(() {
        userName = userData['username'] ?? "Kullanıcı";
      });
    }
  }

  Future<void> loadAvatar() async {
    final auth = AuthService();
    final avatar = await auth.getString('user_avatar');
    setState(() {
      avatarPath = avatar ?? 'profile_pic.png';
    });
  }

  Future<void> deleteAccount() async {
    final token = await AuthService().getString('token');
    final response = await http.delete(
      Uri.parse('$baseURL/auth/users/me/delete'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (!context.mounted) return;

    if (response.statusCode == 200) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const EmailSentScreen()),
        (route) => false,
      );
    } else {
      _showStyledSnackBar("Hesap silinemedi. Lütfen tekrar deneyin.", isError: true);
    }
  }

  void _showStyledSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/arkaplan.png"),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 27, 27, 27),
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: AssetImage("assets/avatars/$avatarPath"),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Expanded(
                      child: ListView.separated(
                        itemCount: settingsItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 32),
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              final itemText = settingsItems[index]["text"];

                              if (itemText == "Hesabı Sil") {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      backgroundColor: const Color.fromARGB(213, 45, 33, 59),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      title: const Text(
                                        "Hesabınızı silmek istediğinize emin misiniz?",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Poppins-Regular',
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      actionsPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      actions: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            _buildDialogFixedButton(
                                              "Hayır",
                                              () => Navigator.pop(context),
                                              color: Colors.green,
                                            ),
                                            const SizedBox(width: 24),
                                            _buildDialogFixedButton(
                                              "Evet",
                                              () {
                                                Navigator.pop(context);
                                                deleteAccount();
                                              },
                                              color: Colors.redAccent,
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                );
                              } else if (itemText == "Dil Tercihi") {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    backgroundColor: const Color.fromARGB(213, 45, 33, 59),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    title: const Text(
                                      "Dil seçenekleri",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Poppins-SemiBold',
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    content: const Text(
                                      "Sonraki güncellemelerle gelecek",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontFamily: 'Poppins-Regular',
                                      ),
                                    ),
                                    actionsPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    actions: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          _buildDialogFixedButton(
                                            "Tamam",
                                            () => Navigator.pop(context),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              } else if (itemText == "Şifreyi Değiştir") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ChangePasswordInAppScreen(),
                                  ),
                                );
                              } else if (itemText == "S.S.S\n(Sıkça Sorulan Sorular)") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const FaqScreen(),
                                  ),
                                );
                              } else if (itemText == "Öneri ve İstek") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReportScreen1(),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFBC52FC),
                                    Color(0xFF857BFB),
                                  ],
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.asset(
                                    settingsItems[index]["icon"],
                                    width: 22,
                                    height: 22,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      settingsItems[index]["text"],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Image.asset('assets/sari_cloud.png', fit: BoxFit.fitWidth),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogFixedButton(String text, VoidCallback onPressed,
      {Color color = const Color(0xFF8E24AA)}) {
    return SizedBox(
      width: 120,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}