import 'package:flutter/material.dart';
import 'change_avatar.dart';

class ProfileUpdate extends StatefulWidget {
  const ProfileUpdate({super.key});

  @override
  State<ProfileUpdate> createState() => _ProfileUpdateState();
}

class _ProfileUpdateState extends State<ProfileUpdate> {
  int selectedTime = 5;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  String selectedAvatar = "assets/profile_pic.png";

  void _selectAvatar() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AvatarSelectionScreen()),
    );

    if (result != null && result is String) {
      setState(() => selectedAvatar = result);
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
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Image.asset('assets/upper_bar.png'),
                      Positioned(
                        top: 60,
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white, 
                          backgroundImage: AssetImage(selectedAvatar),
                        )
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _selectAvatar,
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
                  _buildTextField('Ad Soyad', _nameController),
                  _buildTextField('Kullanıcı Adı', _nicknameController),
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
                  ElevatedButton(
                    onPressed: () {
                      // Güncelleme işlemi yapılacak alan
                      print("Ad: \${_nameController.text}, Kullanıcı Adı: \${_nicknameController.text}, Süre: \${selectedTime} dk");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 14),
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
