import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:android_studio/auth_service.dart';
import 'package:android_studio/constants.dart';

class ChangePasswordInAppScreen extends StatefulWidget {
  const ChangePasswordInAppScreen({super.key});

  @override
  State<ChangePasswordInAppScreen> createState() => _ChangePasswordInAppScreenState();
}

class _ChangePasswordInAppScreenState extends State<ChangePasswordInAppScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  String? errorMessage;
  bool isLoading = false;

  Future<void> changePassword() async {
    if (_newController.text != _confirmController.text) {
      setState(() {
        errorMessage = "Yeni şifreler birbiriyle uyuşmuyor.";
      });
      return;
    }

    setState(() {
      errorMessage = null;
      isLoading = true;
    });

    final auth = AuthService();
    final token = await auth.getString('token');

    final response = await http.post(
      Uri.parse('$baseURL/settings/change_password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'current_password': _currentController.text,
        'new_password': _newController.text,
      }),
    );

    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Şifre başarıyla değiştirildi")),
      );
      _currentController.clear();
      _newController.clear();
      _confirmController.clear();
    } else {
      setState(() {
        errorMessage = jsonDecode(response.body)['detail'] ?? "Hata oluştu.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              'assets/arkaplan.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Şifre Değiştir",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins-Regular',
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildTextField("Mevcut şifre", _currentController),
                      _buildTextField("Yeni şifre", _newController),
                      _buildTextField("Yeni şifre tekrar", _confirmController),
                      const SizedBox(height: 16),
                      if (errorMessage != null)
                        Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 116, 76, 163),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  "Değiştir",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Poppins-SemiBold',
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        obscureText: true,
        style: const TextStyle(color: Colors.white, fontFamily: 'Poppins-Regular'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54, fontFamily: 'Poppins-Regular'),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.white38),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
