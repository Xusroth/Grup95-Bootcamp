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

  bool isLoading = false;

  void showStyledSnackBar(String message, {bool isError = false}) {
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

  Future<void> changePassword() async {
    final current = _currentController.text.trim();
    final newPass = _newController.text.trim();
    final confirmPass = _confirmController.text.trim();

    if (current.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      showStyledSnackBar("Tüm alanları doldurmalısınız", isError: true);
      return;
    }

    if (newPass != confirmPass) {
      showStyledSnackBar("Yeni şifreler birbiriyle uyuşmuyor", isError: true);
      return;
    }

    setState(() => isLoading = true);

    final auth = AuthService();
    final token = await auth.getString('token');

    final response = await http.post(
      Uri.parse('$baseURL/settings/change_password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'current_password': current,
        'new_password': newPass,
      }),
    );

    setState(() => isLoading = false);

    if (!context.mounted) return;

    if (response.statusCode == 200) {
      showStyledSnackBar("Şifre başarıyla değiştirildi");
      _currentController.clear();
      _newController.clear();
      _confirmController.clear();
    } else {
      final detail = jsonDecode(response.body)['detail'] ?? "Hata oluştu.";
      showStyledSnackBar("Hata: $detail", isError: true);
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