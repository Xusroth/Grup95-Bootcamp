import 'package:flutter/material.dart';
import 'change_avatar.dart'; // Avatar seçim ekranı



class UpdateProfilePage extends StatefulWidget {
  const UpdateProfilePage({super.key});

  @override
  State<UpdateProfilePage> createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  bool notificationsEnabled = true;
  String selectedLanguage = "Python";
  int selectedTask = 15;
  double difficulty = 0.5;

  // Başlangıç avatarı (varsayılan)
  String selectedAvatar = "avatars/avatar_cool.png";

  final List<String> languages = [
    "Python",
    "Algoritmalar",
    "C#",
    "Java",
  ];

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
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/arkaplan.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset("assets/upper_bar.png"),
                    Positioned(
                      top: 60,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: AssetImage("assets/$selectedAvatar"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Avatarı Değiştir Butonu
                GestureDetector(
                  onTap: _selectAvatar,
                  child: Container(
                    width: 200,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFBC52FC), Color(0xFF857BFB)],
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        "Avatarı Değiştir",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Bildirimler
                const Text("Bildirimler", style: TextStyle(color: Colors.white)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text("on", style: TextStyle(color: Colors.white)),
                      selected: notificationsEnabled,
                      onSelected: (_) {
                        setState(() => notificationsEnabled = true);
                      },
                      selectedColor: Colors.green,
                      backgroundColor: Colors.grey[800],
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text("off", style: TextStyle(color: Colors.white)),
                      selected: !notificationsEnabled,
                      onSelected: (_) {
                        setState(() => notificationsEnabled = false);
                      },
                      selectedColor: Colors.redAccent,
                      backgroundColor: Colors.grey[800],
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                const Text("Bilgileri Düzenle", style: TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(height: 16),

                buildInputField("Ad Soyad"),
                const SizedBox(height: 12),
                buildInputField("Kullanıcı Adı"),
                const SizedBox(height: 12),
                buildInputField("E-Posta"),

                const SizedBox(height: 32),
                const Text("Hedef Dil", style: TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 10),
                buildDropdown(),

                const SizedBox(height: 24),
                const Text("Günlük Görev", style: TextStyle(color: Colors.white)),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [5, 10, 15].map((val) {
                    return GestureDetector(
                      onTap: () => setState(() => selectedTask = val),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: selectedTask == val ? Colors.deepPurple : const Color(0xFF2A2544),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "$val dk",
                          style: TextStyle(color: selectedTask == val ? Colors.white : Colors.grey),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 32),
                const Text("Zorluk Seviyesi", style: TextStyle(color: Colors.white)),
                const SizedBox(height: 8),

                Slider(
                  value: difficulty,
                  min: 0,
                  max: 1,
                  divisions: 2,
                  label: difficultyLabel(difficulty),
                  onChanged: (val) {
                    setState(() => difficulty = val);
                  },
                  activeColor: Colors.greenAccent,
                  inactiveColor: Colors.white.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInputField(String hint) {
    return TextFormField(
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFF6C4AB6), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    );
  }

  Widget buildDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF6C4AB6), width: 1.5),
        color: Colors.white.withOpacity(0.05),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedLanguage,
          dropdownColor: const Color(0xFF2A2544),
          iconEnabledColor: Colors.white,
          style: const TextStyle(color: Colors.white),
          items: languages.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => selectedLanguage = value!);
          },
        ),
      ),
    );
  }

  String difficultyLabel(double val) {
    if (val == 0.0) return "Kolay";
    if (val == 0.5) return "Orta";
    return "Zor";
  }
}
