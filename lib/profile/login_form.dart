// lib/profile/login_form.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart'; // ApiService'ı import et
import '../services/database_helper.dart'; // DatabaseHelper'ı import et
import '../profile/models/user.dart'; // User modelini import et

// LoginForm widget'ına geçiş callback'i
class LoginForm extends StatefulWidget {
  final VoidCallback? onRegisterInstead;

  const LoginForm({Key? key, this.onRegisterInstead}) : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Yüklenme durumunu yönetmek için bir bayrak
  bool _isLoading = false;

  Future<void> _login() async {
    print('----------------------------------------------------');
    print('[LoginForm] _login FONKSİYONU BAŞLADI!');
    final String email = _emailController.text;
    final String password = _passwordController.text;
    print('[LoginForm] Email: $email'); // Şifreyi güvenlik nedeniyle loglamaktan kaçının

    if (email.isEmpty || password.isEmpty) {
      print('[LoginForm] Email veya şifre boş.');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun.')),
      );
      print('[LoginForm] _login FONKSİYONU BİTTİ! (Boş alanlar)');
      print('----------------------------------------------------');
      return;
    }

    // setState çağırmadan önce mounted kontrolü
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
      print('[LoginForm] _isLoading = true olarak ayarlandı (API çağrısı öncesi).');
    } else {
      print('[LoginForm] _login FONKSİYONU BİTTİ! (API çağrısı öncesi mounted=false)');
      print('----------------------------------------------------');
      return; // mounted değilse devam etmenin anlamı yok
    }

    try {
      ApiService apiService = ApiService();
      print('[LoginForm] ApiService.loginUser çağrılıyor...');
      Map<String, dynamic> apiResponse = await apiService.loginUser(email: email, password: password);
      print('[LoginForm] ApiService.loginUser YANITI GELDİ: $apiResponse'); // Bu log çok önemli!

      if (!mounted) { // API çağrısından sonra da kontrol et
        print('[LoginForm] _login FONKSİYONU BİTTİ! (API yanıtı sonrası mounted=false)');
        print('----------------------------------------------------');
        return;
      }

      if (apiResponse['success'] == true) {
        print('[LoginForm] API yanıtı başarılı (success: true).');
        final SharedPreferences prefs = await SharedPreferences.getInstance();

        // ----> TOKEN KAYDETME KISMI <----
        if (apiResponse.containsKey('token')) {
          final String? apiToken = apiResponse['token'] as String?; // try-catch eklenebilir
          if (apiToken != null && apiToken.isNotEmpty) {
            await prefs.setString('authToken', apiToken);
            print('[LoginForm] SharedPreferences: authToken KAYDEDİLDİ: $apiToken');
          } else {
            print('[LoginForm-UYARI] API yanıtında "token" değeri BOŞ veya NULL geldi. Yanıt: $apiResponse');
          }
        } else {
          print('[LoginForm-HATA] API yanıtında "token" anahtarı BULUNAMADI! Yanıt: $apiResponse');
        }
        // ----> TOKEN KAYDETME KISMI BİTİŞ <----

        final dynamic apiId = apiResponse['id'];
        int? userIdToSave;

        if (apiId is int) {
          userIdToSave = apiId;
        } else if (apiId is String) {
          userIdToSave = int.tryParse(apiId);
        }
        print('[LoginForm] Parsed userIdToSave: $userIdToSave (Gelen apiId: $apiId)');

        if (userIdToSave != null) {
          await prefs.setInt('loggedInUserId', userIdToSave);
          print('[LoginForm] SharedPreferences: loggedInUserId kaydedildi: $userIdToSave');

          // ----> VERİTABANINA KAYIT KISMI <----
          print('[LoginForm] Veritabanına kayıt/güncelleme bloğuna giriliyor...');
          try {
            User userFromApi = User.fromApiResponse(apiResponse, userIdToSave);
            print('[LoginForm-DEBUG] Oluşturulan User nesnesi (userFromApi.toMap()): ${userFromApi.toMap()}');

            User? existingUser = await DatabaseHelper.instance.getUserById(userIdToSave);
            print('[LoginForm-DEBUG] Veritabanında existingUser kontrolü (ID: $userIdToSave): ${existingUser?.id != null ? 'Bulundu (ID: ${existingUser!.id})' : 'Bulunamadı'}');

            if (existingUser != null) {
              print('[LoginForm] Kullanıcı (ID: $userIdToSave) veritabanında bulundu, güncelleme deneniyor...');
              await DatabaseHelper.instance.updateUser(userFromApi);
              print('[LoginForm] Yerel veritabanı: Kullanıcı güncellendi - ID: $userIdToSave');
            } else {
              print('[LoginForm] Kullanıcı (ID: $userIdToSave) veritabanında bulunamadı, ekleme deneniyor...');
              await DatabaseHelper.instance.insertUser(userFromApi);
              print('[LoginForm] Yerel veritabanı: Yeni kullanıcı eklendi - ID: $userIdToSave');
            }
            print('[LoginForm] Veritabanı işlemi (insert/update) tamamlandı.');
          } catch (dbError, stackTrace) {
            print('[LoginForm-HATA] Yerel veritabanına kullanıcı kaydı/güncelleme sırasında HATA: $dbError');
            print('[LoginForm-HATA-STACKTRACE] $stackTrace');
            if (!mounted) {
              print('[LoginForm] _login FONKSİYONU BİTTİ! (Veritabanı hatası sonrası mounted=false)');
              print('----------------------------------------------------');
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Yerel veritabanı hatası: $dbError. Lütfen tekrar deneyin.')),
            );
            // Hata durumunda _isLoading'i false yapıp fonksiyondan çıkalım
            if (mounted) { // Tekrar mounted kontrolü, setState için
              setState(() { _isLoading = false; });
              print('[LoginForm] _isLoading = false olarak ayarlandı (veritabanı hatası sonrası).');
            }
            print('[LoginForm] _login FONKSİYONU BİTTİ! (Veritabanı hatası)');
            print('----------------------------------------------------');
            return;
          }
          // ----> VERİTABANINA KAYIT KISMI BİTİŞ <----

          print('[LoginForm] Diğer SharedPreferences bilgilerini kaydetmeye başlıyor...');
          if (apiResponse.containsKey('name')) await prefs.setString('loggedInUserName', apiResponse['name'] as String? ?? '');
          if (apiResponse.containsKey('surname')) await prefs.setString('loggedInUserSurname', apiResponse['surname'] as String? ?? '');
          if (apiResponse.containsKey('email')) await prefs.setString('loggedInUserEmail', apiResponse['email'] as String? ?? '');
          if (apiResponse.containsKey('phone')) await prefs.setString('loggedInUserPhone', apiResponse['phone']?.toString() ?? '');
          if (apiResponse.containsKey('company')) await prefs.setString('loggedInUserCompany', apiResponse['company']?.toString() ?? '');
          if (apiResponse.containsKey('hesapdurum')) await prefs.setString('loggedInUserAccountStatus', apiResponse['hesapdurum']?.toString() ?? 'bilgi yok');
          if (apiResponse.containsKey('created_at')) await prefs.setString('loggedInUserCreatedAt', apiResponse['created_at']?.toString() ?? 'bilgi yok');
          if (apiResponse.containsKey('motor_plakasi')) await prefs.setString('loggedInUserMotorPlate', apiResponse['motor_plakasi']?.toString() ?? '');
          if (apiResponse.containsKey('calistigi_il_ilce')) await prefs.setString('loggedInUserWorkLocation', apiResponse['calistigi_il_ilce']?.toString() ?? '');
          print('[LoginForm] Diğer SharedPreferences bilgileri kaydedildi.');


          if (!mounted) {
            print('[LoginForm] _login FONKSİYONU BİTTİ! (Yönlendirme öncesi mounted=false)');
            print('----------------------------------------------------');
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Giriş başarılı! Yönlendiriliyor...')),
          );
          print('[LoginForm] /main_app ekranına yönlendiriliyor...');
          Navigator.pushReplacementNamed(context, '/main_app');

        } else {
          print('[LoginForm-HATA] API\'den gelen ID null veya parse edilemedi. Gelen ID: $apiId. Yanıt: $apiResponse');
          if (!mounted) {
            print('[LoginForm] _login FONKSİYONU BİTTİ! (ID parse hatası sonrası mounted=false)');
            print('----------------------------------------------------');
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Giriş başarılı ancak kullanıcı ID alınamadı veya formatı geçersiz.')),
          );
        }
      } else {
        print('[LoginForm-HATA] API yanıtı başarısız (success: false). Mesaj: ${apiResponse['message']}. Yanıt: $apiResponse');
        if (!mounted) {
          print('[LoginForm] _login FONKSİYONU BİTTİ! (API başarısız sonrası mounted=false)');
          print('----------------------------------------------------');
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiResponse['message'] as String? ?? 'Giriş başarısız oldu.')),
        );
      }
    } catch (e, stackTrace) {
      print('[LoginForm-GENEL-HATA] Giriş sırasında bir hata oluştu: ${e.toString()}');
      print('[LoginForm-GENEL-HATA-STACKTRACE] $stackTrace');
      if (!mounted) {
        print('[LoginForm] _login FONKSİYONU BİTTİ! (Genel hata sonrası mounted=false)');
        print('----------------------------------------------------');
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Giriş sırasında bir hata oluştu: ${e.toString()}')),
      );
    } finally {
      print('[LoginForm] _login finally bloğu çalıştı.');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        print('[LoginForm] _isLoading = false olarak ayarlandı (finally).');
      } else {
        print('[LoginForm] finally bloğunda mounted=false, setState çağrılmadı.');
      }
    }
    print('[LoginForm] _login FONKSİYONU BİTTİ!');
    print('----------------------------------------------------');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Giriş Yap',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'E-posta',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Şifre',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 20),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
            onPressed: _login, // Bu zaten doğru ayarlanmış
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              textStyle: const TextStyle(fontSize: 18),
            ),
            child: const Text('Giriş Yap'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _isLoading ? null : widget.onRegisterInstead,
            child: const Text('Hesabın yok mu? Kayıt Ol'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    print('[LoginForm] dispose çağrıldı.'); // Dispose logu
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}