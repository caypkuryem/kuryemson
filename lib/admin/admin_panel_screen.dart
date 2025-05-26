// lib/admin_panel_screen.dart

import 'package:flutter/material.dart';
// Projenizdeki doğru yolları kullandığınızdan emin olun
import '../services/api_service.dart';
import '../profile/models/user.dart'; // YOLU KONTROL EDİN

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  late Future<List<User>> _usersFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    setState(() {
      _usersFuture = _apiService.getAllUsers();
    });
  }

  void _refreshUsers() {
    print("[AdminPanelScreen] Kullanıcı listesi yenileniyor...");
    _loadUsers();
  }

  void _showUserDetails(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(user.fullName), // User modelinizdeki fullName getter'ı
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('ID: ${user.id}'),
                Text('E-posta: ${user.email}'),
                Text('Telefon: ${user.phone ?? 'Belirtilmemiş'}'),
                Text('Firma: ${user.company ?? 'Belirtilmemiş'}'),
                // user.hesapDurumuAciklamasi getter'ını kullanmak daha iyi olabilir
                Text('Hesap Durumu: ${user.hesapDurumuAciklamasi ?? user.hesapDurumu ?? 'Bilinmiyor'}'),
                Text('Çalıştığı Bölge: ${user.calistigiBolge ?? 'Belirtilmemiş'}'),
                Text('Motor Plakası: ${user.motorPlakasi ?? 'Belirtilmemiş'}'),
                if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Avatar:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Image.network(user.avatarUrl!, height: 100, fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Text('Avatar yüklenemedi');
                          },
                        ),
                      ],
                    ),
                  ),
                // Parola gösterilmemeli
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Kapat'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            // TODO: Rol değiştirme, engelleme gibi butonlar buraya eklenebilir
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yönetici Paneli - Kullanıcılar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshUsers,
            tooltip: 'Listeyi Yenile',
          ),
        ],
      ),
      body: FutureBuilder<List<User>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // ... (hata gösterme kısmı aynı kalabilir) ...
            print("[AdminPanelScreen-FutureBuilder] Hata: ${snapshot.error}");
            print("[AdminPanelScreen-FutureBuilder] StackTrace: ${snapshot.stackTrace}");
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 50),
                    const SizedBox(height: 10),
                    Text(
                      'Kullanıcılar yüklenirken bir hata oluştu.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tekrar Dene'),
                      onPressed: _refreshUsers,
                    )
                  ],
                ),
              ),
            );
          } else if (snapshot.hasData) {
            final users = snapshot.data!;
            if (users.isEmpty) {
              // ... (boş liste gösterme kısmı aynı kalabilir) ...
              return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline, size: 50, color: Colors.grey),
                      const SizedBox(height: 10),
                      const Text('Gösterilecek kullanıcı bulunamadı.'),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Yeniden Kontrol Et'),
                        onPressed: _refreshUsers,
                      )
                    ],
                  )
              );
            }
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                          ? NetworkImage(user.avatarUrl!)
                          : null,
                      backgroundColor: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                          ? Colors.transparent // Arka planı şeffaf yap eğer resim varsa
                          : _getAvatarColor(user.hesapDurumu), // Modelinizdeki hesapDurumu
                      foregroundColor: Colors.white,
                      child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                          ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?')
                          : null,
                    ),
                    title: Text(user.fullName), // Modelinizdeki fullName getter'ı
                    subtitle: Text(
                        'ID: ${user.id} - ${user.email}\nDurum: ${user.hesapDurumuAciklamasi ?? user.hesapDurumu ?? 'Bilinmiyor'}'),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // TODO: Rol değiştirme ve engelleme butonları eklenecek
                      ],
                    ),
                    onTap: () {
                      _showUserDetails(context, user);
                    },
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('Kullanıcı bulunamadı veya bir sorun oluştu.'));
          }
        },
      ),
      // TODO: Yeni kullanıcı ekleme butonu (FloatingActionButton) eklenebilir
    );
  }

  Color _getAvatarColor(String? hesapDurumu) {
    // Modelinizdeki hesapDurumuAciklamasi veya doğrudan hesapDurumu kullanılabilir.
    // Sizin User modelinizdeki switch-case yapısına benzer bir mantık.
    switch (hesapDurumu?.toLowerCase()) {
      case 'admin':
        return Colors.redAccent;
      case 'kurye':
        return Colors.green;
      case 'musteri':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

// TODO: Rol Değiştirme Dialog'u
// void _promptChangeRole(BuildContext context, User user) { ... }
}