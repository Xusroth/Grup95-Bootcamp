import 'package:android_studio/screens/sss.dart';
import 'package:flutter/material.dart';
import 'package:android_studio/screens/email_sent.dart';
import 'package:android_studio/screens/change_email.dart';
import 'package:android_studio/screens/change_password.dart';
import 'package:android_studio/screens/sss.dart';


class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> settingsItems = [
      {"icon": "assets/sign-out-fill.png", "text": "Oturumu Kapat"},
      {"icon": "assets/user-circle-minus-fill.png", "text": "Hesabı Sil"},
      {"icon": "assets/globe-fill.png", "text": "Dil Tercihi"},
      {"icon": "assets/password.png", "text": "Şifreyi Değiştir"},
      {"icon": "assets/envelope.png", "text": "E-Posta Değiştir"},
      {"icon": "assets/paper-plane-right.png", "text": "Öneri ve İstek"},
      {"icon": "assets/question.png", "text": "S.S.S\n(Sıkça Sorulan Sorular)"},
      {"icon": "assets/keyhole.png", "text": "Gizlilik"},
    ];

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
                    const Text(
                      "User",
                      style: TextStyle(
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
                              builder: (BuildContext context) {
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
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
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
                                                    Navigator.pushAndRemoveUntil(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) => const EmailSentScreen(),
                                                      ),
                                                          (route) => false,
                                                    );
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
                          } else if (itemText == "E-Posta Değiştir") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const EmailChangeScreen()),
                            );
                          } else if (itemText == "Şifreyi Değiştir") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PasswordChangeScreen()),
                            );
                          } else if (itemText == "S.S.S\n(Sıkça Sorulan Sorular)") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const FaqScreen()),
                            );

                          } else if (itemText == "Dil Tercihi") {
                            String selectedLang = "Türkçe";
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) {
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
                                              "Dil seçimi yapınız",
                                              style: TextStyle(color: Colors.white, fontSize: 16),
                                            ),
                                            const SizedBox(height: 16),
                                            DropdownButton<String>(
                                              value: selectedLang,
                                              dropdownColor: Colors.deepPurple.shade800,
                                              style: const TextStyle(color: Colors.white),
                                              items: ["Türkçe", "İngilizce"].map((lang) {
                                                return DropdownMenuItem(
                                                  value: lang,
                                                  child: Text(lang),
                                                );
                                              }).toList(),
                                              onChanged: (val) => setState(() => selectedLang = val!),
                                            ),
                                            const SizedBox(height: 24),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.deepPurple.shade700,
                                              ),
                                              child: const Text("Tamam"),
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
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
