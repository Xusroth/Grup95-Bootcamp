import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:android_studio/screens/welcome_screen2.dart';
import 'package:android_studio/screens/home_screen.dart';
import 'package:android_studio/screens/dersec_screen.dart';
import 'package:android_studio/auth_service.dart';
import 'package:android_studio/constants.dart';
import 'package:android_studio/screens/update_profile.dart';
import 'package:android_studio/screens/setting_screen.dart';

class ProfilePage extends StatefulWidget {
  final String userName;

  const ProfilePage({super.key, required this.userName});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int completedCount = 0;
  int totalCount = 0;
  String avatarPath = 'profile_pic.png';

  @override
  void initState() {
    super.initState();
    fetchDailyTasks();
    loadAvatar();
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

  Future<void> fetchDailyTasks() async {
    try {
      final authService = AuthService();
      final token = await authService.getString('token');
      if (token == null) {
        debugPrint('Token not found');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Giriş yapılmamış.')));
        return;
      }

      final response = await http.get(
        Uri.parse('$baseURL/tasks/daily'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final tasks = jsonDecode(response.body);
        final completed = tasks
            .where((task) => task['is_completed'] == true)
            .length;

        setState(() {
          totalCount = tasks.length;
          completedCount = completed;
          debugPrint('Tasks loaded: $completedCount/$totalCount');
        });
      } else {
        debugPrint('Failed to load tasks: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Görevler alınamadı: ${response.statusCode}')),
        );
      }
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Görevler alınırken bir hata oluştu.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/arkaplan.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/upper_bar.png',
                        width: double.infinity,
                        fit: BoxFit.fill,
                      ),
                      Positioned(
                        top: 60,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfileUpdate(),
                              ),
                            );
                          },
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
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
                              border: Border.all(
                                color: const Color.fromARGB(255, 59, 59, 59),
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.userName,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const Text(
                    'Turkey',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  _buildGradientButton('Profili Düzenle', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProfileUpdate()),
                    );
                  }),
                  const SizedBox(height: 15),
                  _buildGradientButton('Devam Eden Eğitimler', () {}),
                  const SizedBox(height: 15),
                  _buildGradientButton('Ayarlar', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SettingsPage()),
                    );
                  }),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: () {
                      final authService = AuthService();
                      authService.clearString(
                        'token',
                      ); 
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => WelcomeScreen2()),
                      );
                    },
                    child: Container(
                      height: 46,
                      width: 272,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.transparent,
                        border: Border.all(color: Colors.redAccent, width: 1.5),
                      ),
                      child: const Center(
                        child: Text(
                          'Çıkış Yap',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 30,
                    ),
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: AssetImage('assets/hedef_kart.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Günlük Görevler',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$completedCount/$totalCount tamamlandı',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Container(
                            height: 5,
                            width: 300,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: totalCount > 0
                                  ? completedCount / totalCount
                                  : 0.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(width: 350, child: Image.asset("assets/alt_bar.png", fit: BoxFit.fill)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 60.0, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => HomeScreen(userMail: '', userName: widget.userName),
                                ),
                              );
                            },
                            child: Image.asset("assets/home.png", height: 28),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DersSec(userMail: '', userName: widget.userName),
                                ),
                              );
                            },
                            child: Image.asset("assets/ders.png", height: 28),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProfilePage(userName: widget.userName),
                                ),
                              );
                            },
                            child: Image.asset("assets/profile.png", height: 28),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildGradientButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        width: 272,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFFBC52FC), Color(0xFF857BFB)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
