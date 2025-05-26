// lib/main.dart
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Projenizdeki doğru yolları kullandığınızdan emin olun
import 'profile/profile_screen.dart';
// import 'services/database_helper.dart'; // Eğer doğrudan main'de kullanılmıyorsa ve başka yerde başlatılıyorsa kaldırılabilir.
import 'auth_wrapper.dart';
import 'auth/auth_screen.dart';
import 'map/map_screen.dart';
import 'pages/home_page.dart';
import 'screens/firmalar_sayfasi.dart';
import 'anasayfa.dart';
// Admin paneli için import. Dosya yolunu kendi projenize göre ayarlayın.
// Örnek: import 'admin/admin_panel_screen.dart';
// VEYA projenizin kök lib dizinindeyse:
import 'admin/admin_panel_screen.dart'; // Eğer lib/admin_panel_screen.dart ise

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  // DatabaseHelper.instance.database; // Eğer global erişim içinse veya başka yerde başlatılıyorsa bu satır gözden geçirilebilir.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vigo Kurye Asistanı',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthWrapper(),
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/main_app': (context) => const MyHomePage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  int? _currentUserId;
  String? _currentUserAccountStatus; // SharedPreferences'ten okunan hesap durumu
  bool _isLoadingUserData = true;

  List<Widget> _pages = [];
  List<NavigationDestination> _navigationDestinations = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUserDataAndSetupUI();
  }

  Future<void> _loadCurrentUserDataAndSetupUI() async {
    if (!mounted) return;

    setState(() {
      _isLoadingUserData = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final userIdFromPrefs = prefs.getInt('loggedInUserId');
    // DOĞRU ANAHTAR KULLANILIYOR: 'loggedInUserAccountStatus'
    final accountStatusFromPrefs = prefs.getString('loggedInUserAccountStatus');

    print('--------------------------------------------------');
    print('MyHomePage - Veri Yükleme Başladı (initState)');
    print('MyHomePage - SharedPreferences\'ten okunan loggedInUserId: $userIdFromPrefs');
    print('MyHomePage - SharedPreferences\'ten okunan (loggedInUserAccountStatus): $accountStatusFromPrefs');
    print('--------------------------------------------------');

    if (!mounted) return;

    if (userIdFromPrefs == null) {
      print('UYARI: MyHomePage - Kullanıcı ID bulunamadı (loggedInUserId null). Bazı özellikler çalışmayabilir veya giriş ekranına yönlendirilmeli.');
      // Gerekirse burada giriş ekranına yönlendirme yapılabilir:
      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //   if (mounted) Navigator.of(context).pushReplacementNamed('/auth');
      // });
      // setState(() { _isLoadingUserData = false; }); // Yüklemeyi bitir, yönlendirme olacaksa.
      // return;
    }

    setState(() {
      _currentUserId = userIdFromPrefs;
      _currentUserAccountStatus = accountStatusFromPrefs;
      _setupPagesAndDestinations(); // Sayfaları ve navigasyon barlarını oluştur
      _isLoadingUserData = false;
    });
  }

  bool get _isAdmin {
    // MySQL'deki 'hesap_durumu' ve dolayısıyla SP'ye kaydedilen
    // 'loggedInUserAccountStatus' değerinin 'Admin' (büyük A ile) olmasına bağlıdır.
    final isAdminResult = _currentUserAccountStatus == 'Admin';
    print('MyHomePage - _isAdmin kontrolü: _currentUserAccountStatus="$_currentUserAccountStatus" (Okunan Anahtar: loggedInUserAccountStatus), Sonuç: $isAdminResult');
    return isAdminResult;
    // Büyük/küçük harf duyarsız kontrol isteniyorsa:
    // return _currentUserAccountStatus?.toLowerCase() == 'admin';
  }

  void _setupPagesAndDestinations() {
    final List<Widget> tempPages = [];
    final List<NavigationDestination> tempDestinations = [];

    tempPages.addAll([
      const Anasayfa(),
      if (_currentUserId != null)
        MapScreen(currentUserId: _currentUserId!)
      else
        const Center(child: Text('Harita için kullanıcı girişi gerekli.')), // Kullanıcı ID yoksa gösterilecek placeholder
      const FirmalarSayfasi(),
      const HomePage(),
      const ProfileScreen(),
    ]);

    tempDestinations.addAll([
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Anasayfa',
      ),
      const NavigationDestination(
        icon: Icon(Icons.map_outlined),
        selectedIcon: Icon(Icons.map),
        label: 'Harita',
      ),
      const NavigationDestination(
        icon: Icon(Icons.business_outlined),
        selectedIcon: Icon(Icons.business),
        label: 'Firmalar',
      ),
      const NavigationDestination(
        icon: Icon(Icons.article_outlined),
        selectedIcon: Icon(Icons.article),
        label: 'Haber',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Profil',
      ),
    ]);

    print('MyHomePage - _setupPagesAndDestinations - _isAdmin: $_isAdmin');
    if (_isAdmin) {
      print('MyHomePage - Admin olarak algılandı. Yönetici sekmesi ekleniyor.');
      // AdminPanelScreen'i projenize eklediğinizden ve doğru import ettiğinizden emin olun
      // Eğer lib/admin/admin_panel_screen.dart ise import 'admin/admin_panel_screen.dart'; olmalı.
      tempPages.add(const AdminPanelScreen());
      tempDestinations.add(
        const NavigationDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings),
          label: 'Yönetici',
        ),
      );
    } else {
      print('MyHomePage - Admin olarak algılanmadı. Yönetici sekmesi eklenmeyecek.');
    }

    if (!mounted) return;
    setState(() {
      _pages = List.unmodifiable(tempPages);
      _navigationDestinations = List.unmodifiable(tempDestinations);
      if (_selectedIndex >= _pages.length && _pages.isNotEmpty) {
        _selectedIndex = _pages.length - 1;
      } else if (_pages.isEmpty && _selectedIndex !=0) {
        _selectedIndex = 0; // Eğer hiç sayfa yoksa (beklenmedik durum)
      }
    });
  }

  void _onItemTapped(int index) {
    if (!mounted) return;
    if (index >= 0 && index < _pages.length) {
      setState(() {
        _selectedIndex = index;
      });
    } else {
      print("UYARI: Geçersiz navigasyon index'i: $index. Sayfa sayısı: ${_pages.length}");
      // Güvenlik için, eğer index hatalıysa ve sayfalar varsa ilk sayfaya resetle
      if(_pages.isNotEmpty) {
        setState(() {
          _selectedIndex = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUserData) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_pages.isEmpty && _navigationDestinations.isEmpty && !_isLoadingUserData) {
      print("HATA: Sayfalar veya navigasyon hedefleri yüklenemedi. _isLoadingUserData: $_isLoadingUserData");
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Sayfalar yüklenirken bir sorun oluştu."),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _loadCurrentUserDataAndSetupUI,
                child: const Text("Yeniden Dene"),
              )
            ],
          ),
        ),
      );
    }
    // Eğer sadece _pages boşsa (ama navigasyon hedefleri olabilir)
    // veya seçili index _pages sınırları dışındaysa, bu bir hata durumudur.
    // Ancak _onItemTapped ve _setupPagesAndDestinations içindeki kontroller bunu minimize etmeli.

    return Scaffold(
      body: (_pages.isNotEmpty && _selectedIndex < _pages.length)
          ? IndexedStack(
        index: _selectedIndex,
        children: _pages,
      )
          : Center( // _pages boşsa veya _selectedIndex hatalıysa gösterilecek fallback
        child: _isLoadingUserData
            ? const CircularProgressIndicator()
            : const Text("Sayfa içeriği yüklenemedi veya geçersiz sekme."),
      ),
      bottomNavigationBar: (_navigationDestinations.isNotEmpty)
          ? NavigationBar(
        selectedIndex: (_selectedIndex < _navigationDestinations.length && _selectedIndex >= 0)
            ? _selectedIndex
            : 0, // Geçerli bir index sağla
        onDestinationSelected: _onItemTapped,
        destinations: _navigationDestinations,
      )
          : null, // Navigasyon hedefleri yoksa barı gösterme
    );
  }
}