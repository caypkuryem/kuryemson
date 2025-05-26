// lib/profile/register_form.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // SharedPreferences'ı import edin
import '../services/api_service.dart'; // ApiService'i import edin

// DatabaseHelper ve User modelini artık bu methodda kullanmıyoruz,
// ancak projenizin başka yerlerinde kullanılıyorsa bu importları kaldırmayın.
// import '../services/database_helper.dart'; // DatabaseHelper'ı import edin
// import 'models/user.dart'; // User modelini import edin

// RegisterForm widget'ına geçiş callback'i eklendi
class RegisterForm extends StatefulWidget {
  final VoidCallback? onLoginInstead;

  const RegisterForm({Key? key, this.onLoginInstead}) : super(key: key);

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Form doğrulama için GlobalKey eklendi (isteğe bağlı ama iyi uygulama)
  final _formKey = GlobalKey<FormState>();

  // Yüklenme durumunu yönetmek için değişken
  bool _isLoading = false;

  // ApiService örneği oluştur
  final ApiService _apiService = ApiService();

  Future<void> _register() async {
    // Form alanlarının geçerliliğini kontrol et
    if (_formKey.currentState!.validate()) {
      // Form validasyonundan geçti

      setState(() {
        _isLoading = true; // Kayıt işlemi başladığında yükleme durumunu aktif et
      });

      final name = _nameController.text;
      final surname = _surnameController.text;
      final email = _emailController.text;
      final phone = _phoneController.text;
      final company = _companyController.text;
      final password = _passwordController.text;

      // SQlite kontrolünü kaldırıyoruz, e-posta kontrolü backend'de yapılacak.
      // Kullanıcı modelini de artık lokal DB için oluşturmuyoruz.

      try {
        // API servisi aracılığıyla kayıt API'sine istek gönder
        final result = await _apiService.registerUser(
          name: name,
          surname: surname,
          email: email,
          phone: phone,
          company: company,
          password: password,
        );

        // API'den gelen yanıtı kontrol et
        if (result['success']) {
          // Kayıt başarılı
          final user_id = result['user_id']; // API'den dönen kullanıcı ID'si

          // Başarılı mesajını göster
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );

          // Oturum açma mantığı: Başarılı kayıttan sonra otomatik giriş yap
          // API'den dönen user_id'yi shared preferences'a kaydet
          final prefs = await SharedPreferences.getInstance();
          // 'loggedInUserId' yerine 'user_id' kullanmak API'den gelen isimle tutarlı olur
          await prefs.setInt('user_id', user_id);

          // Kayıt ve otomatik giriş başarılı olduktan sonra Shared Preferences
          // güncellendiği için, AuthWrapper durumu algılayıp ana sayfaya (MyHomePage)
          // geçiş yapacaktır.
          // Navigation stack'i temizleyip ana rotaya git
          // Eğer ana rotanız '/' ise aşağıdaki gibi kullanabilirsiniz.
          // Rotalama yapınız farklıysa burayı kendi rotanıza göre ayarlayın.
          Navigator.pushReplacementNamed(context, '/');


        } else {
          // Kayıt başarısız (API'den gelen hata mesajı)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kayıt başarısız: ${result['message']}')),
          );
        }

      } catch (e) {
        // API çağrısı sırasında bir hata oluştu (örn. ağ hatası, JSON çözümleme hatası)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('API isteği başarısız: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false; // İşlem tamamlandığında yükleme durumunu kapat
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Form widget'ı ekleyerek doğrulama (_formKey) kullanıyoruz
    return Form(
      key: _formKey, // Form anahtarını ata
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            'Kayıt Ol',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextFormField( // TextField yerine TextFormField kullanarak doğrulama ekleyelim
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Ad',
              border: OutlineInputBorder(),
            ),
            validator: (value) { // Doğrulama fonksiyonu
              if (value == null || value.isEmpty) {
                return 'Lütfen adınızı girin.';
              }
              return null; // Doğrulama başarılı
            },
          ),
          const SizedBox(height: 12),
          TextFormField( // TextFormField
            controller: _surnameController,
            decoration: const InputDecoration(
              labelText: 'Soyad',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen soyadınızı girin.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField( // TextFormField
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'E-posta',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen e-posta adresinizi girin.';
              }
              // Basit e-posta formatı kontrolü ekleyebilirsiniz
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Geçerli bir e-posta adresi girin.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField( // TextFormField
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Telefon Numarası',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen telefon numaranızı girin.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField( // TextFormField
            controller: _companyController,
            decoration: const InputDecoration(
              labelText: 'Firma Adı',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen firma adınızı girin.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField( // TextFormField
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Şifre',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen bir şifre belirleyin.';
              }
              // Şifre için minimum uzunluk gibi ek kontroller ekleyebilirsiniz
              if (value.length < 6) {
                return 'Şifre en az 6 karakter olmalıdır.';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _isLoading // Yüklenme durumuna göre butonu veya loading spinner'ı göster
              ? const CircularProgressIndicator() // İşlem sürerken loading spinner göster
              : ElevatedButton(
            onPressed: _register, // Butona basıldığında _register metodunu çağır
            child: const Text('Kayıt Ol'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _isLoading ? null : widget.onLoginInstead, // İşlem sürerken butonu devre dışı bırak
            child: const Text('Zaten hesabın var mı? Giriş Yap'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}