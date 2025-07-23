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



}
