import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:android_studio/constants.dart';
import 'package:android_studio/auth_service.dart';
import 'package:android_studio/screens/welcome_screen1.dart';
import 'package:android_studio/screens/home_screen.dart';
import 'package:android_studio/screens/password_reset_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
 
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("Environment loaded - API URL: ${dotenv.env['API_BASE_URL']}");
  } catch (e) {
    debugPrint("Environment load error: $e");
    
  }
  
  runApp(const MyApp());  
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Codebite',
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();
  final AppLinks _appLinks = AppLinks();
  
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _handleIncomingLinks();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

     
      final isLoggedIn = await _authService.isLoggedIn();
      
      if (isLoggedIn) {
        await _loadUserDataAndNavigate();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Uygulama başlatma hatası: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = "Bir hata oluştu. Lütfen tekrar deneyin.";
      });
    }
  }

  Future<void> _loadUserDataAndNavigate() async {
    try {
      final userResponse = await _authService.makeAuthenticatedRequest(
        'GET', 
        '/auth/me'
      );
      
      if (userResponse?.statusCode != 200) {
        throw Exception('Kullanıcı bilgisi alınamadı');
      }

      final userInfo = jsonDecode(userResponse!.body);

      
      await _authService.setString('user_id', userInfo['id'].toString());
      await _authService.setString('user_name', userInfo['username']);
      await _authService.setString('user_mail', userInfo['email']);

     
      await _authService.fetchAndSaveUserAvatar(
        await _authService.getString('token') ?? ''
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            userName: userInfo['username'],
            userMail: userInfo['email'],
          ),
        ),
      );
    } catch (e) {
      debugPrint("Kullanıcı verisi yükleme hatası: $e");
      setState(() => _isLoading = false);
    }
  }

  void _handleIncomingLinks() {
    _appLinks.uriLinkStream.listen(
      (Uri? uri) => _processAppLink(uri),
      onError: (err) => debugPrint('App link error: $err'),
    );

    _appLinks.getInitialAppLink().then((Uri? uri) {
      if (uri != null) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _processAppLink(uri)
        );
      }
    });
  }

  void _processAppLink(Uri? uri) {
    if (uri?.scheme != 'codebite' || uri?.host != 'reset-password') {
      return;
    }

    final token = uri?.queryParameters['token'];
    if (token?.isNotEmpty == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PasswordResetScreen(token: token!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeApp,
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    return const WelcomeScreen1();
  }
}