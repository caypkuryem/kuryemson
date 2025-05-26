// lib/profile/screens/profile_info.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Sadece kullanıcı ID'si için
import '../models/user.dart'; // User modelini import edin (doğru yolu kontrol edin)
import '../../services/database_helper.dart'; // DatabaseHelper'ı import edin (doğru yolu kontrol edin)
import 'profile_screen.dart'; // ProfileScreen'e yönlendirme için

class ProfileInfoScreen extends StatefulWidget {
  const ProfileInfoScreen({super.key});

  @override
  State<ProfileInfoScreen> createState() => _ProfileInfoScreenState();
}

class _ProfileInfoScreenState extends State<ProfileInfoScreen> {
  User? _userData;
  String? _profileImagePath; // Bu bilgi hala SharedPreferences'ta tutuluyor gibi duruyor.
  // Eğer User modeline veya DB'ye eklenecekse oradan okunmalı.

  static const String keyProfileImagePath = 'profileImagePath'; // profile_screen.dart ile aynı olmalı

  @override
  void initState() {
    super.initState();
    _fetchUserDataAndImagePath();
  }

  Future<void> _fetchUserDataAndImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    final int? userId = prefs.getInt('loggedInUserId'); // profile_screen.dart ile aynı anahtar olmalı

    if (userId != null) {
      final user = await DatabaseHelper.instance.getUserById(userId);
      if (user != null) {
        if (mounted) {
          setState(() {
            _userData = user;
            _profileImagePath = prefs.getString(keyProfileImagePath);
          });
        }
      } else {
        // Kullanıcı DB'de bulunamadı, bu bir sorun olabilir.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kullanıcı verileri bulunamadı.')),
          );
        }
      }
    } else {
      // Kullanıcı ID yok, giriş yapılmamış.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giriş yapmış kullanıcı bulunamadı.')),
        );
        // Giriş ekranına yönlendirme yapılabilir.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Bilgileri'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Profili Düzenle',
            onPressed: () async {
              // ProfileScreen'e git ve geri dönüldüğünde verileri yenile
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
              // ProfileScreen'den geri dönüldüğünde (pop ile),
              // verilerin güncellenmiş olma ihtimaline karşı yeniden yükle.
              // ProfileScreen bir değer döndürürse (örn: true), o zaman yenileme yapılabilir.
              // Şimdilik her dönüşte yeniliyoruz.
              _fetchUserDataAndImagePath();
            },
          ),
        ],
      ),
      body: _userData == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator( // Pull-to-refresh ekleyelim
        onRefresh: _fetchUserDataAndImagePath,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: _profileImagePath != null
                        ? FileImage(File(_profileImagePath!)) // FileImage File nesnesi bekler
                        : null, // Veya varsayılan bir avatar: AssetImage('assets/default_avatar.png')
                    child: _profileImagePath == null
                        ? const Icon(Icons.person, size: 60, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${_userData!.name} ${_userData!.surname}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userData!.email,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'İletişim Bilgileri'),
            const Divider(thickness: 1),
            ProfileDetailRow(icon: Icons.phone_outlined, title: 'Telefon', value: _userData!.phone),
            ProfileDetailRow(icon: Icons.business_outlined, title: 'Şirket', value: _userData!.company),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Ek Bilgiler'),
            const Divider(thickness: 1),
            ProfileDetailRow(
              icon: Icons.location_city_outlined,
              title: 'Çalıştığı Bölge',
              value: _userData!.calistigiBolge ?? 'Belirtilmemiş', // User modelinden gelen veri
            ),
            // Eğer motor plakası User modeline ve DB'ye eklendiyse:
            // ProfileDetailRow(
            //   icon: Icons.motorcycle_outlined,
            //   title: 'Motor Plakası',
            //   value: _userData!.motorPlate ?? 'Belirtilmemiş',
            // ),
            // Şimdilik motor plakası bu ekranda gösterilmiyor varsayalım,
            // çünkü sadece SharedPreferences'taydı ve _userData'da yok.
            // Eğer gösterilecekse ve sadece SP'deyse, _fetchUserDataAndImagePath içinde o da okunmalı.

            // Diğer bilgiler buraya eklenebilir.
            // Örneğin, SharedPreferences'tan okunan müsaitlik durumu vb.
            // Ancak bu ekran daha çok DB'den gelen "sabit" profil bilgilerini göstermeli.
            // Ayarlar için ProfileScreen daha uygun.
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class ProfileDetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const ProfileDetailRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24.0, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2.0),
                Text(
                  value.isNotEmpty ? value : 'Belirtilmemiş',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}