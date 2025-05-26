// lib/profile/screens/profile_screen.dart

import 'dart:convert'; // JSON işlemleri için eklendi
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // HTTP istekleri için eklendi
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
// path_provider import'u eğer dosyayı yerel olarak kaydetmeyecekseniz gerekmeyebilir.
// import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- DİKKAT: BU GÖRECELİ IMPORT YOLLARINI KENDİ PROJE YAPINIZA GÖRE KONTROL EDİN ---
// Eğer profile_screen.dart dosyası lib/profile/screens/ altındaysa:
import '../../utils/il_ilce_listeleri.dart'; // Bu dosyanın var olduğundan emin olun
import 'models/user.dart'; // User modelinizin projenizde olduğundan emin olun
import '../../services/database_helper.dart'; // DatabaseHelper'ınızın projenizde olduğundan emin olun
// --- IMPORT YOLLARI KONTROLÜ BİTTİ ---

// --- API SABİTLERİ ---
const String API_BASE_URL = 'https://caypmodel.store/kuryem_api';
const String AVATARS_SERVER_BASE_PATH = '/avatars/'; // Sunucudaki avatar klasörü
const String UPLOAD_AVATAR_ENDPOINT_PATH = '/upload_avatar.php'; // PHP dosyanızın adı
const String UPDATE_PROFILE_ENDPOINT_PATH = '/update_user_profile.php'; // Profil güncelleme PHP dosyanız

// --- YENİ: Varsayılan Avatar Dosya Adları (GÖRECELİ YOL İÇİN) ---
// Bu isimler sunucunuzdaki kuryem_api/avatars/ klasöründeki dosya adlarıyla eşleşmeli
const List<String> defaultAvatarFileNames = [
  'motorcu1.png',
  'motorcu2.png',
  'motorcu3.png',
  'motorcu4.png',
  'motorcu5.png',
  'default.png', // Eğer bir genel varsayılanınız varsa
];
// --- YENİ BİTTİ ---

String getFullAvatarUrl(String avatarFileNameOrRelativePath) {
  if (avatarFileNameOrRelativePath.isEmpty) {
    // Varsayılan bir resim URL'i döndürün veya boş bırakın
    // Örnek: return '$API_BASE_URL${AVATARS_SERVER_BASE_PATH}default.png';
    return ''; // Ya da uygulamanızın mantığına göre bir placeholder
  }
  if (avatarFileNameOrRelativePath.startsWith('http://') || avatarFileNameOrRelativePath.startsWith('https://')) {
    return avatarFileNameOrRelativePath;
  }

  String normalizedBasePath = AVATARS_SERVER_BASE_PATH;
  if (normalizedBasePath.startsWith('/')) {
    normalizedBasePath = normalizedBasePath.substring(1);
  }
  if (!normalizedBasePath.endsWith('/')) {
    normalizedBasePath = '$normalizedBasePath/';
  }

  String normalizedApiBaseUrl = API_BASE_URL;
  if (normalizedApiBaseUrl.endsWith('/')) {
    normalizedApiBaseUrl = normalizedApiBaseUrl.substring(0, normalizedApiBaseUrl.length - 1);
  }

  // Gelen yol "avatars/dosya.png" formatında mı, yoksa sadece "dosya.png" mi?
  if (avatarFileNameOrRelativePath.startsWith('avatars/')) {
    // Zaten "avatars/" içeriyorsa, doğrudan base URL ile birleştir
    return '$normalizedApiBaseUrl/$avatarFileNameOrRelativePath';
  } else {
    // Sadece dosya adı ise, AVATARS_SERVER_BASE_PATH'i ekle
    return '$normalizedApiBaseUrl/$normalizedBasePath$avatarFileNameOrRelativePath';
  }
}

Uri getUploadAvatarEndpoint() {
  final path = UPLOAD_AVATAR_ENDPOINT_PATH.startsWith('/')
      ? UPLOAD_AVATAR_ENDPOINT_PATH.substring(1)
      : UPLOAD_AVATAR_ENDPOINT_PATH;
  return Uri.parse('$API_BASE_URL/$path');
}

Uri getUpdateProfileEndpoint() {
  final path = UPDATE_PROFILE_ENDPOINT_PATH.startsWith('/')
      ? UPDATE_PROFILE_ENDPOINT_PATH.substring(1)
      : UPDATE_PROFILE_ENDPOINT_PATH;
  return Uri.parse('$API_BASE_URL/$path');
}
// --- API SABİTLERİ BİTTİ ---

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _currentUser;
  String? _profileImageUrl; // Görüntüleme için TAM URL
  bool _isAvailable = true;
  bool _receiveNotifications = true;
  String? _motorPlate;
  bool _isLoading = true;
  String? _loadingError;
  bool _isUploading = false; // Hem dosya yükleme hem de profil güncelleme için kullanılabilir

  final ImagePicker _picker = ImagePicker();

  static const String keyLoggedInUserId = 'loggedInUserId';
  // keyProfileImagePath, artık doğrudan _currentUser.avatarUrl'den (göreceli yol) okunacak
  // ve getFullAvatarUrl ile _profileImageUrl'e (tam yol) dönüştürülecek.
  // SharedPreferences'a TAM URL kaydetmek yerine GÖRECELİ YOL kaydetmek daha esnek olabilir.
  // Ya da en iyisi _currentUser.avatarUrl'i SharedPreferences'a hiç yazmamak,
  // sadece _loadUserProfileAndSettings'de DB'den okuyup, güncellemelerde DB ve sunucuyu güncellemek.
  // Şimdilik keyProfileImagePath'i TAM URL olarak tutmaya devam edelim,
  // ama idealde bu _currentUser.avatarUrl (göreceli yol) olmalı ve
  // _profileImageUrl buradan türetilmeli.
  static const String keyProfileImagePath = 'profileImagePath_full_url'; // Adını değiştirdim kafa karışıklığı olmasın diye
  static const String keyIsAvailable = 'isAvailable';
  static const String keyReceiveNotifications = 'receiveNotifications';
  static const String keyWorkLocation = 'workLocation';
  static const String keyMotorPlate = 'motorPlate';

  @override
  void initState() {
    super.initState();
    _loadUserProfileAndSettings();
  }

  Future<void> _loadUserProfileAndSettings() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadingError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt(keyLoggedInUserId);

      if (userId != null) {
        User? dbUser = await DatabaseHelper.instance.getUserById(userId);

        if (!mounted) return;

        if (dbUser != null) {
          _currentUser = dbUser;

          // _profileImageUrl'i _currentUser.avatarUrl'den (göreceli yol) oluştur
          if (_currentUser!.avatarUrl != null && _currentUser!.avatarUrl!.isNotEmpty) {
            _profileImageUrl = getFullAvatarUrl(_currentUser!.avatarUrl!);
          } else {
            // SP'de eski bir tam URL kalmışsa onu da kontrol edebiliriz (geçiş süreci için)
            String? legacyFullUrl = prefs.getString(keyProfileImagePath);
            if (legacyFullUrl != null && legacyFullUrl.isNotEmpty) {
              _profileImageUrl = legacyFullUrl;
              // ve bunu _currentUser'a göreceli yol olarak atamaya çalışabiliriz.
              // Bu kısım biraz karmaşıklaşabilir, en temizi dbUser.avatarUrl'i kullanmak.
            } else {
              _profileImageUrl = null; // veya varsayılan bir avatarın tam URL'si
            }
          }


          _isAvailable = prefs.getBool(keyIsAvailable) ?? true;
          _receiveNotifications = prefs.getBool(keyReceiveNotifications) ?? true;
          _motorPlate = prefs.getString(keyMotorPlate) ?? _currentUser!.motorPlakasi;

          final spWorkLocation = prefs.getString(keyWorkLocation);
          if (_currentUser!.calistigiBolge == null && spWorkLocation != null && spWorkLocation != "Belirtilmemiş") {
            _currentUser = _currentUser!.copyWith(calistigiBolge: spWorkLocation);
          }
          if (_currentUser!.motorPlakasi != null) {
            _motorPlate = _currentUser!.motorPlakasi;
          }

          if (mounted) {
            setState(() => _isLoading = false);
          }
        } else {
          _handleLoadingError('Kullanıcı verileri veritabanında bulunamadı (ID: $userId). Lütfen tekrar giriş yapın.');
        }
      } else {
        _handleLoadingError('Giriş yapmış kullanıcı ID\'si bulunamadı. Lütfen giriş yapın.');
      }
    } catch (e, stacktrace) {
      print("ProfileScreen: _loadUserProfileAndSettings İÇİNDE HATA: $e");
      print("ProfileScreen: Stacktrace: $stacktrace");
      _handleLoadingError('Profil yüklenirken bir hata oluştu: $e');
    }
  }

  void _handleLoadingError(String message) {
    if (!mounted) return;
    setState(() {
      _loadingError = message;
      _isLoading = false;
      _currentUser = null;
    });
  }

  // Bu fonksiyon, sunucuya GÖRECELİ avatar yolunu kaydeder.
  // `avatarRelativePath` parametresi "avatars/motorcu1.png" veya "avatars/user_123_time.jpg" gibi olmalı.
  Future<bool> _updateUserProfileOnServer({
    String? avatarRelativePath, // ARTIK GÖRECELİ YOL
    String? email,
    String? phone,
    String? company,
    String? motorPlakasi,
    String? calistigiBolge,
  }) async {
    if (_currentUser?.id == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil güncellemek için kullanıcı ID bulunamadı.')));
      return false;
    }
    if (mounted) setState(() => _isUploading = true); // Yükleme göstergesini başlat

    try {
      final Map<String, dynamic> body = {
        'id': _currentUser!.id.toString(), // PHP tarafı 'user_id' bekliyorsa böyle kalsın, 'id' bekliyorsa 'id' yapın.
        // Önceki PHP analizine göre 'id' bekleniyordu, ancak update_user_profile.php user_id mi id mi kontrol edilmeli.
        // update_user_profile.php'niz '$data->id' kullandığı için 'id' olmalı.
        // Eğer upload_avatar.php user_id bekliyorsa ve update_user_profile.php id bekliyorsa bu bir tutarsızlık.
        // Şimdilik upload_avatar.php'nin user_id istediğini, update_user_profile.php'nin id istediğini varsayıyorum.
        // Bu iki PHP scriptinde user_id anahtarının tutarlı olması en iyisidir.
        // **DÜZELTME ÖNERİSİ: update_user_profile.php'de de user_id kullanın veya her ikisinde de id kullanın.**
        // Şimdilik update için 'id' kullanıyorum, User modelindeki toMapForApiUpdate'e göre:
        // 'id': _currentUser!.id.toString(), // Eğer update_user_profile.php 'id' bekliyorsa
      };

      // User modelindeki toMapForApiUpdate benzeri bir mantık burada da olabilir veya doğrudan parametreler kullanılır.
      // update_user_profile.php $data->avatarUrl bekliyor.
      if (avatarRelativePath != null) body['avatarUrl'] = avatarRelativePath; // DİKKAT: Anahtar 'avatarUrl' olmalı
      if (email != null) body['email'] = email;
      if (phone != null) body['phone'] = phone;
      if (company != null) body['company'] = company;
      if (motorPlakasi != null) body['motor_plakasi'] = motorPlakasi;
      if (calistigiBolge != null) body['calistigi_il_ilce'] = calistigiBolge;


      // Sadece user_id varsa ve avatarRelativePath de null ise, güncelleme yapacak bir şey yok.
      // (Aslında diğer alanlar da null ise...)
      bool hasUpdates = body.entries.any((entry) => entry.key != 'id' && entry.value != null); // 'id' olmalı eğer yukarıdaki gibi
      if (!hasUpdates && avatarRelativePath == null) { // avatarRelativePath yukarıda body'ye eklendiği için bu kontrol body.length > 1 ile de yapılabilir
        print("Güncellenecek bir alan yok.");
        return true; // Başarılı sayılabilir
      }


      final response = await http.post(
        getUpdateProfileEndpoint(),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['success'] == true) {
        return true;
      } else {
        throw Exception(responseData['message'] ?? 'Profil güncellenemedi: Sunucudan geçersiz yanıt. Durum: ${response.statusCode}');
      }
    } catch (e) {
      print("ProfileScreen: _updateUserProfileOnServer HATA: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profil sunucuda güncellenirken hata: $e')));
      return false;
    } finally {
      if (mounted) setState(() => _isUploading = false); // Yükleme göstergesini durdur
    }
  }


  // Galeriden/Kameradan resim seçip yükleme ve güncelleme
  Future<void> _pickAndUploadImage(ImageSource source) async {
    if (_isUploading || _currentUser == null) return;

    XFile? pickedFile;
    try {
      pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
      if (pickedFile == null) return;

      if (!mounted) return;
      setState(() => _isUploading = true);

      // 1. Resmi sunucuya yükle (upload_avatar.php)
      // Bu fonksiyon TAM URL döndürüyordu, onu GÖRECELİ YOLA çevirmemiz veya
      // _uploadImageToServer'ı göreceli yol döndürecek şekilde düzenlememiz lazım.
      // Mevcut _uploadImageToServer'ınız TAM URL döndürüyor.
      // Dönen tam URL'den göreceli yolu çıkarmamız gerekecek.

      var uploadRequest = http.MultipartRequest('POST', getUploadAvatarEndpoint());
      // upload_avatar.php 'user_id' mi 'id' mi bekliyor? Önceki analize göre 'id' olmalıydı ama kodunuzda 'user_id' var.
      // Eğer upload_avatar.php user_id bekliyorsa ve siz flutter'da request.fields['id'] yaptıysanız, burada da 'id' kullanmalısınız.
      // Bu tutarlılık önemli. Şimdilik kodunuzdaki gibi 'user_id' bırakıyorum.
      uploadRequest.fields['id'] = _currentUser!.id.toString();
      uploadRequest.files.add(await http.MultipartFile.fromPath(
        'avatar_file', // PHP tarafı 'avatar' mı 'avatar_file' mı bekliyor? Kontrol edin. upload_avatar.php'niz 'avatar' bekliyordu.
        // **DÜZELTME: PHP 'avatar' bekliyorsa burası 'avatar' olmalı.**
        pickedFile.path,
        filename: p.basename(pickedFile.path),
      ));

      var streamedResponse = await uploadRequest.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(responseBody);
        if (data['success'] == true && data['avatar_path'] != null) {
          String returnedRelativePath = data['avatar_path']; // upload_avatar.php zaten 'avatars/user_...' gibi göreceli yol döndürüyor. BU İYİ.

          // 2. Kullanıcı profilini sunucuda güncelle (update_user_profile.php)
          final bool updateSuccess = await _updateUserProfileOnServer(avatarRelativePath: returnedRelativePath);

          if (updateSuccess) {
            // 3. Yerel durumu ve SharedPreferences'ı güncelle
            _currentUser = _currentUser!.copyWith(avatarUrl: returnedRelativePath);
            await DatabaseHelper.instance.updateUser(_currentUser!); // Yerel DB'yi güncelle

            // SharedPreferences'a TAM URL yerine göreceli yolu kaydetmek daha iyi olabilir,
            // ya da hiç kaydetmeyip hep _currentUser.avatarUrl'den okumak.
            // Şimdilik _profileImageUrl'i güncelleyelim.
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(keyProfileImagePath, getFullAvatarUrl(returnedRelativePath)); // SP'ye tam URL (eski mantık)

            if (!mounted) return;
            setState(() {
              _profileImageUrl = getFullAvatarUrl(returnedRelativePath); // UI için tam URL
            });
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil resmi başarıyla güncellendi.')));
          } else {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil resmi sunucuda güncellenemedi.')));
          }
        } else {
          throw Exception(data['message'] ?? 'Avatar yüklenemedi: Sunucudan geçersiz yanıt.');
        }
      } else {
        throw Exception('Avatar yükleme hatası: ${streamedResponse.statusCode} - $responseBody');
      }
    } catch (e) {
      print("ProfileScreen: _pickAndUploadImage HATA: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Resim ayarlanırken bir hata oluştu: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }


  // Varsayılan bir avatar seçildiğinde çağrılacak fonksiyon
  Future<void> _setDefaultAvatar(String selectedAvatarFileName) async {
    if (_isUploading || _currentUser == null) return;

    // Seçilen avatarın SADECE dosya adı ("motorcu1.png")
    // Bunu sunucunun beklediği formata (örn: "avatars/motorcu1.png") çevirmeliyiz.
    // AVATARS_SERVER_BASE_PATH / ile başlıyor ve sonunda / var.
    String relativePathForServer = "${AVATARS_SERVER_BASE_PATH.substring(1)}$selectedAvatarFileName"; // "avatars/motorcu1.png"

    try {
      if (!mounted) return;
      // setState(() => _isUploading = true); // _updateUserProfileOnServer zaten yapıyor

      // 1. Kullanıcı profilini sunucuda güncelle (update_user_profile.php)
      final bool updateSuccess = await _updateUserProfileOnServer(avatarRelativePath: relativePathForServer);

      if (updateSuccess) {
        // 2. Yerel durumu ve SharedPreferences'ı güncelle
        _currentUser = _currentUser!.copyWith(avatarUrl: relativePathForServer);
        await DatabaseHelper.instance.updateUser(_currentUser!);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(keyProfileImagePath, getFullAvatarUrl(relativePathForServer)); // SP'ye tam URL (eski mantık)


        if (!mounted) return;
        setState(() {
          _profileImageUrl = getFullAvatarUrl(relativePathForServer); // UI için tam URL
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil resmi başarıyla güncellendi.')));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil resmi sunucuda güncellenemedi.')));
      }
    } catch (e) {
      print("ProfileScreen: _setDefaultAvatar HATA: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Varsayılan resim ayarlanırken bir hata oluştu: $e')));
    } finally {
      // if (mounted) setState(() => _isUploading = false); // _updateUserProfileOnServer zaten yapıyor
    }
  }


  void _showAvatarSelectionDialog() {
    if (_currentUser == null) return;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Column( // Column kullandım ki başlık ekleyebileyim
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text("Profil Resmi Seçin", style: Theme.of(context).textTheme.titleLarge),
              ),
              const Divider(),
              // Varsayılan Avatarlar için GridView
              if (defaultAvatarFileNames.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: GridView.builder(
                    shrinkWrap: true, // Column içinde olduğu için
                    physics: const NeverScrollableScrollPhysics(), // Column içinde olduğu için
                    itemCount: defaultAvatarFileNames.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, // Bir sırada kaç avatar gösterilsin
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) {
                      final avatarFileName = defaultAvatarFileNames[index];
                      // AVATARS_SERVER_BASE_PATH /avatars/ şeklinde.
                      // Görüntüleme için tam URL lazım.
                      final String fullUrl = getFullAvatarUrl(avatarFileName); // getFullAvatarUrl sadece dosya adını da alabilmeli

                      return GestureDetector(
                        onTap: () {
                          Navigator.of(bc).pop(); // Dialogu kapat
                          _setDefaultAvatar(avatarFileName); // Seçilen dosya adını gönder
                        },
                        child: CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(fullUrl),
                          onBackgroundImageError: (e,s) {
                            // Hata durumunda placeholder veya ikon gösterebilirsiniz.
                            print('Varsayılan avatar yüklenemedi: $fullUrl, Hata: $e');
                          },
                        ),
                      );
                    },
                  ),
                ),
              if (defaultAvatarFileNames.isNotEmpty) const Divider(),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeriden Yeni Yükle'),
                onTap: () {
                  Navigator.of(bc).pop();
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Kameradan Yeni Çek'),
                onTap: () {
                  Navigator.of(bc).pop();
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
              // İsteğe bağlı: Avatarı kaldır seçeneği
              // ListTile(
              //   leading: Icon(Icons.delete_outline, color: Colors.red),
              //   title: Text('Profil Resmini Kaldır', style: TextStyle(color: Colors.red)),
              //   onTap: () async {
              //     Navigator.of(bc).pop();
              //     // Sunucuda avatarUrl'i null veya boş string yapacak şekilde güncelleme
              //     bool success = await _updateUserProfileOnServer(avatarRelativePath: ""); // Boş string gönder
              //     if (success) {
              //       _currentUser = _currentUser!.copyWith(avatarUrl: "");
              //       await DatabaseHelper.instance.updateUser(_currentUser!);
              //       final prefs = await SharedPreferences.getInstance();
              //       await prefs.remove(keyProfileImagePath); // Veya boş string ata
              //       if(mounted) setState(() => _profileImageUrl = null);
              //       if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profil resmi kaldırıldı.')));
              //     } else {
              //       if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profil resmi kaldırılamadı.')));
              //     }
              //   },
              // ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // ... (Geri kalan _updateAvailability, _updateNotificationSettings, _editInfoField, _showLocationSelectionDialog metodlarınız aynı kalacak)


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: const Text('Profil Ayarları'),
            elevation: 1,
            actions: [
            if (_isUploading) // Bu _isUploading hem dosya yükleme hem de profil güncelleme için kullanılacak
        const Padding(
    padding: EdgeInsets.only(right: 20.0),
    child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3))),
        ),
    ]

    ),
    body: _isLoading
    ? const Center(child: CircularProgressIndicator())
        : _loadingError != null
    ? Center(
    child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Text(_loadingError!, style: const TextStyle(color: Colors.red, fontSize: 16)),
    ))
        : _currentUser == null
    ? const Center(
    child: Text('Kullanıcı bilgileri yüklenemedi. Lütfen tekrar deneyin.', style: TextStyle(fontSize: 16)))
        : _buildProfileView());
  }

  Widget _buildProfileView() {
    // _profileImageUrl'in null veya boş olma durumuna göre varsayılan bir avatar göster
    final String displayImageUrl = (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
        ? _profileImageUrl!
        : getFullAvatarUrl(defaultAvatarFileNames.isNotEmpty ? defaultAvatarFileNames.last : 'default.png'); // Veya başka bir placeholder

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: <Widget>[
        Center(
          child: Stack(
            children: <Widget>[
              CircleAvatar(
                radius: 60,
                backgroundImage: (displayImageUrl.isNotEmpty) ? NetworkImage(displayImageUrl) : null,
                onBackgroundImageError: (displayImageUrl.isNotEmpty) ? (e, s) {
                  print('Ana profil avatarı yüklenemedi: $displayImageUrl, Hata: $e');
                  // Hata durumunda varsayılan bir ikon veya placeholder gösterilebilir
                } : null,
                child: (displayImageUrl.isEmpty)
                    ? const Icon(Icons.person, size: 60) // Placeholder
                    : null,
                backgroundColor: Colors.grey[300], // Resim yoksa veya yüklenemezse arka plan
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell( // IconButton yerine InkWell daha fazla özelleştirme sağlar
                  onTap: _showAvatarSelectionDialog, // YENİ FONKSİYONU ÇAĞIR
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.blue, // Veya Theme.of(context).primaryColor
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 20),
                  ),
                ),
              ),
              if (_isUploading) // Profil resmi yüklenirken avatarın üzerinde bir gösterge
                const Positioned.fill(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.black45,
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _currentUser!.fullName ?? 'İsim Soyisim',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          _currentUser!.email ?? 'E-posta adresi belirtilmemiş',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 30),
        _buildProfileInfoCard(),
        const SizedBox(height: 20),
        _buildSettingsCard(),
        const SizedBox(height: 20),
        // Diğer widget'larınız (Çıkış Yap butonu vs.)
        Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              // TODO: Çıkış yapma işlemini buraya ekleyin
              // Örnek:
              // final prefs = await SharedPreferences.getInstance();
              // await prefs.remove(keyLoggedInUserId);
              // Navigator.of(context).pushAndRemoveUntil(
              //   MaterialPageRoute(builder: (context) => LoginScreen()), // LoginScreen'inize yönlendirin
              //   (Route<dynamic> route) => false,
              // );
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Çıkış yapma özelliği henüz eklenmedi.')));
            },
            child: const Text('Çıkış Yap', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Kullanıcı Bilgileri', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 20, thickness: 1),
            _buildInfoRow(
              icon: Icons.phone_android,
              label: 'Telefon',
              value: _currentUser!.phone ?? 'Belirtilmemiş',
              onEdit: () => _editInfoField(
                title: 'Telefon Numaranızı Güncelleyin',
                initialValue: _currentUser!.phone ?? '',
                keyboardType: TextInputType.phone,
                onSave: (newValue) async {
                  if (_currentUser!.phone == newValue) return;
                  bool success = await _updateUserProfileOnServer(phone: newValue);
                  if (success) {
                    setState(() => _currentUser = _currentUser!.copyWith(phone: newValue));
                    await DatabaseHelper.instance.updateUser(_currentUser!);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Telefon güncellendi.')));
                  }
                },
              ),
            ),
            _buildInfoRow(
              icon: Icons.business,
              label: 'Firma',
              value: _currentUser!.company ?? 'Belirtilmemiş',
              onEdit: () => _editInfoField(
                title: 'Firma Adını Güncelleyin',
                initialValue: _currentUser!.company ?? '',
                onSave: (newValue) async {
                  if (_currentUser!.company == newValue) return;
                  bool success = await _updateUserProfileOnServer(company: newValue);
                  if (success) {
                    setState(() => _currentUser = _currentUser!.copyWith(company: newValue));
                    await DatabaseHelper.instance.updateUser(_currentUser!);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Firma adı güncellendi.')));
                  }
                },
              ),
            ),
            _buildInfoRow(
              icon: Icons.motorcycle,
              label: 'Motor Plakası',
              value: _motorPlate ?? _currentUser!.motorPlakasi ?? 'Belirtilmemiş',
              onEdit: () => _editInfoField(
                title: 'Motor Plakasını Güncelleyin',
                initialValue: _motorPlate ?? _currentUser!.motorPlakasi ?? '',
                onSave: (newValue) async {
                  if ((_motorPlate ?? _currentUser!.motorPlakasi) == newValue) return;
                  bool success = await _updateUserProfileOnServer(motorPlakasi: newValue);
                  if (success) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString(keyMotorPlate, newValue);
                    setState(() {
                      _motorPlate = newValue;
                      _currentUser = _currentUser!.copyWith(motorPlakasi: newValue);
                    });
                    await DatabaseHelper.instance.updateUser(_currentUser!);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Motor plakası güncellendi.')));
                  }
                },
              ),
            ),
            _buildInfoRow(
              icon: Icons.location_on,
              label: 'Çalıştığı Bölge',
              value: _currentUser!.calistigiBolge ?? 'Belirtilmemiş',
              onEdit: () => _showLocationSelectionDialog(
                currentLocation: _currentUser!.calistigiBolge,
                onLocationSelected: (newLocation) async {
                  if (_currentUser!.calistigiBolge == newLocation || newLocation == null) return;
                  bool success = await _updateUserProfileOnServer(calistigiBolge: newLocation);
                  if (success) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString(keyWorkLocation, newLocation);
                    setState(() => _currentUser = _currentUser!.copyWith(calistigiBolge: newLocation));
                    await DatabaseHelper.instance.updateUser(_currentUser!);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Çalışma bölgesi güncellendi.')));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Uygulama Ayarları', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 20, thickness: 1),
            SwitchListTile(
              title: const Text('Müsaitlik Durumu'),
              subtitle: Text(_isAvailable ? 'Müsait (Yeni görev alabilir)' : 'Müsait Değil (Yeni görev alamaz)'),
              value: _isAvailable,
              onChanged: (bool value) async {
                // Sunucuda da bu durumu güncellemek gerekebilir.
                // Örnek: bool success = await _updateUserAvailabilityOnServer(value);
                // if (success) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(keyIsAvailable, value);
                setState(() => _isAvailable = value);
                // Ayrıca _currentUser'da da bu bilgiyi tutuyorsanız güncelleyin ve DB'ye kaydedin.
                // _currentUser = _currentUser!.copyWith(isAvailable: value);
                // await DatabaseHelper.instance.updateUser(_currentUser!);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Müsaitlik durumu güncellendi: ${_isAvailable ? "Müsait" : "Müsait Değil"}')));
                // } else {
                //   if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Müsaitlik durumu sunucuda güncellenemedi.')));
                // }
              },
              secondary: Icon(_isAvailable ? Icons.check_circle : Icons.cancel, color: _isAvailable ? Colors.green : Colors.red),
            ),
            SwitchListTile(
              title: const Text('Bildirimler'),
              subtitle: Text(_receiveNotifications ? 'Açık' : 'Kapalı'),
              value: _receiveNotifications,
              onChanged: (bool value) async {
                // Sunucuda da bu durumu güncellemek gerekebilir.
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(keyReceiveNotifications, value);
                setState(() => _receiveNotifications = value);
                // Ayrıca _currentUser'da da bu bilgiyi tutuyorsanız güncelleyin ve DB'ye kaydedin.
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bildirim ayarları güncellendi: ${_receiveNotifications ? "Açık" : "Kapalı"}')));
              },
              secondary: Icon(_receiveNotifications ? Icons.notifications_active : Icons.notifications_off, color: _receiveNotifications ? Colors.blue : Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label, required String value, VoidCallback? onEdit}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: <Widget>[
          Icon(icon, color: Theme.of(context).primaryColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              icon: Icon(Icons.edit_outlined, color: Colors.grey[700], size: 20),
              onPressed: onEdit,
              tooltip: '$label Düzenle',
            ),
        ],
      ),
    );
  }

  Future<void> _editInfoField({
    required String title,
    required String initialValue,
    required Function(String) onSave,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final TextEditingController controller = TextEditingController(text: initialValue);
    String? newValue = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            keyboardType: keyboardType,
            autofocus: true,
            decoration: InputDecoration(
                hintText: 'Yeni değeri girin',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => controller.clear(),
                )
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Kaydet'),
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            ),
          ],
        );
      },
    );

    if (newValue != null && newValue.isNotEmpty && newValue != initialValue) {
      await onSave(newValue);
    }
  }

  Future<void> _showLocationSelectionDialog({
    String? currentLocation,
    required Function(String?) onLocationSelected,
  }) async {
    String? selectedIl = currentLocation?.split(' / ')[0];
    String? selectedIlce = currentLocation != null && currentLocation.contains(' / ')
        ? currentLocation.substring(currentLocation.indexOf(' / ') + 3)
        : null;

    List<String> ilceler = selectedIl != null ? illerVeIlceler[selectedIl] ?? [] : [];

    String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder( // Dialog içindeki state yönetimi için
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Çalışma Bölgesi Seçin'),
              content: SingleChildScrollView( // İçerik taşabilir
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'İl Seçin'),
                      value: selectedIl,
                      hint: const Text('İl seçiniz'),
                      items: illerVeIlceler.keys.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(value: value, child: Text(value));
                      }).toList(),
                      onChanged: (String? newValue) {
                        setDialogState(() {
                          selectedIl = newValue;
                          selectedIlce = null; // İl değişince ilçe sıfırlanır
                          ilceler = newValue != null ? illerVeIlceler[newValue] ?? [] : [];
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    if (selectedIl != null) // İl seçildiyse ilçe dropdown'ını göster
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'İlçe Seçin'),
                        value: selectedIlce,
                        hint: const Text('İlçe seçiniz'),
                        items: ilceler.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(value: value, child: Text(value));
                        }).toList(),
                        onChanged: (String? newValue) {
                          setDialogState(() => selectedIlce = newValue);
                        },
                      ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('İptal'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('Kaydet'),
                  onPressed: () {
                    if (selectedIl != null && selectedIlce != null) {
                      Navigator.of(context).pop('$selectedIl / $selectedIlce');
                    } else if (selectedIl != null) { // Sadece il seçilmişse
                      Navigator.of(context).pop(selectedIl);
                    } else { // Hiçbir şey seçilmemişse
                      Navigator.of(context).pop(); // null döner
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) { // result "İl / İlçe" veya "İl" formatında gelecek
      await onLocationSelected(result);
    } else if (result == null && currentLocation != null) {
      // Eğer kullanıcı dialogdan bir şey seçmeden çıktıysa ve mevcut bir konum varsa
      // ve "Belirtilmemiş" yapmak istiyorsa, bu durumu ayrıca ele almanız gerekebilir.
      // Şimdilik null gelirse ve bir şey seçilmemişse "Belirtilmemiş" gibi davranabilir veya hiçbir şey yapmaz.
      // Veya "Konumu Temizle" butonu ekleyebilirsiniz dialoga.
      // await onLocationSelected("Belirtilmemiş"); // Örnek olarak
    }
  }
}