import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_studio/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:android_studio/constants.dart';
import 'change_avatar.dart';

class ProfileUpdate extends StatefulWidget {
  const ProfileUpdate({super.key});

  @override
  State<ProfileUpdate> createState() => _ProfileUpdateState();
}

class _ProfileUpdateState extends State<ProfileUpdate> {
  int selectedTime = 5;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String avatarPath = 'profile_pic.png';
  bool notificationsOn = true;

  @override
  void initState() {
    super.initState();
    loadAvatar();
    loadUserInfo();
  }

  Future<void> loadAvatar() async {
    final authService = AuthService();
    final avatar = await authService.getString('user_avatar');
    setState(() {
      avatarPath = avatar ?? 'profile_pic.png';
    });
  }

  Future<void> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('user_name');
    final email = prefs.getString('user_mail');
    final dailyGoal = prefs.getInt('daily_goal');
    final notif = prefs.getBool('notifications_on');
    setState(() {
      _usernameController.text = username ?? '';
      _emailController.text = email ?? '';
      selectedTime = dailyGoal ?? 5;
      if (notif != null) notificationsOn = notif;
    });
  }

  Future<void> _selectAvatar() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AvatarSelectionScreen()),
    );

    if (result != null && result is String) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_avatar', result);
      setState(() {
        avatarPath = result;
      });
    }
  }

  Future<void> _saveProfile() async {
    final confirmed = await _showPasswordDialog();
    if (!confirmed) return;

    final authService = AuthService();
    final token = await authService.getString('token');
    final userId = await authService.getString('user_id');

    final response = await http.post(
      Uri.parse('$baseURL/settings/change_password'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'current_password': _passwordController.text,
        'new_password': _passwordController.text,
      }),
    );

    if (response.statusCode != 200) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Şifre yanlış',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red[600], // Kırmızı arkaplan
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
          elevation: 6,
        ),
      );
      return;
    }

    final updateResponse = await http.put(
      Uri.parse('$baseURL/auth/users/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "username": _usernameController.text,
        "email": _emailController.text,
        "level": "beginner",
        "notification_preferences": {
          "email": notificationsOn,
          "push": notificationsOn,
        },
        "theme": "light",
        "language": "tr",
        "avatar": avatarPath,
      }),
    );

    if (updateResponse.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', _usernameController.text);
      await prefs.setString('user_mail', _emailController.text);
      await prefs.setInt('daily_goal', selectedTime);
      await prefs.setBool('notifications_on', notificationsOn);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Profil başarıyla güncellendi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green[600],
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
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Profil güncelleme başarısız',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red[600],
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
  }

  Future<bool> _showPasswordDialog() async {
    _passwordController.clear();

    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: const Color.fromARGB(213, 45, 33, 59),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "Lütfen işlemi onaylamak için şifrenizi giriniz.",
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins-Regular',
                ),
                textAlign: TextAlign.center,
              ),
              content: TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: '',
                  hintStyle: TextStyle(color: Colors.white38),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white38),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
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
                      "Vazgeç",
                      () => Navigator.pop(context, false),
                      color: Colors.red,
                    ),
                    const SizedBox(width: 24),
                    _buildDialogFixedButton("Düzenle", () {
                      if (_passwordController.text.isNotEmpty) {
                        Navigator.pop(context, true);
                      }
                    }, color: Colors.green),
                  ],
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Widget _buildDialogFixedButton(
    String text,
    VoidCallback onPressed, {
    Color color = Colors.white,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Poppins-Regular',
          fontSize: 14,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset('assets/arkaplan.png', fit: BoxFit.cover),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Image.asset('assets/upper_bar.png'),
                      Positioned(
                        top: 60,
                        child: GestureDetector(
                          onTap: _selectAvatar,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color.fromARGB(255, 59, 59, 59),
                                width: 1,
                              ),
                              image: DecorationImage(
                                image: AssetImage(
                                  avatarPath.startsWith('avatar_')
                                      ? 'assets/avatars/$avatarPath'
                                      : 'assets/$avatarPath',
                                ),
                                fit: BoxFit.cover,
                                onError: (exception, stackTrace) {
                                  debugPrint('Asset image error: $exception');
                                  setState(() {
                                    avatarPath = 'profile_pic.png';
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _selectAvatar,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      backgroundColor: const Color(0xFFBF8BFA),
                    ),
                    child: const Text(
                      'Avatarı Değiştir',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins-Regular',
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Kullanıcı Bilgileri',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins-Regular',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField('Kullanıcı Adı', _usernameController),
                  _buildTextField('E-posta', _emailController),
                  const SizedBox(height: 20),
                  const Text(
                    'Bildirimleri Aç/Kapat',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins-Regular',
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Switch(
                    value: notificationsOn,
                    onChanged: (value) async {
                      setState(() {
                        notificationsOn = value;
                      });
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('notifications_on', value);
                    },
                    activeColor: Colors.green,
                    inactiveThumbColor: Colors.red,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Günlük Görev',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins-Regular',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [5, 10, 15].map((minute) {
                      final isSelected = selectedTime == minute;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ChoiceChip(
                          label: Text(
                            '$minute dk',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.black
                                  : Colors.blueGrey,
                              fontFamily: 'Poppins-Regular',
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              selectedTime = minute;
                            });
                          },
                          selectedColor: Colors.white,
                          backgroundColor: Colors.white24,
                          elevation: isSelected ? 3 : 0,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent.shade700,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 60,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Düzenle',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontFamily: 'Poppins-Regular',
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 6),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Poppins-Regular',
        ),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(
            color: Colors.white38,
            fontFamily: 'Poppins-Regular',
          ),
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}