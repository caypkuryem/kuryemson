// lib/auth/auth_screen.dart

import 'package:flutter/material.dart';
// Import yolları, formların lib/profile altında olduğunu varsayarak düzeltildi
import '../profile/login_form.dart'; // lib/profile/login_form.dart'ı içeri aktarın
import '../profile/register_form.dart'; // lib/profile/register_form.dart'ı içeri aktarın

// Giriş ve Kayıt Formlarını içerecek veya yönlendirecek ekran
class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _showLoginForm = true; // Başlangıçta Giriş Formunu göster

  void _toggleForm() {
    setState(() {
      _showLoginForm = !_showLoginForm; // Formlar arasında geçiş yap
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showLoginForm ? 'Giriş Yap' : 'Kayıt Ol'),
      ),
      body: Center( // Center widget'ı içeriği ortalamak için
        child: SingleChildScrollView( // İçerik taşarsa kaydırılabilir yapmak için
          padding: const EdgeInsets.all(16.0),
          child: _showLoginForm
              ? LoginForm( // Giriş Formu widget'ı (lib/profile altında)
            onRegisterInstead: _toggleForm, // Kayıt Ol'a geçiş callback'i
          )
              : RegisterForm( // Kayıt Formu widget'ı (lib/profile altında)
            onLoginInstead: _toggleForm, // Giriş Yap'a geçiş callback'i
          ),
        ),
      ),
    );
  }
}