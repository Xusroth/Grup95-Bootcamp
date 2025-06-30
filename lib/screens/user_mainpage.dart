import 'package:flutter/material.dart';

class UserMainpage extends StatelessWidget {
  final String selectedCourse; // seçilen kursun şeysi

  const UserMainpage({super.key, required this.selectedCourse});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D213B),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Merhaba User kısmı parametleri
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Merhaba User',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white54,
                  child: Icon(Icons.person, size: 30, color: Colors.purple),
                ),
              ],
            ),

            const SizedBox(height: 48),

            // Devam et butonu
            Center(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Devam Et',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Seçilen ders butonu
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: const Icon(Icons.build, size: 32),
                title: Text(
                  selectedCourse,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Günlük görev butonu
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const ListTile(
                leading: Icon(Icons.alarm, size: 32, color: Colors.orange),
                title: Text(
                  'Günlük görev',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}