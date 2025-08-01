import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:android_studio/constants.dart';
import 'package:android_studio/auth_service.dart';

class StreakPage1 extends StatefulWidget {
  const StreakPage1({super.key});

  @override
  State<StreakPage1> createState() => _StreakPage1State();
}

class _StreakPage1State extends State<StreakPage1> {
  int streakCount = 0;  
  List<dynamic> streakList = [];

  @override
  void initState() {
    super.initState();
    fetchStreakCount();
  }

  Future<void> fetchStreakCount() async {
    try {
      final authService = AuthService();
      final token = await authService.getString('token');

      if (token == null) return;

      final response = await http.get(
        Uri.parse('$baseURL/auth/streaks'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
      final List<dynamic> fetchedStreaks = json.decode(response.body);

      if (fetchedStreaks.isNotEmpty) {
        
        streakList = fetchedStreaks;

        
        fetchedStreaks.sort((a, b) => b['streak_count'].compareTo(a['streak_count']));
        streakCount = fetchedStreaks[0]['streak_count'];
      } else {
        streakCount = 0;
      }
    }
      
      else {
        debugPrint('Streak fetch failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Streak fetch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/arkaplan.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                
                  Text(
                    'STREAK SAYIN: $streakCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Poppins-SemiBold',
                      fontSize: 24,
                      color: Colors.redAccent,
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black,
                          offset: Offset(1, 1),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

        
                  Image.asset(
                    'assets/level1.png',
                    width: 180,
                    height: 180,
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    "STREAK BAŞLADI 🔥\nŞimdi her gün görevini yap!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins-SemiBold',
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
