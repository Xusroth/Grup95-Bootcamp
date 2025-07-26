import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:android_studio/constants.dart';
import 'package:android_studio/screens/welcome_screen1.dart';

class PasswordResetScreen extends StatefulWidget {
  final String token;

  const PasswordResetScreen({super.key, required this.token});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool isLoading = false;
  String? errorText;

  Future<void> resetPassword() async {
    if (_passwordController.text != _confirmController.text) {
      setState(() => errorText = "Şifreler uyuşmuyor.");
      return;
    }

    setState(() {
      errorText = null;
      isLoading = true;
    });

    final response = await http.post(
      Uri.parse('$baseURL/auth/password_reset'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': widget.token,
        'new_password': _passwordController.text,
      }),
    );

    if (response.statusCode == 200) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen1()),
      );
    } else {
      setState(() {
        errorText = 'Şifre sıfırlama başarısız. Lütfen geçerli bir bağlantı kullanın.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/arkaplan.png', fit: BoxFit.cover),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white54),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Yeni Şifrenizi Girin",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins-Regular',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(_passwordController, "Yeni Şifre"),
                  const SizedBox(height: 12),
                  _buildPasswordField(_confirmController, "Yeni Şifre (Tekrar)"),
                  const SizedBox(height: 12),
                  if (errorText != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        errorText!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                            )
                          : const Text(
                              "Şifreyi Sıfırla",
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      obscureText: true,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white60),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white54),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
