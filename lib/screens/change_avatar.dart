import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:android_studio/constants.dart';
import 'package:android_studio/auth_service.dart';

class AvatarSelectionScreen extends StatefulWidget {
  const AvatarSelectionScreen({super.key});

  @override
  State<AvatarSelectionScreen> createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen> {
  final List<String> avatars = [
    'avatar_boom.png',
    'avatar_cat.png',
    'avatar_cleaner.png',
    'avatar_coder.png',
    'avatar_cool.png',
    'avatar_cowbot.png',
    'avatar_fairy.png',
    'avatar_frog.png',
    'avatar_alien.png',
    'avatar_astrout.png',
    'avatar_robot.png',
    'avatar_robot_2.png',
    'avatar_rock.png',
    'avatar_sleepy.png',
    'avatar_supergirl.png',
    'avatar_turtle.png',
    'avatar_vampire.png',
    'avatar_wizard.png',
  ];

  String? selectedAvatar;
  bool isLoading = false;

  Future<void> _submitAvatar() async {
  if (selectedAvatar == null) return;

  setState(() {
    isLoading = true;
  });

  final authService = AuthService();
  final token = await authService.getString('token');

  final response = await http.put(
    Uri.parse('$baseURL/avatar/update'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({'avatar': selectedAvatar}),
  );

  setState(() {
    isLoading = false;
  });

  if (!context.mounted) return;

  if (response.statusCode == 200) {
    //  Avatarı yerel belleğe de kaydet
    await authService.setString('user_avatar', selectedAvatar!);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Avatar başarıyla güncellendi")),
    );

    Navigator.pop(context, selectedAvatar); 
  } else if (response.statusCode == 403) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Misafir kullanıcılar avatar güncelleyemez")),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Hata: ${jsonDecode(response.body)['detail'] ?? 'Bilinmeyen hata'}"),
        backgroundColor: Colors.red,
      ),
    );
  }
}


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
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "Avatarını Seç",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: avatars.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemBuilder: (context, index) {
                    String avatar = avatars[index];
                    bool isSelected = avatar == selectedAvatar;
                    return GestureDetector(
                      onTap: () {
                        setState(() => selectedAvatar = avatar);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? Colors.blueAccent : Colors.transparent,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/avatars/$avatar',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Kaydet Butonu
              if (selectedAvatar != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBC52FC),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: isLoading ? null : _submitAvatar,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Kaydet",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
