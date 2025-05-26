
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart'; // MyHomePage ve MyApp'i kullanmak için
import 'auth/auth_screen.dart'; // Giriş/Kayıt Ekranı (lib/auth altında olacak)

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoggedIn = false;
  bool _isLoading = true; // Oturum kontrolü yapılırken yüklenme durumu

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // Widget oluşturulduğunda oturum durumunu kontrol et
  }

  // Oturum durumunu shared_preferences'tan kontrol et
  Future<void> _checkLoginStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? userId = prefs.getInt('loggedInUserId'); // Anahtar düzeltildi
    setState(() {
      // Kullanıcı ID'si null değilse giriş yapılmıştır
      _isLoggedIn = userId != null;
      _isLoading = false; // Yüklenme tamamlandı
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isLoggedIn) {
      return const MyHomePage(); // Kullanıcı giriş yapmışsa Ana Sayfa
    } else {
      // Kullanıcı giriş yapmamışsa Giriş/Kayıt ekranını göster
      return const AuthScreen(); // AuthScreen'ı doğrudan döndürüyoruz
    }
  }
}