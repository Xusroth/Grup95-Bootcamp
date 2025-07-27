import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_studio/auth_service.dart';
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
  String avatarPath = 'profile_pic.png';

  @override
  void initState() {
    super.initState();
    loadAvatar();
    loadUserInfo();
  }

  Future<void> loadAvatar() async {
    try {
      final authService = AuthService();
      final avatar = await authService.getString('user_avatar');
      setState(() {
        avatarPath = avatar ?? 'profile_pic.png';
        debugPrint('Avatar loaded: $avatarPath');
      });
    } catch (e) {
      debugPrint('Avatar loading error: $e');
      setState(() {
        avatarPath = 'profile_pic.png';
      });
    }
  }

  Future<void> loadUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('user_name');
      final nickname = prefs.getString('user_nickname');
      final dailyGoal = prefs.getInt('daily_goal');
      setState(() {
        _nameController.text = name ?? '';
        _nicknameController.text = nickname ?? '';
        selectedTime = dailyGoal ?? 5;
      });
    } catch (e) {
      debugPrint('Error loading user info: $e');
    }
  }

  Future<void> _selectAvatar() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AvatarSelectionScreen()),
    );

    if (result != null && result is String) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_avatar', result);
        setState(() {
          avatarPath = result;
          debugPrint('Avatar selected and saved: $avatarPath');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar başarıyla güncellendi.')),
        );
      } catch (e) {
        debugPrint('Error saving avatar: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Avatar kaydedilemedi.')));
      }
    }
  }

  Future<void> _saveProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', _nameController.text);
      await prefs.setString('user_nickname', _nicknameController.text);
      await prefs.setInt('daily_goal', selectedTime);
      debugPrint(
        'Profile saved: Ad: ${_nameController.text}, Kullanıcı Adı: ${_nicknameController.text}, Süre: $selectedTime dk',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil başarıyla güncellendi.')),
      );
    } catch (e) {
      debugPrint('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil güncelleme başarısız.')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
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
