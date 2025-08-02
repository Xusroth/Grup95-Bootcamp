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

 
  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      
      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))
      );
      
      final exp = payload['exp'];
      if (exp == null) return true;
      
      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expiry);
    } catch (e) {
      return true;
    }
  }


  Future<String?> _getValidToken() async {
    final token = await getString('token');
    if (token == null) return null;
    
 
    if (!_isTokenExpired(token)) {
      return token;
    }
    
  
    final refreshSuccess = await refreshTokenIfNeeded();
    if (refreshSuccess) {
      return await getString('token');
    }
    
    return null;
  }

 
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseURL/auth/login'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'username': email, 
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final accessToken = data['access_token'];
        final refreshToken = data['refresh_token'];
        
       
        await setString('token', accessToken);
        await setString('refresh_token', refreshToken);
        
       
        await setTokenAndUserData(accessToken);
        
        return data;
      } else {
        print('Login başarısız: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Login hatası: $e');
      return null;
    }
  }

 
  Future<void> logout() async {
    clearString('token');
    clearString('refresh_token');
    clearString('user_id');
    clearString('user_name');
    clearString('user_mail');
    clearString('avatar');
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
      await fetchAndSaveUserAvatar(token); 
    } else {
      print("auth/me çağrısı başarısız: ${response.statusCode}");
    }
  }

  Future<int?> getUserIdFromToken() async {
    final token = await _getValidToken(); 
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
    } else if (response.statusCode == 401) {
     
      final refreshSuccess = await refreshTokenIfNeeded();
      if (refreshSuccess) {
        return await getUserIdFromToken(); 
      }
      print("auth/me hatası: ${response.body}");
      return null;
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
    } else if (response.statusCode == 401) {
      
      final refreshSuccess = await refreshTokenIfNeeded();
      if (refreshSuccess) {
        final newToken = await getString('token');
        if (newToken != null) {
          await fetchAndSaveUserAvatar(newToken);
        }
      }
    } else {
      print("Avatar bilgisi alınamadı: ${response.statusCode}");
    }
  }

  Future<bool> verifyPassword(String password) async {
    final token = await _getValidToken(); 
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
    } else if (response.statusCode == 401) {
      
      final refreshSuccess = await refreshTokenIfNeeded();
      if (refreshSuccess) {
        return await verifyPassword(password); 
      }
      print('Şifre doğrulama başarısız: ${response.body}');
      return false;
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
    final validToken = await _getValidToken(); 
    if (validToken == null) return false;

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
        'Authorization': 'Bearer $validToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 401) {
      
      final refreshSuccess = await refreshTokenIfNeeded();
      if (refreshSuccess) {
        return await updateUserProfile(
          userId: userId,
          token: await getString('token') ?? '',
          username: username,
          email: email,
          avatar: avatar,
          notifications: notifications,
          dailyGoal: dailyGoal,
        );
      }
      print('Profil güncelleme hatası: ${response.body}');
      return false;
    } else {
      print('Profil güncelleme hatası: ${response.body}');
      return false;
    }
  }

  Future<bool> refreshTokenIfNeeded() async {
    final refreshToken = await getString('refresh_token');
    if (refreshToken == null) {
      print('Refresh token bulunamadı');
      return false;
    }

    try {
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

        print('Token başarıyla yenilendi');
        return true;
      } else {
        print('Refresh token başarısız: ${response.statusCode} ${response.body}');
        
      
        if (response.statusCode == 401) {
          await logout();
        }
        
        return false;
      }
    } catch (e) {
      print('Refresh token hatası: $e');
      return false;
    }
  }


  Future<bool> isLoggedIn() async {
    final token = await getString('token');
    if (token == null) return false;
    
  
    if (!_isTokenExpired(token)) {
      return true;
    }
    
 
    return await refreshTokenIfNeeded();
  }

 
  Future<http.Response?> makeAuthenticatedRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? additionalHeaders,
  }) async {
    final token = await _getValidToken();
    if (token == null) {
      print('Geçerli token bulunamadı');
      return null;
    }

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      ...?additionalHeaders,
    };

    http.Response response;
    final uri = Uri.parse('$baseURL$endpoint');

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;
        default:
          throw Exception('Desteklenmeyen HTTP method: $method');
      }

 
      if (response.statusCode == 401) {
        final refreshSuccess = await refreshTokenIfNeeded();
        if (refreshSuccess) {
     
          final newToken = await getString('token');
          final newHeaders = {
            'Authorization': 'Bearer $newToken',
            'Content-Type': 'application/json',
            ...?additionalHeaders,
          };

          switch (method.toUpperCase()) {
            case 'GET':
              response = await http.get(uri, headers: newHeaders);
              break;
            case 'POST':
              response = await http.post(
                uri,
                headers: newHeaders,
                body: body != null ? jsonEncode(body) : null,
              );
              break;
            case 'PUT':
              response = await http.put(
                uri,
                headers: newHeaders,
                body: body != null ? jsonEncode(body) : null,
              );
              break;
            case 'DELETE':
              response = await http.delete(uri, headers: newHeaders);
              break;
          }
        }
      }

      return response;
    } catch (e) {
      print('API çağrısı hatası: $e');
      return null;
    }
  }
}