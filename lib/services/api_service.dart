// lib/services/api_service.dart

import 'package:flutter/foundation.dart'; // debugPrint için eklendi
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // SocketException ve File için eklendi
import 'dart:async'; // TimeoutException için eklendi
import 'package:shared_preferences/shared_preferences.dart'; // YENİ EKLENDİ

// Rapor modeli importu
import '../map/models/report_model.dart';

// UserLocation modelini import et
import '../map/models/user_location.dart';

// User modelini import et
import '../profile/models/user.dart'; // User sınıfının yolu

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  final String _baseUrl = "https://caypmodel.store/kuryem_api";

  // --- Yardımcı Metotlar ---
  Map<String, String> _getHeaders({bool sendContentTypeJson = true, String? token}) {
    final headers = <String, String>{};
    if (sendContentTypeJson) {
      headers['Content-Type'] = 'application/json; charset=UTF-8';
    } else {
      // Genellikle form verileri için veya bazı PHP backend'lerinin $_POST ile
      // daha kolay çalışması için kullanılır.
      headers['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8';
    }
    headers['Accept'] = 'application/json'; // API'nin her zaman JSON döndürdüğünü varsayıyoruz
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  dynamic _handleResponse(http.Response response, String operationName) {
    final String responseBody = utf8.decode(response.bodyBytes);

    if (kDebugMode) {
      final String responseForPrint = responseBody.length > 300
          ? "${responseBody.substring(0, 300)}..."
          : responseBody;
      debugPrint("ApiService ($operationName) - _handleResponse - Status: ${response.statusCode}, Body: $responseForPrint");
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (responseBody.isEmpty && response.statusCode == 204) { // No Content
        return {'success': true, 'message': '$operationName başarılı (İçerik Yok).'};
      }
      if (responseBody.isEmpty) {
        // Bu durum genellikle bir hata olmamalı, 204 ile ele alınmalıydı.
        // Ama yine de bir kontrol olarak kalabilir.
        throw ApiException('$operationName başarısız oldu: Sunucudan boş yanıt alındı (Durum: ${response.statusCode}).');
      }
      try {
        return jsonDecode(responseBody);
      } catch (e) {
        throw ApiException('$operationName yanıtı işlenemedi: Geçersiz JSON formatı. Hata: $e, Yanıt: $responseBody');
      }
    } else {
      String errorMessage = '$operationName başarısız oldu. Durum Kodu: ${response.statusCode}.';
      if (responseBody.isNotEmpty) {
        try {
          final errorData = jsonDecode(responseBody);
          if (errorData is Map && errorData.containsKey('message')) {
            errorMessage = errorData['message']?.toString() ?? errorMessage;
          } else if (errorData is Map && errorData.containsKey('error')) {
            // Bazı API'ler 'error' anahtarı kullanabilir
            errorMessage = errorData['error']?.toString() ?? errorMessage;
          } else {
            // Hata mesajı yoksa veya farklı formatta ise tüm body'yi ekle
            errorMessage += ' Detay: $responseBody';
          }
        } catch (_) {
          // JSON parse edilemezse ham body'yi ekle
          errorMessage += ' Detay (işlenemedi): $responseBody';
        }
      }
      if (response.statusCode == 401) {
        errorMessage = 'Yetkisiz erişim. Lütfen tekrar giriş yapın veya yetkilerinizi kontrol edin. ($operationName)';
      }
      // Diğer özel durum kodları burada ele alınabilir (403 Forbidden, 404 Not Found vb.)
      throw ApiException(errorMessage);
    }
  }

  String _handleError(dynamic e, String operationName) {
    if (kDebugMode) {
      debugPrint("ApiService ($operationName) - _handleError caught: $e");
    }
    if (e is TimeoutException) {
      return '$operationName zaman aşımına uğradı. İnternet bağlantınızı kontrol edin.';
    } else if (e is SocketException) {
      return '$operationName sırasında sunucuya bağlanılamadı. İnternet bağlantınızı veya sunucu durumunu kontrol edin.';
    } else if (e is http.ClientException) {
      // http paketinden gelen genel bir istemci hatası
      return '$operationName sırasında bir ağ sorunu oluştu: ${e.message}';
    } else if (e is ApiException) {
      return e.message; // Zaten özel bir mesaj içeriyor
    } else if (e is FormatException) {
      // Genellikle jsonDecode başarısız olduğunda veya geçersiz URL'de olur.
      // _handleResponse içinde jsonDecode hatası zaten ele alınıyor.
      return '$operationName sırasında veri formatı hatası: ${e.message}';
    }
    // Diğer bilinmeyen hatalar
    return '$operationName sırasında beklenmeyen bir hata oluştu. (${e.toString()})';
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken'); // Token anahtarınızın 'authToken' olduğunu varsayıyoruz
  }

  // --- Mevcut Kayıt (Register) işlemi ---
  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String surname,
    required String email,
    required String phone,
    required String company,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/register.php');
    const operationName = 'Kullanıcı Kaydı';
    final requestBodyMap = {
      'name': name,
      'surname': surname,
      'email': email,
      'phone': phone,
      'company': company,
      'password': password,
    };

    if (kDebugMode) {
      debugPrint("ApiService ($operationName) - Sending data: ${jsonEncode(requestBodyMap)}");
    }

    try {
      final response = await http.post(
        url,
        headers: _getHeaders(sendContentTypeJson: true), // Token gerektirmeyen istek
        body: jsonEncode(requestBodyMap),
      ).timeout(const Duration(seconds: 20));
      final responseData = _handleResponse(response, operationName) as Map<String, dynamic>;
      // API'nin 'success': true döndüğünü kontrol ediyoruz.
      if (responseData.containsKey('success') && responseData['success'] == true) {
        return responseData;
      } else {
        // success:false veya message yoksa genel bir hata mesajı
        final apiMessage = responseData['message']?.toString() ?? 'API tarafından $operationName başarısız (yanıt success:false veya mesaj eksik).';
        throw ApiException(apiMessage);
      }
    } catch (e) {
      final errorMessage = _handleError(e, operationName);
      throw ApiException(errorMessage);
    }
  }

  // --- Mevcut Giriş (Login) işlemi ---
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/login.php');
    const operationName = 'Kullanıcı Girişi';
    final requestBodyMap = {'email': email, 'password': password};

    if (kDebugMode) {
      debugPrint("ApiService ($operationName) - Sending data: ${jsonEncode(requestBodyMap)}");
    }

    try {
      final response = await http.post(
        url,
        headers: _getHeaders(sendContentTypeJson: true), // Token gerektirmeyen istek
        body: jsonEncode(requestBodyMap),
      ).timeout(const Duration(seconds: 20));
      final responseData = _handleResponse(response, operationName) as Map<String, dynamic>;
      if (responseData.containsKey('success') && responseData['success'] == true) {
        // Token'ı kaydetme UI tarafında yapılmalı.
        // Bu metod sadece API yanıtını döndürür.
        // UI'da: if (response['success'] == true && response.containsKey('token')) { prefs.setString('authToken', response['token']); }
        return responseData;
      } else {
        final apiMessage = responseData['message']?.toString() ?? 'API tarafından $operationName başarısız (yanıt success:false veya mesaj eksik).';
        throw ApiException(apiMessage);
      }
    } catch (e) {
      final errorMessage = _handleError(e, operationName);
      throw ApiException(errorMessage);
    }
  }

  // --- Rapor Metodları ---
  Future<List<Report>> getReports() async {
    final url = Uri.parse('$_baseUrl/get_reports.php');
    const operationName = 'Raporları Çekme';
    final token = await _getToken();

    if (kDebugMode) {
      debugPrint("ApiService ($operationName) - Requesting GET from $url. Token: ${token != null ? 'Var' : 'Yok'}");
    }
    try {
      final response = await http.get(
        url,
        // Genellikle GET istekleri için Content-Type göndermek gereksizdir,
        // ama _getHeaders token ekleme gibi başka şeyler de yapıyor.
        // sendContentTypeJson:false olabilir veya Accept: application/json yeterli olabilir.
        headers: _getHeaders(sendContentTypeJson: false, token: token),
      ).timeout(const Duration(seconds: 20));
      final dynamic responseData = _handleResponse(response, operationName);

      if (responseData is List) {
        if (responseData.isEmpty) return [];
        return responseData.map((reportJson) {
          try {
            return Report.fromJson(reportJson as Map<String, dynamic>);
          } catch (e) {
            if (kDebugMode) {
              debugPrint("ApiService ($operationName) - Error parsing report JSON: $e. JSON: $reportJson");
            }
            return null; // Hatalı veriyi atla
          }
        }).whereType<Report>().toList(); // null olanları filtrele
      } else if (responseData is Map<String, dynamic> && responseData.containsKey('success') && responseData['success'] == false) {
        // Bu durum _handleResponse tarafından zaten ele alınmalı, ama ekstra kontrol.
        throw ApiException(responseData['message']?.toString() ?? '$operationName başarısız: Beklenmeyen API yanıtı (success:false).');
      } else {
        throw ApiException('$operationName başarısız: Sunucudan beklenmeyen formatta yanıt alındı (Liste bekleniyordu, gelen: ${responseData.runtimeType}). Yanıt: $responseData');
      }
    } catch (e) {
      final errorMessage = _handleError(e, operationName);
      throw ApiException(errorMessage);
    }
  }

  Future<Map<String, dynamic>> addReport({
    required double latitude,
    required double longitude,
    required String reportType,
    required int userId, // API'niz token'dan user_id alıyorsa bu gereksiz olabilir.
    String? description,
  }) async {
    final url = Uri.parse('$_baseUrl/add_report.php');
    const operationName = 'Rapor Ekleme';
    final token = await _getToken();

    final Map<String, dynamic> requestBody = {
      'latitude': latitude,
      'longitude': longitude,
      'report_type': reportType,
      'user_id': userId,
    };
    if (description != null && description.isNotEmpty) {
      requestBody['description'] = description;
    }

    if (kDebugMode) {
      debugPrint("ApiService ($operationName) - Sending data: ${jsonEncode(requestBody)}. Token: ${token != null ? 'Var' : 'Yok'}");
    }

    try {
      final response = await http.post(
        url,
        headers: _getHeaders(sendContentTypeJson: true, token: token),
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 20));
      final responseData = _handleResponse(response, operationName) as Map<String, dynamic>;
      if (responseData.containsKey('success') && responseData['success'] == true) {
        return responseData;
      } else {
        final apiMessage = responseData['message']?.toString() ?? '$operationName başarısız oldu (API yanıtı success:false veya mesaj eksik).';
        throw ApiException(apiMessage);
      }
    } catch (e) {
      final errorMessage = _handleError(e, operationName);
      // Orijinal loglamanız:
      // if (kDebugMode) {
      //   debugPrint("ApiService ($operationName) - Caught exception in addReport: '$e'. Processed error message: '$errorMessage'");
      // }
      throw ApiException(errorMessage);
    }
  }

  Future<Map<String, dynamic>> deleteReport({
    required int reportId,
    required int currentUserId, // API'niz token'dan user_id alıyorsa bu gereksiz olabilir.
  }) async {
    final url = Uri.parse('$_baseUrl/delete_reports.php');
    const operationName = 'Rapor Silme';
    final token = await _getToken();

    // API'nizin x-www-form-urlencoded beklediğini varsayıyoruz.
    final Map<String, String> body = {
      'report_id': reportId.toString(),
      'user_id': currentUserId.toString(),
    };

    if (kDebugMode) {
      debugPrint("ApiService ($operationName) - Sending form data: $body. Token: ${token != null ? 'Var' : 'Yok'}");
    }

    try {
      final response = await http.post(
        url,
        headers: _getHeaders(sendContentTypeJson: false, token: token), // x-www-form-urlencoded
        body: body,
        encoding: Encoding.getByName('utf-8'),
      ).timeout(const Duration(seconds: 20));
      final responseData = _handleResponse(response, operationName) as Map<String, dynamic>;
      if (responseData.containsKey('success') && responseData['success'] == true) {
        return responseData;
      } else {
        final apiMessage = responseData['message']?.toString() ?? '$operationName başarısız oldu (API).';
        throw ApiException(apiMessage);
      }
    } catch (e) {
      final errorMessage = _handleError(e, operationName);
      throw ApiException(errorMessage);
    }
  }

  // --- Konum Metodları ---
  Future<Map<String, dynamic>> updateUserLocation({
    required int userId, // API'niz token'dan user_id alıyorsa bu gereksiz olabilir.
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.parse('$_baseUrl/update_user_location.php');
    const operationName = 'Kullanıcı Konumu Güncelleme';
    final token = await _getToken();

    final Map<String, dynamic> requestBody = {
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
    };

    if (kDebugMode) {
      debugPrint("ApiService ($operationName) - Sending JSON data: ${jsonEncode(requestBody)}. Token: ${token != null ? 'Var' : 'Yok'}");
    }

    try {
      final response = await http.post(
        url,
        headers: _getHeaders(sendContentTypeJson: true, token: token),
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15));

      final responseData = _handleResponse(response, operationName) as Map<String, dynamic>;

      if (responseData.containsKey('success') && responseData['success'] == true) {
        return responseData;
      } else {
        final apiMessage = responseData['message']?.toString() ?? '$operationName başarısız oldu (API yanıtı success:false veya mesaj eksik).';
        throw ApiException(apiMessage);
      }
    } catch (e) {
      final errorMessage = _handleError(e, operationName);
      // Orijinal loglamanız:
      // if (kDebugMode) {
      //   debugPrint("ApiService ($operationName) - Caught exception: '$e'. Processed error message: '$errorMessage'");
      // }
      throw ApiException(errorMessage);
    }
  }

  Future<List<UserLocation>> getActiveUsersLocations({required int currentUserId}) async {
    final url = Uri.parse('$_baseUrl/get_active_users_locations.php?current_user_id=$currentUserId');
    const operationName = 'Aktif Kullanıcı Konumlarını Çekme';
    final token = await _getToken();

    if (kDebugMode) {
      debugPrint("ApiService ($operationName) - Requesting GET from $url. Token: ${token != null ? 'Var' : 'Yok'}");
    }
    try {
      final response = await http.get(
        url,
        headers: _getHeaders(sendContentTypeJson: false, token: token),
      ).timeout(const Duration(seconds: 20));

      final dynamic responseData = _handleResponse(response, operationName);

      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('success') &&
          responseData['success'] == true) {
        if (responseData.containsKey('data') && responseData['data'] is List) {
          final List<dynamic> usersData = responseData['data'];
          if (usersData.isEmpty) {
            return [];
          }
          return usersData.map((userJson) {
            try {
              if (userJson is Map<String, dynamic>) {
                return UserLocation.fromJson(userJson);
              } else {
                if (kDebugMode) {
                  debugPrint("ApiService ($operationName) - Expected Map<String, dynamic> for UserLocation.fromJson, got ${userJson.runtimeType}. Data: $userJson");
                }
                return null;
              }
            } catch (e) {
              if (kDebugMode) {
                debugPrint("ApiService ($operationName) - Error parsing UserLocation JSON: $e. JSON: $userJson");
              }
              return null;
            }
          }).whereType<UserLocation>().toList();
        } else {
          // 'data' alanı yoksa veya liste değilse
          throw ApiException('$operationName başarısız: Sunucudan veri alınamadı (data alanı eksik/hatalı formatta). Yanıt: $responseData');
        }
      } else if (responseData is Map<String, dynamic> &&
          responseData.containsKey('success') && responseData['success'] == false) {
        final apiMessage = responseData['message']?.toString() ?? '$operationName başarısız oldu (API success:false).';
        throw ApiException(apiMessage);
      } else {
        // Beklenmedik bir format
        throw ApiException('$operationName başarısız: Sunucudan beklenmeyen formatta yanıt alındı. Gelen: ${responseData.runtimeType}');
      }
    } catch (e) {
      final errorMessage = _handleError(e, operationName);
      throw ApiException(errorMessage);
    }
  }

  Future<List<User>> getLatestRegisteredUsers({int limit = 5}) async {
    final url = Uri.parse('$_baseUrl/get_latest_users.php?limit=$limit');
    const operationName = 'Son Kayıt Olan Kullanıcıları Çekme';
    final token = await _getToken();

    if (kDebugMode) {
      debugPrint("ApiService ($operationName) - Requesting GET from $url. Token: ${token != null ? 'Var' : 'Yok'}");
    }

    try {
      final response = await http.get(
        url,
        headers: _getHeaders(sendContentTypeJson: false, token: token),
      ).timeout(const Duration(seconds: 20));

      final dynamic responseData = _handleResponse(response, operationName);

      List<dynamic> usersListJson;

      if (responseData is List) {
        usersListJson = responseData;
      } else if (responseData is Map<String, dynamic> && responseData.containsKey('data') && responseData['data'] is List) {
        usersListJson = responseData['data'];
      } else if (responseData is Map<String, dynamic> && responseData.containsKey('users') && responseData['users'] is List) {
        // 'users' anahtarını da destekleyelim
        usersListJson = responseData['users'];
      }
      else if (responseData is Map<String, dynamic> && responseData.containsKey('success') && responseData['success'] == false) {
        throw ApiException(responseData['message']?.toString() ?? '$operationName başarısız: API hatası.');
      }
      else {
        throw ApiException('$operationName başarısız: Sunucudan beklenmeyen formatta yanıt alındı (Liste veya data/users içeren Map bekleniyordu, gelen: ${responseData.runtimeType}). Yanıt: $responseData');
      }

      if (usersListJson.isEmpty) {
        return [];
      }
      // User.fromApiListJson veya User.fromJson (hangisi uygunsa)
      return usersListJson
          .map((userJson) {
        try {
          // User modelinizdeki uygun fabrika metodunu kullanın
          // Eğer fromApiListJson yoksa ve fromJson varsa: return User.fromJson(userJson as Map<String, dynamic>);
          return User.fromApiListJson(userJson as Map<String, dynamic>);
        } catch (e) {
          if (kDebugMode) {
            debugPrint("ApiService ($operationName) - Error parsing User JSON: $e. JSON: $userJson");
          }
          return null;
        }
      })
          .whereType<User>()
          .toList();
    } catch (e) {
      final errorMessage = _handleError(e, operationName);
      throw ApiException(errorMessage);
    }
  }

  // --- Profil Metodları ---
  Future<Map<String, dynamic>> uploadAvatar({
    required File imageFile,
    required int userId, // API'niz token'dan user_id alıyorsa bu gereksiz olabilir.
  }) async {
    final url = Uri.parse('$_baseUrl/upload_avatar.php');
    const operationName = 'Avatar Yükleme';
    final token = await _getToken();

    if (token == null) {
      throw ApiException('Avatar yüklemek için yetkilendirme tokenı bulunamadı. Lütfen tekrar giriş yapın.');
    }

    try {
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json'; // API'nin JSON döndüreceğini belirtir

      request.fields['id'] = userId.toString(); // PHP tarafında 'id' olarak bekleniyorsa

      String fileName = imageFile.path.split('/').last;
      request.files.add(
        await http.MultipartFile.fromPath(
          'avatar', // PHP tarafında $_FILES['avatar'] olarak alınacak
          imageFile.path,
          filename: fileName,
        ),
      );

      if (kDebugMode) {
        debugPrint("ApiService ($operationName) - Sending multipart request. URL: $url, Fields: ${request.fields}, Files: ${request.files.map((f) => f.filename).toList()}, Headers: ${request.headers}");
      }

      var streamedResponse = await request.send().timeout(const Duration(seconds: 45));
      var response = await http.Response.fromStream(streamedResponse);
      // _handleResponse'ı burada da kullanabiliriz.
      final responseData = _handleResponse(response, operationName) as Map<String, dynamic>;

      if (responseData.containsKey('success') && responseData['success'] == true && responseData.containsKey('avatar_path')) {
        return responseData; // {'success': true, 'message': '...', 'avatar_path': '...'}
      } else {
        final apiMessage = responseData['message']?.toString() ?? '$operationName başarısız oldu (API yanıtı success:false veya avatar_path eksik).';
        throw ApiException(apiMessage);
      }
    } catch (e) {
      final errorMessage = _handleError(e, operationName);
      // Orijinal loglamanız:
      // if (kDebugMode) {
      //   debugPrint("ApiService ($operationName) - Caught exception: '$e'. Processed error message: '$errorMessage'");
      // }
      throw ApiException(errorMessage);
    }
  }

  Future<Map<String, dynamic>> updateUserProfile({
    required User userData,
  }) async {
    final url = Uri.parse('$_baseUrl/update_user_profile.php');
    const operationName = 'Profil Güncelleme';
    final token = await _getToken();

    if (token == null) {
      throw ApiException('Profil güncellemek için yetkilendirme tokenı bulunamadı. Lütfen tekrar giriş yapın.');
    }
    // User modelinizde toMapForApiUpdate() 'id' içerdiğinden emin olun.
    final Map<String, dynamic> requestBodyMap = userData.toMapForApiUpdate();

    if (kDebugMode) {
      debugPrint("ApiService ($operationName) - Sending JSON data: ${jsonEncode(requestBodyMap)} to $url. Token: Var");
    }

    try {
      final response = await http.post(
        url,
        headers: _getHeaders(sendContentTypeJson: true, token: token),
        body: jsonEncode(requestBodyMap),
      ).timeout(const Duration(seconds: 20));

      final responseData = _handleResponse(response, operationName) as Map<String, dynamic>;

      if (responseData.containsKey('success') && responseData['success'] == true) {
        return responseData;
      } else {
        final apiMessage = responseData['message']?.toString() ?? '$operationName başarısız oldu (API yanıtı success:false veya mesaj eksik).';
        throw ApiException(apiMessage);
      }
    } catch (e) {
      final errorMessage = _handleError(e, operationName);
      // Orijinal loglamanız:
      // if (kDebugMode) {
      //   debugPrint("ApiService ($operationName) - Caught exception: '$e'. Processed error message: '$errorMessage'");
      // }
      throw ApiException(errorMessage);
    }
  }

  // --- Çıkış (Logout) işlemi ---
  Future<void> logout() async {
    final token = await _getToken();
    const operationName = 'Logout';
    if (kDebugMode) {
      debugPrint("ApiService ($operationName) - Token: ${token != null ? 'Var, API çağrısı yapılacak (eğer endpoint tanımlıysa)' : 'Yok, sadece yerel temizlik'}");
    }

    // API'nizde özel bir logout endpoint'i varsa (örn: token'ı sunucuda geçersiz kılmak için)
    // final logoutUrl = Uri.parse('$_baseUrl/logout.php');
    // try {
    //   if (token != null) {
    //     await http.post(
    //       logoutUrl,
    //       headers: _getHeaders(sendContentTypeJson: false, token: token)
    //     ).timeout(const Duration(seconds: 10));
    //     if (kDebugMode) {
    //       debugPrint("ApiService ($operationName) - API üzerinden çıkış yapıldı (veya denendi).");
    //     }
    //   }
    // } catch (e) {
    //   // Hata olsa bile UI tarafı token'ı silmeli.
    //   if (kDebugMode) {
    //     debugPrint("ApiService ($operationName) - API çıkış hatası: $e. Yerel temizlik yine de yapılacak.");
    //   }
    // }
    // Token temizliği (SharedPreferences'tan silme) bu servisin değil,
    // çağıran katmanın (örn: AuthProvider, AuthBloc) sorumluluğunda olmalı.
    // Bu metod sadece API'ye logout bildirimi yapar (eğer varsa).
    return Future.value();
  }

  // --- ADMIN METODLARI ---

  // YENİ EKLENEN METOT: Tüm kullanıcıları getirme (Admin için)
  Future<List<User>> getAllUsers() async {
    const operationName = 'Tüm Kullanıcıları Çekme (Admin)';
    final token = await _getToken();

    if (token == null) {
      if (kDebugMode) {
        debugPrint("ApiService ($operationName) - HATA: Yetkilendirme tokenı bulunamadı.");
      }
      throw ApiException('Kullanıcıları listelemek için yetkilendirme tokenı bulunamadı. Lütfen tekrar giriş yapın.');
    }

    // PHP dosyanızın adını ve yolunu kontrol edin
    final url = Uri.parse('$_baseUrl/get_all_users.php');

    if (kDebugMode) {
      debugPrint("ApiService ($operationName) - Requesting GET from $url. Token: Var");
    }

    try {
      final response = await http.get(
        url,
        headers: _getHeaders(sendContentTypeJson: false, token: token), // GET için body gönderilmez, Content-Type gereksizdir ama token için _getHeaders kullanılır.
      ).timeout(const Duration(seconds: 30));

      final dynamic responseData = _handleResponse(response, operationName);
      List<dynamic> usersListJson;

      if (responseData is List) {
        usersListJson = responseData;
      } else if (responseData is Map<String, dynamic>) {
        if (responseData.containsKey('success') && responseData['success'] == true) {
          if (responseData.containsKey('users') && responseData['users'] is List) {
            usersListJson = responseData['users'];
          } else if (responseData.containsKey('data') && responseData['data'] is List) { // 'data' anahtarını da kontrol et
            usersListJson = responseData['data'];
          } else {
            if (kDebugMode) {
              debugPrint("ApiService ($operationName) - HATA: API yanıtı 'users' veya 'data' listesi içermiyor. Yanıt: $responseData");
            }
            throw ApiException('$operationName başarısız: API yanıtı beklenen formatta değil (users/data listesi bulunamadı).');
          }
        } else {
          // success:false durumu _handleResponse'da ApiException fırlatır.
          // Bu blok _handleResponse'ın düzgün çalışmadığı bir senaryo için ek bir güvenliktir.
          final apiMessage = responseData['message']?.toString() ?? '$operationName başarısız oldu (API success:false).';
          throw ApiException(apiMessage);
        }
      } else {
        if (kDebugMode) {
          debugPrint("ApiService ($operationName) - HATA: Sunucudan beklenmeyen formatta yanıt alındı. Gelen: ${responseData.runtimeType}. Yanıt: $responseData");
        }
        throw ApiException('$operationName başarısız: Sunucudan beklenmeyen formatta yanıt alındı.');
      }

      if (usersListJson.isEmpty) {
        if (kDebugMode) {
          debugPrint("ApiService ($operationName) - Sunucudan boş kullanıcı listesi alındı.");
        }
        return [];
      }

      // User modelinizdeki fabrika metodunu kullanın (fromApiListJson veya fromJson)
      return usersListJson
          .map((userJson) {
        try {
          // User modelinizde `fromApiListJson` veya sadece `fromJson` varsa ona göre ayarlayın
          // Örneğin: return User.fromJson(userJson as Map<String, dynamic>);
          return User.fromApiListJson(userJson as Map<String, dynamic>);
        } catch (e) {
          if (kDebugMode) {
            debugPrint("ApiService ($operationName) - Bir kullanıcı verisi işlenirken hata: $e. JSON: $userJson");
          }
          return null; // Hatalı veriyi atla
        }
      })
          .whereType<User>() // null olanları filtrele
          .toList();
    } catch (e) {
      final errorMessage = _handleError(e, operationName);
      // Orijinal loglama:
      // if (kDebugMode) {
      //   debugPrint("ApiService ($operationName) - getAllUsers hata yakaladı: '$e'. İşlenmiş hata: '$errorMessage'");
      // }
      throw ApiException(errorMessage);
    }
  }

  // YENİ EKLENEN METOT: Kullanıcı silme (Admin için)
  Future<Map<String, dynamic>> deleteUserAsAdmin({required int userId}) async {
    const operationName = 'Kullanıcı Silme (Admin)';
    final token = await _getToken();

    if (token == null) {
      if (kDebugMode) {
        debugPrint("ApiService ($operationName) - HATA: Yetkilendirme tokenı bulunamadı.");
      }
      throw ApiException('Kullanıcı silmek için yetkilendirme tokenı bulunamadı. Lütfen tekrar giriş yapın.');
    }

    // PHP dosyanızın adını ve yolunu kontrol edin
    final url = Uri.parse('$_baseUrl/admin_delete_user.php');

    // PHP tarafı muhtemelen $_POST['user_id'] gibi bekleyecektir.
    // Bu yüzden sendContentTypeJson: false ve body'yi Map<String, String> olarak gönderiyoruz.
    final Map<String, String> requestBody = {
      'user_id': userId.toString(),
    };

    if (kDebugMode) {
      debugPrint("ApiService ($operationName) - Requesting POST to $url with body: $requestBody. Token: Var");
    }

    try {
      final response = await http.post(
        url,
        headers: _getHeaders(sendContentTypeJson: false, token: token), // x-www-form-urlencoded
        body: requestBody,
        encoding: Encoding.getByName('utf-8'), // Form data için önemli
      ).timeout(const Duration(seconds: 20));

      final responseData = _handleResponse(response, operationName) as Map<String, dynamic>;

      if (responseData.containsKey('success') && responseData['success'] == true) {
        if (kDebugMode) {
          debugPrint("ApiService ($operationName) - Kullanıcı ($userId) başarıyla silindi. Yanıt: $responseData");
        }
        return responseData; // Genellikle {'success': true, 'message': '...'}
      } else {
        final apiMessage = responseData['message']?.toString() ?? '$operationName başarısız oldu (API yanıtı success:false veya mesaj eksik).';
        if (kDebugMode) {
          debugPrint("ApiService ($operationName) - Kullanıcı ($userId) silinemedi. API Mesajı: $apiMessage. Yanıt: $responseData");
        }
        throw ApiException(apiMessage);
      }
    } catch (e) {
      final errorMessage = _handleError(e, operationName);
      // Orijinal loglama:
      // if (kDebugMode) {
      //  debugPrint("ApiService ($operationName) - deleteUserAsAdmin hata yakaladı: '$e'. İşlenmiş hata: '$errorMessage'");
      // }
      throw ApiException(errorMessage);
    }
  }

  // YENİ EKLENEN METOT: Kullanıcı rolünü güncelleme (Admin için)
  Future<Map<String, dynamic>> updateUserRoleAsAdmin({
    required int userId,
    required String newRole, // Örneğin "admin", "user", "editor" vb.
  }) async {
    const operationName = 'Kullanıcı Rolü Güncelleme (Admin)';
    final token = await _getToken();

    if (token == null) {
      if (kDebugMode) {
        debugPrint("ApiService ($operationName) - HATA: Yetkilendirme tokenı bulunamadı.");
      }
      throw ApiException('Kullanıcı rolünü güncellemek için yetkilendirme tokenı bulunamadı. Lütfen tekrar giriş yapın.');
    }

    // PHP dosyanızın adını ve yolunu kontrol edin
    final url = Uri.parse('$_baseUrl/admin_update_user_role.php');

    // PHP tarafı muhtemelen $_POST['user_id'] ve $_POST['new_role'] gibi bekleyecektir.
    final Map<String, String> requestBody = {
      'user_id': userId.toString(),
      'new_role': newRole,
    };

    if (kDebugMode) {
      debugPrint("ApiService ($operationName) - Requesting POST to $url with body: $requestBody. Token: Var");
    }

    try {
      final response = await http.post(
        url,
        headers: _getHeaders(sendContentTypeJson: false, token: token), // x-www-form-urlencoded
        body: requestBody,
        encoding: Encoding.getByName('utf-8'),
      ).timeout(const Duration(seconds: 20));

      final responseData = _handleResponse(response, operationName) as Map<String, dynamic>;

      if (responseData.containsKey('success') && responseData['success'] == true) {
        if (kDebugMode) {
          debugPrint("ApiService ($operationName) - Kullanıcı ($userId) rolü ($newRole) başarıyla güncellendi. Yanıt: $responseData");
        }
        return responseData; // Genellikle {'success': true, 'message': '...'}
      } else {
        final apiMessage = responseData['message']?.toString() ?? '$operationName başarısız oldu (API yanıtı success:false veya mesaj eksik).';
        if (kDebugMode) {
          debugPrint("ApiService ($operationName) - Kullanıcı ($userId) rolü güncellenemedi. API Mesajı: $apiMessage. Yanıt: $responseData");
        }
        throw ApiException(apiMessage);
      }
    } catch (e) {
      final errorMessage = _handleError(e, operationName);
      // Orijinal loglama:
      // if (kDebugMode) {
      //   debugPrint("ApiService ($operationName) - updateUserRoleAsAdmin hata yakaladı: '$e'. İşlenmiş hata: '$errorMessage'");
      // }
      throw ApiException(errorMessage);
    }
  }
}