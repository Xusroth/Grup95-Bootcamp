import 'dart:convert';
import 'package:android_studio/auth_service.dart';
import 'package:android_studio/constants.dart';
import 'package:android_studio/screens/change_password_inapp.dart';
import 'package:android_studio/screens/email_sent.dart';
import 'package:android_studio/screens/change_password.dart';
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

  final List<Map<String, dynamic>> settingsItems = [
    {"icon": "assets/user-circle-minus-fill.png", "text": "Hesabı Sil"},
    {"icon": "assets/globe-fill.png", "text": "Dil Tercihi"},
    {"icon": "assets/password.png", "text": "Şifreyi Değiştir"},
    {"icon": "assets/paper-plane-right.png", "text": "Öneri ve İstek"},
    {"icon": "assets/question.png", "text": "S.S.S\n(Sıkça Sorulan Sorular)"},
    {"icon": "assets/keyhole.png", "text": "Gizlilik"},
  ];

  @override
  void initState() {
    super.initState();
    fetchUserName();
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

  Future<void> deleteAccount() async {
    final token = await AuthService().getString('token');
    final response = await http.delete(
      Uri.parse('$baseURL/auth/users/me/delete'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const EmailSentScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hesap silinemedi: ${response.statusCode}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
                    const CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage("assets/profile_pic.png"),
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
                    )
                  ],
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: ListView.separated(
                    itemCount: settingsItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 24),
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          final itemText = settingsItems[index]["text"];

                          if (itemText == "Hesabı Sil") {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) {
                                String reason = "";
                                return StatefulBuilder(
                                  builder: (context, setState) {
                                    return Dialog(
                                      backgroundColor: Colors.deepPurple.shade900.withOpacity(0.95),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              "Hesabınızı neden silmek istiyorsunuz?",
                                              style: TextStyle(color: Colors.white, fontSize: 16),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 16),
                                            TextField(
                                              onChanged: (value) => setState(() => reason = value),
                                              style: const TextStyle(color: Colors.white),
                                              decoration: InputDecoration(
                                                hintText: "Sebep...",
                                                hintStyle: const TextStyle(color: Colors.white54),
                                                filled: true,
                                                fillColor: Colors.white.withOpacity(0.1),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                              children: [
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.grey.shade800,
                                                  ),
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text("Vazgeç"),
                                                ),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: reason.trim().isEmpty
                                                        ? Colors.grey
                                                        : Colors.redAccent,
                                                  ),
                                                  onPressed: reason.trim().isEmpty
                                                      ? null
                                                      : () {
                                                          Navigator.pop(context);
                                                          deleteAccount();
                                                        },
                                                  child: const Text("Onayla"),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          } else if (itemText == "Şifreyi Değiştir") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ChangePasswordInAppScreen()),
                            );
                          } else if (itemText == "S.S.S\n(Sıkça Sorulan Sorular)") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const FaqScreen()),
                            );
                          } else if (itemText == "Dil Tercihi") {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Sonraki güncellemelerle gelecek")),
                            );
                          } else if (itemText == "Öneri ve İstek") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ReportScreen1()),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFBC52FC), Color(0xFF857BFB)],
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
    );
  }
}
