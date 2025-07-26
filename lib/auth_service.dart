import 'dart:convert';
import 'package:android_studio/constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class  AuthService {
  
  Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

   Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  void clearString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(key); 
  }

  Future<void> setTokenAndUserData(String token) async {
  final authService = AuthService();
  await authService.setString('token', token);

  final response = await http.get(
    Uri.parse('$baseURL/auth/me'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final userData = json.decode(response.body);
    await authService.setString('user_id', userData['id'].toString());
    await authService.setString('user_name', userData['username']);
    await authService.setString('user_mail', userData['email']);
  } else {
    print("auth/me çağrısı başarısız: ${response.statusCode}");
  }
}


  Future<int?> getUserIdFromToken() async {
    final token = await getString('token');
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseURL/auth/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final userData = json.decode(response.body);
      return userData['id'];
    } else {
      print("auth/me hatası: ${response.body}");
      return null;
    }
  }

}
