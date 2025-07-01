import 'package:flutter/material.dart';
import 'package:android_studio/screens/welcome_screen3.dart';

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

  bool notificationsOn = true;
  String? warningMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // arka plan için
          SizedBox.expand(
            child: Image.asset(
              'assets/arkaplan.png',
              fit: BoxFit.cover,
            ),
          ),

          // içerikler için
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Üst Bar ve Profil Fotoğrafı
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

                  // Fotoğrafı değiştir Butonu
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      backgroundColor: const Color(0xFFBF8BFA),
                    ),
                    child: const Text(
                      'Fotoğrafı Değiştir',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins-Regular',
                        fontSize: 16,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bildirimler
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

                  // Kullancıı bilgileri
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

                  const SizedBox(height: 24),

                  // Günlük Görev Süresi
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
                              color: isSelected ? Colors.black : Colors.blueGrey,
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

                  // Uyarı mesajı
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
                      ),
                    ),

                  // Oluştur Butonu
                  ElevatedButton(
                    onPressed: () {
                      if (_nameController.text.trim().isEmpty ||
                          _nicknameController.text.trim().isEmpty ||
                          _mailController.text.trim().isEmpty) {
                        setState(() {
                          warningMessage = "Boş bırakılmamalıdır";
                        });
                      } else {
                        setState(() {
                          warningMessage = null;
                        });
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WelcomeScreen3(
                              userName: _nameController.text.trim(),
                              userNickname: _nicknameController.text.trim(),
                              userMail: _mailController.text.trim(),
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
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

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 6),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontFamily: 'Poppins-Regular'),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: Colors.white38, fontFamily: 'Poppins-Regular'),
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
