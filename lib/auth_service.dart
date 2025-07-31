import 'dart:convert';
import 'package:android_studio/constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
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
    await setString('token', token);

    final response = await http.get(
      Uri.parse('$baseURL/auth/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final userData = json.decode(response.body);
      await setString('user_id', userData['id'].toString());
      await setString('user_name', userData['username']);
      await setString('user_mail', userData['email']);
      await fetchAndSaveUserAvatar(token); // Avatar da burada otomatik güncelleniyor
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

  Future<void> fetchAndSaveUserAvatar(String token) async {
    final response = await http.get(
      Uri.parse('$baseURL/avatar/current'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final avatar = data['avatar'];
      await setString('avatar', avatar);
    } else {
      print("Avatar bilgisi alınamadı: ${response.statusCode}");
    }
  }

  Future<bool> verifyPassword(String password) async {
    final token = await getString('token');
    if (token == null) return false;

    final response = await http.post(
      Uri.parse('$baseURL/auth/verify-password'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['valid'] == true;
    } else {
      print('Şifre doğrulama başarısız: ${response.body}');
      return false;
    }
  }

  Future<bool> updateUserProfile({
    required int userId,
    required String token,
    required String username,
    required String email,
    required String avatar,
    required bool notifications,
    required int dailyGoal,
  }) async {
    final body = {
      'username': username,
      'email': email,
      'level': 'beginner',
      'notification_preferences': {
        'email': notifications,
        'push': notifications,
      },
      'theme': 'light',
      'language': 'tr',
      'avatar': avatar,
    };

    final response = await http.put(
      Uri.parse('$baseURL/auth/users/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print('Profil güncelleme hatası: ${response.body}');
      return false;
    }
  }

  Future<bool> refreshTokenIfNeeded() async {
    final refreshToken = await getString('refresh_token');
    if (refreshToken == null) return false;

    final response = await http.post(
      Uri.parse('$baseURL/auth/refresh?refresh_token=$refreshToken'),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final newAccessToken = data['access_token'];
      final newRefreshToken = data['refresh_token'];

      await setString('token', newAccessToken);
      await setString('refresh_token', newRefreshToken);

      await setTokenAndUserData(newAccessToken);

      return true;
    } else {
      print('Refresh token başarısız: ${response.statusCode} ${response.body}');
      return false;
    }
  }
}
