import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ApiService ve User modelini import et
import '../../services/api_service.dart'; // api_service.dart dosyanızın doğru yolunu belirtin
import '../../profile/models/user.dart'; // user.dart dosyanızın doğru yolunu belirtin
// AuthScreen veya LoginScreen (Çıkış sonrası yönlendirme için)
// ÖNEMLİ: Çıkış yapma işlevi için bu import'u etkinleştirin ve doğru yolu belirtin
// import '../../auth/screens/auth_screen.dart'; // Örnek yol, kendi projenize göre ayarlayın

class Anasayfa extends StatefulWidget {
  const Anasayfa({super.key});

  @override
  State<Anasayfa> createState() => _AnasayfaState();
}

class _AnasayfaState extends State<Anasayfa> {
  final ApiService _apiService = ApiService();
  bool _konumPaylasimiAktif = true;

  List<User> _sonKayitOlanKullanicilar = [];
  bool _kullanicilarYukleniyor = true;
  String? _kullaniciListesiHataMesaji;

  User? _mevcutKullanici;
  bool _mevcutKullaniciYukleniyor = true;

  // ÖNEMLİ: Resimlerinizin bulunduğu sunucunun ana URL'si
  // Bu URL'yi kendi sunucu yapılandırmanıza göre değiştirin.
  // Örneğin: "https://www.siteniz.com/uploads/avatars/"
  // Eğer ApiService içinde bir baseUrl tanımlıysa, onu kullanmak daha iyi olabilir:
  // final String _baseAvatarUrl = ApiService.baseUrl + "uploads/avatars/";
  final String _baseAvatarUrl = "https://caypmodel.store/kuryem_api/"; // <--- BURAYI GÜNCELLEYİN!

  final List<Map<String, String>> _oneCikanlarListesi = [
    {
      "image": "https://via.placeholder.com/300x150.png?text=Sahil+Yolu",
      "title": "Sahil Yolu Trafiğe Kapandı",
      "subtitle": "Bugün 10:30"
    },
    {
      "image": "https://via.placeholder.com/300x150.png?text=Yeni+Yol",
      "title": "Yeni Çevre Yolu Açıldı",
      "subtitle": "Dün 15:00"
    },
  ];

  final List<Map<String, dynamic>> _kategoriListesi = [
    {"icon": Icons.car_crash_outlined, "label": "Kaza Bildir", "action": () { print("Kaza Bildir tıklandı"); }},
    {"icon": Icons.build_outlined, "label": "Yol Çalışması", "action": () { print("Yol Çalışması tıklandı"); }},
    {"icon": Icons.local_police_outlined, "label": "Polis Kontrolü", "action": () { print("Polis Kontrolü tıklandı"); }},
    {"icon": Icons.warning_amber_rounded, "label": "Tehlike Bildir", "action": () { print("Tehlike Bildir tıklandı"); }},
  ];

  @override
  void initState() {
    super.initState();
    _loadMevcutKullaniciBilgileri();
    _fetchSonKayitOlanKullanicilar();
  }

  Future<void> _loadMevcutKullaniciBilgileri() async {
    setState(() {
      _mevcutKullaniciYukleniyor = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId != null) {
        _mevcutKullanici = User(
          id: userId,
          name: prefs.getString('userName') ?? '',
          surname: prefs.getString('userSurname') ?? '',
          email: prefs.getString('userEmail') ?? '',
          password: '', // Password genellikle SharedPreferences'te saklanmaz veya boş bırakılır
          phone: prefs.getString('userPhone'),
          company: prefs.getString('userCompany'),
          avatarUrl: prefs.getString('userAvatarUrl'), // SharedPreferences'ten avatar URL'sini oku
          // Diğer alanlar (motorPlakasi, calistigiIlIlce vb.) User modelinize ve SP'ye göre eklenebilir
        );
      } else {
        _mevcutKullanici = null;
      }
    } catch (e) {
      if (mounted) {
        debugPrint("SharedPreferences'ten mevcut kullanıcı bilgileri okunurken hata: $e");
        _mevcutKullanici = null;
      }
    } finally {
      if (mounted) {
        setState(() {
          _mevcutKullaniciYukleniyor = false;
        });
      }
    }
  }

  Future<void> _fetchSonKayitOlanKullanicilar() async {
    setState(() {
      _kullanicilarYukleniyor = true;
      _kullaniciListesiHataMesaji = null;
    });
    try {
      // ApiService'in User nesnelerini avatarUrl ile birlikte döndürdüğünden emin olun
      final users = await _apiService.getLatestRegisteredUsers(limit: 5);
      if (mounted) {
        setState(() {
          _sonKayitOlanKullanicilar = users;
          _kullanicilarYukleniyor = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _kullaniciListesiHataMesaji = e.message;
          _kullanicilarYukleniyor = false;
        });
        debugPrint("API'den son kullanıcılar çekilirken hata (ApiException): ${e.message}");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _kullaniciListesiHataMesaji = "Bilinmeyen bir hata oluştu: ${e.toString()}";
          _kullanicilarYukleniyor = false;
        });
        debugPrint("API'den son kullanıcılar çekilirken genel hata: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: const Text('Ana Sayfa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              print("Bildirimler tıklandı");
              // Navigator.push(context, MaterialPageRoute(builder: (context) => const BildirimlerSayfasi()));
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchSonKayitOlanKullanicilar();
          await _loadMevcutKullaniciBilgileri();
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildKonumBolumu(),
            const SizedBox(height: 24),
            _buildBaslik("Yol Durumu Güncellemeleri"),
            const SizedBox(height: 16),
            _buildYatayKartListesi(
              context: context,
              height: 200,
              itemCount: _oneCikanlarListesi.length,
              itemBuilder: (context, index) {
                final item = _oneCikanlarListesi[index];
                return _buildOneCikanKart(
                  imageUrl: item["image"]!,
                  title: item["title"]!,
                  subtitle: item["subtitle"]!,
                );
              },
            ),
            const SizedBox(height: 24),
            _buildBaslik("Hızlı Bildirim"),
            const SizedBox(height: 16),
            _buildYatayKartListesi(
              context: context,
              height: 130,
              itemCount: _kategoriListesi.length,
              itemBuilder: (context, index) {
                final kategori = _kategoriListesi[index];
                return _buildKategoriKarti(
                  icon: kategori["icon"] as IconData,
                  label: kategori["label"] as String,
                  onTap: kategori["action"] as VoidCallback,
                );
              },
            ),
            const SizedBox(height: 24),
            _buildBaslik("Son Kayıt Olanlar"),
            const SizedBox(height: 16),
            _buildSonKayitOlanKullanicilarListesi(), // Bu widget _buildKullaniciKarti'nı kullanacak
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    String? drawerAvatarFinalUrl = _mevcutKullanici?.avatarUrl;
    if (drawerAvatarFinalUrl != null &&
        drawerAvatarFinalUrl.isNotEmpty &&
        !drawerAvatarFinalUrl.startsWith('http://') &&
        !drawerAvatarFinalUrl.startsWith('https://')) {
      drawerAvatarFinalUrl = _baseAvatarUrl + drawerAvatarFinalUrl;
    }

    ImageProvider? drawerBackgroundImageProvider;
    if (drawerAvatarFinalUrl != null &&
        drawerAvatarFinalUrl.isNotEmpty &&
        Uri.tryParse(drawerAvatarFinalUrl)?.hasAbsolutePath == true) {
      drawerBackgroundImageProvider = NetworkImage(drawerAvatarFinalUrl);
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          if (_mevcutKullaniciYukleniyor)
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            )
          else if (_mevcutKullanici != null)
            UserAccountsDrawerHeader(
              accountName: Text(
                _mevcutKullanici!.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(_mevcutKullanici!.email),
              currentAccountPicture: CircleAvatar(
                backgroundImage: drawerBackgroundImageProvider,
                onBackgroundImageError: drawerBackgroundImageProvider != null
                    ? (exception, stackTrace) {
                  debugPrint('Drawer avatar yüklenirken hata: $drawerAvatarFinalUrl, Hata: $exception');
                }
                    : null,
                backgroundColor: Colors.grey[300],
                child: (drawerBackgroundImageProvider == null)
                    ? Text(
                  _mevcutKullanici!.name.isNotEmpty ? _mevcutKullanici!.name[0].toUpperCase() : "?",
                  style: const TextStyle(fontSize: 40.0, color: Colors.white70),
                )
                    : null,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
            )
          else
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const Text(
                'Kuryem App',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Ana Sayfa'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: const Text('Harita'),
            onTap: () {
              Navigator.pop(context);
              print("Harita menü öğesi tıklandı");
              // TODO: Harita sayfasına yönlendirme
              // Navigator.push(context, MaterialPageRoute(builder: (context) => HaritaSayfasi()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profilim'),
            onTap: () {
              Navigator.pop(context);
              print("Profilim menü öğesi tıklandı");
              // TODO: Profil sayfasına yönlendirme
              // Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilSayfasi(userId: _mevcutKullanici?.id)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Ayarlar'),
            onTap: () {
              Navigator.pop(context);
              print("Ayarlar menü öğesi tıklandı");
              // TODO: Ayarlar sayfasına yönlendirme
              // Navigator.push(context, MaterialPageRoute(builder: (context) => AyarlarSayfasi()));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Çıkış Yap'),
            onTap: () async {
              Navigator.pop(context); // Önce drawer'ı kapat
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear(); // Tüm SharedPreferences verilerini temizle
              await _apiService.logout(); // Eğer varsa API üzerinden de çıkış yap

              if (mounted) {
                // Kullanıcıyı giriş ekranına yönlendir
                // AuthScreen veya LoginScreen'i ve import'unu etkinleştirin
                // Navigator.of(context).pushAndRemoveUntil(
                //   MaterialPageRoute(builder: (context) => const AuthScreen(showLoginPageInitially: true)),
                //   (Route<dynamic> route) => false,
                // );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Başarıyla çıkış yapıldı.")),
                );
                // YUKARIDAKİ NAVIGATOR SATIRINI AKTİF EDİN VE İLGİLİ SAYFAYA YÖNLENDİRİN
                // Örneğin AuthScreen'e:
                // Navigator.of(context).pushAndRemoveUntil(
                //   MaterialPageRoute(builder: (context) => const AuthScreen(showLoginPageInitially: true)), // AuthScreen veya LoginScreen
                //   (Route<dynamic> route) => false,
                // );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBaslik(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildKonumBolumu() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Konum Paylaşımı", style: Theme.of(context).textTheme.titleMedium),
            Switch(
              value: _konumPaylasimiAktif,
              onChanged: (bool value) {
                setState(() {
                  _konumPaylasimiAktif = value;
                });
                print("Konum paylaşımı: $value");
                // TODO: Konum paylaşımı durumunu API'ye veya yerel depolamaya kaydet
              },
              activeColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYatayKartListesi({
    required BuildContext context,
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    double height = 180.0,
  }) {
    if (itemCount == 0) {
      return SizedBox(
        height: height,
        child: const Center(
            child: Text("Gösterilecek içerik bulunamadı.", style: TextStyle(color: Colors.grey))),
      );
    }
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: itemBuilder(context, index),
          );
        },
      ),
    );
  }

  Widget _buildOneCikanKart({required String imageUrl, required String title, required String subtitle}) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75,
      child: Card(
        elevation: 3,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey)),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ));
                },
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis
                    ),
                    Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKategoriKarti({required IconData icon, required String label, required VoidCallback onTap}) {
    return SizedBox(
      width: 110,
      child: Material(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).cardColor,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSonKayitOlanKullanicilarListesi() {
    if (_kullanicilarYukleniyor) {
      return const SizedBox(
          height: 150, // Yükseklik biraz artırıldı
          child: Center(child: CircularProgressIndicator()));
    }

    if (_kullaniciListesiHataMesaji != null) {
      return SizedBox(
        height: 150,
        child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Kullanıcılar yüklenemedi: $_kullaniciListesiHataMesaji",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red)),
            )),
      );
    }

    if (_sonKayitOlanKullanicilar.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(child: Text("Henüz kayıt olan kullanıcı bulunmuyor.")),
      );
    }

    return _buildYatayKartListesi(
      context: context,
      height: 150, // Yükseklik kullanıcı kartına göre ayarlandı
      itemCount: _sonKayitOlanKullanicilar.length,
      itemBuilder: (context, index) {
        final user = _sonKayitOlanKullanicilar[index];
        return _buildKullaniciKarti(user); // Güncellenmiş kullanıcı kartı widget'ı çağrılıyor
      },
    );
  }

  // --- GÜNCELLENMİŞ KULLANICI KARTI WIDGET'I ---
  Widget _buildKullaniciKarti(User user) {
    String? rawAvatarUrl = user.avatarUrl;
    String? finalAvatarUrl;
    ImageProvider? backgroundImageProvider;

    if (rawAvatarUrl != null && rawAvatarUrl.isNotEmpty) {
      if (rawAvatarUrl.startsWith('http://') || rawAvatarUrl.startsWith('https://')) {
        finalAvatarUrl = rawAvatarUrl; // Zaten tam bir URL
      } else {
        // Sadece dosya adı ise, _baseAvatarUrl ile birleştir
        finalAvatarUrl = _baseAvatarUrl + rawAvatarUrl;
      }

      // Güvenlik için URL geçerliliğini kontrol et
      if (Uri.tryParse(finalAvatarUrl)?.hasAbsolutePath == true) {
        backgroundImageProvider = NetworkImage(finalAvatarUrl);
      } else {
        debugPrint('Geçersiz avatar URL formatı oluşturuldu veya _baseAvatarUrl hatalı: $finalAvatarUrl');
        finalAvatarUrl = null; // Geçersizse null yap ki varsayılan ikon/harf görünsün
      }
    }

    return SizedBox(
      width: 110, // Genişlik biraz artırıldı
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Daha yuvarlak köşeler
        child: InkWell(
          onTap: () {
            print("${user.fullName} profiline tıklandı (ID: ${user.id})");
            // TODO: Kullanıcı profili sayfasına yönlendirme
            // Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileScreen(userId: user.id)));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("${user.fullName} profili (TODO)")),
            );
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(10.0), // Padding biraz artırıldı
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30, // Avatar boyutu biraz büyütüldü
                  backgroundImage: backgroundImageProvider,
                  onBackgroundImageError: backgroundImageProvider != null ? (exception, stackTrace) {
                    debugPrint('Son kullanıcı avatar yüklenirken hata oluştu ($finalAvatarUrl): $exception');
                  } : null,
                  backgroundColor: Colors.grey[200],
                  child: (backgroundImageProvider == null)
                      ? (user.name.isNotEmpty
                      ? Text(
                    user.name[0].toUpperCase(),
                    style: TextStyle(fontSize: 22, color: Theme.of(context).primaryColorDark), // Harf için stil
                  )
                      : Icon(Icons.person_outline, size: 30, color: Colors.grey[700]))
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  user.name, // Sadece isim gösterilebilir, soyisim ile çok uzun olabilir
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // İsteğe bağlı olarak soyadını da ekleyebilirsiniz ama kart küçük kalabilir
                // if (user.surname.isNotEmpty)
                //   Text(
                //     user.surname,
                //     style: Theme.of(context).textTheme.bodySmall,
                //     textAlign: TextAlign.center,
                //     maxLines: 1,
                //     overflow: TextOverflow.ellipsis,
                //   ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// TODO: Gerekli diğer sayfaların importlarını ve sınıflarını ekleyin
// (BildirimlerSayfasi, HaritaSayfasi, ProfilSayfasi, AyarlarSayfasi, UserProfileScreen, AuthScreen vb.)