import 'package:flutter/material.dart';
import 'package:android_studio/screens/FeedbackThanksScreen.dart';
import 'package:android_studio/auth_service.dart';
import 'package:android_studio/constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ReportScreen1 extends StatefulWidget {
  const ReportScreen1({super.key});

  @override
  State<ReportScreen1> createState() => _ReportScreen1State();
}

class _ReportScreen1State extends State<ReportScreen1> {
  String? selectedOption;
  final TextEditingController _feedbackController = TextEditingController();
  final List<String> options = [
    'Fonksiyonel Hata / Çalışmama Sorunu',
    'Görsel Hata / Arayüz Sorunu',
    'İçerik / Soru Hatalı',
    'Performans Sorunu',
  ];

  
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 24),
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
        backgroundColor: const Color.fromARGB(255, 255, 4, 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }

  
  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 24),
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
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }

  void _submitFeedback() async {
    final auth = AuthService();
    final token = await auth.getString('token');

    if ((selectedOption == null || selectedOption!.isEmpty) &&
        _feedbackController.text.isEmpty) {
      _showErrorSnackBar(
        context,
        'Lütfen geri bildirim türü seçin veya mesaj yazın',
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseURL/error/report'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'error_message': selectedOption ?? 'Serbest Geri Bildirim',
          'details': _feedbackController.text,
        }),
      );

      if (response.statusCode == 201) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FeedbackThanksScreen()),
        );
      } else {
        final detail =
            jsonDecode(response.body)['detail'] ?? 'Gönderim başarısız';
        if (!mounted) return;
        _showErrorSnackBar(context, detail);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(context, 'Hata oluştu: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/arkaplan.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              children: [
                SizedBox(height: 60),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Hangi konuda geri bildirimde bulunmak istersiniz?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 30),

                            // Dropdown
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage('assets/user_bar.png'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: DropdownButton<String>(
                                  value: selectedOption,
                                  hint: Text(
                                    'Bir seçenek seçin',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  dropdownColor: Color.fromARGB(
                                    255,
                                    105,
                                    81,
                                    137,
                                  ),
                                  icon: Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.white,
                                  ),
                                  iconSize: 24,
                                  elevation: 16,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                  ),
                                  underline: SizedBox.shrink(),
                                  isExpanded: true,
                                  items: options.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      selectedOption = newValue;
                                    });
                                  },
                                ),
                              ),
                            ),

                            SizedBox(height: 40),

                            // Text Input Section
                            Column(
                              children: [
                                Text(
                                  'Diğer öneri, istek ve geri bildirimler için',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 20),
                                Container(
                                  width: double.infinity,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: AssetImage(
                                        'assets/corner_gradient_rectangle.png',
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: TextField(
                                      controller: _feedbackController,
                                      maxLines: 6,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                      ),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: 'Mesajınızı buraya yazın...',
                                        hintStyle: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 40),

                            // Submit Button
                            Padding(
                              padding: const EdgeInsets.only(bottom: 40),
                              child: GestureDetector(
                                onTap: _submitFeedback,
                                child: Container(
                                  width: 219,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: AssetImage('assets/user_bar.png'),
                                      fit: BoxFit.cover,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Gönder',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
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
          ),

          // Back Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white, size: 28),
                onPressed: () {
                  Navigator.pop(context); 
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}