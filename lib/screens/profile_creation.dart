import 'package:flutter/material.dart';
import 'package:android_studio/screens/welcome_screen3.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:android_studio/constants.dart';
import 'package:android_studio/auth_service.dart';
import 'package:android_studio/screens/change_avatar.dart';

class ProfileCreation extends StatefulWidget {
  const ProfileCreation({super.key});

  @override
  State<ProfileCreation> createState() => _ProfileCreationState();
}

class _ProfileCreationState extends State<ProfileCreation> {
  int selectedTime = 5;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _mailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool notificationsOn = true;
  bool isLoading = false;
  String? warningMessage;
  String? passwordError;

  bool _validatePassword(String password) {
    if (password.length < 8) {
      setState(() {
        passwordError = 'Şifre en az 8 karakter olmalıdır';
      });
      return false;
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      setState(() {
        passwordError = 'Şifre en az 1 büyük harf içermelidir';
      });
      return false;
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      setState(() {
        passwordError = 'Şifre en az 1 küçük harf içermelidir';
      });
      return false;
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      setState(() {
        passwordError = 'Şifre en az 1 sayı içermelidir';
      });
      return false;
    }

    setState(() {
      passwordError = null;
    });
    return true;
  }

  Future<bool> registerAndLoginUser() async {
    if (!_validatePassword(_passwordController.text.trim())) {
      return false;
    }

    try {
      setState(() => isLoading = true);

     
      final registerResponse = await http.post(
        Uri.parse('$baseURL/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': _nicknameController.text.trim(),
          'email': _mailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      if (registerResponse.statusCode != 201) {
        final errorData = json.decode(registerResponse.body);
        setState(() {
          warningMessage = errorData['detail'] ?? 'Kayıt başarısız';
        });
        return false;
      }

      print("✅ Kayıt başarılı");

     
      final loginResult = await _authService.login(
        _mailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (loginResult != null) {
        print("🔐 Login başarılı, tokenlar kaydedildi");
        return true;
      } else {
        setState(() {
          warningMessage = 'Giriş başarısız. Lütfen tekrar deneyin.';
        });
        return false;
      }
    } catch (e) {
      print('Register error: $e');
      setState(() {
        warningMessage = 'Kayıt sırasında bir hata oluştu.';
      });
      return false;
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _mailController.dispose();
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
                        child: Image.asset(
                          'assets/profile_pic.png',
                          height: 110,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: const Color.fromARGB(213, 45, 33, 59),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: const Text(
                            "Avatar değişikliği",
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins-SemiBold',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          content: const Text(
                            "Avatarınızı profil oluşturduktan sonra Profili Düzenle sayfasından değiştirebilirsiniz.",
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
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFBF8BFA),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 10,
                                    ),
                                  ),
                                  child: const Text(
                                    "Tamam",
                                    style: TextStyle(
                                      fontFamily: 'Poppins-SemiBold',
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
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
                  const SizedBox(height: 16),
                  const Text(
                    'Bildirimler',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins-Regular',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Switch(
                        value: notificationsOn,
                        onChanged: (val) {
                          setState(() {
                            notificationsOn = val;
                          });
                        },
                        activeColor: Colors.green,
                      ),
                      Text(
                        notificationsOn ? 'on' : 'off',
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins-Regular',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Kullanıcı Bilgileri',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins-Regular',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField('Ad Soyad', _nameController),
                  _buildTextField('Kullanıcı Adı', _nicknameController),
                  _buildTextField('E-Posta', _mailController),
                  _buildTextField(
                    'Şifre',
                    _passwordController,
                    isPassword: true,
                  ),
                  if (passwordError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        passwordError!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontFamily: 'Poppins-Regular',
                        ),
                      ),
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
                  if (warningMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        warningMessage!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 14,
                          fontFamily: 'Poppins-Regular',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ElevatedButton(
                    onPressed: isLoading ? null : () async {
                      if (_nameController.text.trim().isEmpty ||
                          _nicknameController.text.trim().isEmpty ||
                          _mailController.text.trim().isEmpty ||
                          _passwordController.text.trim().isEmpty) {
                        setState(() {
                          warningMessage = "Tüm alanlar doldurulmalıdır.";
                        });
                        return;
                      }

                      setState(() {
                        warningMessage = null;
                      });

                      final success = await registerAndLoginUser();
                      if (success && mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WelcomeScreen3(
                              userName: _nameController.text.trim(),
                              userNickname: _nicknameController.text.trim(),
                              userMail: _mailController.text.trim(),
                              userPassword: _passwordController.text.trim(),
                            ),
                          ),
                        );
                      }
                    },
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
                    child: isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        : const Text(
                            'Oluştur',
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

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 6),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
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