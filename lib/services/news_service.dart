// lib/services/news_service.dart

import 'dart:convert';
import 'dart:io'; // File için
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p; // path paketini import ediyoruz dosya adı için

// HABER MODELİNİ BURADAN ALIYORUZ:
import '../models/news_article.dart'; // NewsArticle modelinizin doğru olduğundan emin olun

// YENİ: API yanıtını sarmalamak için sınıf
class NewsApiResponse {
  final List<NewsArticle> articles;
  final int totalNews;     // API'den GERÇEK DEĞERİ ALACAK
  final int totalPages;    // API'den GERÇEK DEĞERİ ALACAK
  final int currentPage;   // API'den GERÇEK DEĞERİ ALACAK
  final String status;
  final String? message;

  NewsApiResponse({
    required this.articles,
    required this.totalNews,
    required this.totalPages,
    required this.currentPage,
    required this.status,
    this.message,
  });

  factory NewsApiResponse.fromJson(Map<String, dynamic> json) {
    var list = json['news'] as List? ?? []; // API'niz 'news' anahtarını kullanıyor

    List<NewsArticle> articlesList = list
        .map((i) => NewsArticle.fromJson(i as Map<String, dynamic>))
        .toList();

    // --- DÜZELTME: API'den gelen GERÇEK sayfalama bilgilerini oku ---
    // PHP API'nizin 'totalNews', 'totalPages', 'currentPage' anahtarlarını gönderdiğini varsayıyoruz.
    int totalNewsFromApi = json['totalNews'] as int? ?? 0;
    int currentPageFromApi = json['currentPage'] as int? ?? 1; // API göndermezse varsayılan 1
    int totalPagesFromApi = json['totalPages'] as int? ?? 1;   // API göndermezse varsayılan 1

    // İsteğe bağlı: Eğer API'den gelen totalPages 0 ise ve haber varsa,
    // bu genellikle bir mantık hatasıdır. totalNews > 0 ise totalPages en az 1 olmalıdır.
    // Ancak şimdilik API'den gelene güvenelim. Bu kontrol HomePage'de de yapılabilir.
    // if (totalPagesFromApi == 0 && totalNewsFromApi > 0) {
    //   totalPagesFromApi = 1;
    // }


    return NewsApiResponse(
      articles: articlesList,
      totalNews: totalNewsFromApi,
      totalPages: totalPagesFromApi,
      currentPage: currentPageFromApi,
      status: json['status'] as String? ?? 'error',
      message: json['message'] as String?, // PHP'den gelen mesajı al
    );
  }

  // Hata durumları için bir fabrika metodu ekleyebiliriz
  factory NewsApiResponse.error({String? message, String status = 'error'}) {
    return NewsApiResponse(
      articles: [],
      totalNews: 0,
      totalPages: 0, // Hata durumunda totalPages'i 0 yapabiliriz
      currentPage: 0, // Hata durumunda currentPage'i 0 yapabiliriz
      status: status,
      message: message ?? 'Bilinmeyen bir hata oluştu.',
    );
  }
}

class NewsService {
  static const String _baseUrl = "https://caypmodel.store/kuryem_api";

  Future<NewsApiResponse> getNews({int page = 1, int limit = 4}) async { // Varsayılan limit şimdilik 4 kalsın
    final Uri uri = Uri.parse('$_baseUrl/get_news.php?page=$page&limit=$limit');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 20));

      if (response.body.isNotEmpty) {
      } else {
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedBody;
        try {
          decodedBody = json.decode(response.body) as Map<String, dynamic>;
        } catch (e) {
          return NewsApiResponse.error(message: 'Sunucudan gelen yanıt anlaşılamadı (JSON formatında değil).');
        }

        if (decodedBody.containsKey('status') && decodedBody['status'] == 'success') {
          // decodedBody'yi GÜNCELLENMİŞ NewsApiResponse.fromJson'a gönderiyoruz
          return NewsApiResponse.fromJson(decodedBody);
        } else {
          final errorMessage = decodedBody['message'] as String? ?? 'Haberler alınırken API tarafında bilinmeyen bir sorun oluştu.';
          return NewsApiResponse.error(message: errorMessage, status: decodedBody['status'] as String? ?? 'error');
        }
      } else {
        String errorMessage = 'Haberler API sunucusuna ulaşılamadı. Hata kodu: ${response.statusCode}.';
        String errorStatus = 'http_error';
        try {
          if (response.body.isNotEmpty) {
            final Map<String, dynamic> errorBody = json.decode(response.body) as Map<String, dynamic>;
            errorMessage = errorBody['message'] as String? ?? errorMessage;
            errorStatus = errorBody['status'] as String? ?? errorStatus;
          }
        } catch (e) {
        }
        return NewsApiResponse.error(message: errorMessage, status: errorStatus);
      }
    } on FormatException catch (e) {
      return NewsApiResponse.error(message: 'Sunucudan gelen yanıt anlaşılamadı (Format hatası).');
    } catch (e) {
      return NewsApiResponse.error(message: 'Haberler yüklenirken bir sorun oluştu: ${e.toString()}');
    }
  }

  // addNews ve deleteNews fonksiyonları olduğu gibi kalabilir
  Future<Map<String, dynamic>> addNews({
    required int userId,
    required String title,
    required String description,
    File? imageFile,
    String? sourceUrl,
    String? sourceName,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/add_news.php'));
      request.fields['user_id'] = userId.toString();
      request.fields['title'] = title;
      request.fields['description'] = description;
      if (sourceUrl != null && sourceUrl.isNotEmpty) {
        request.fields['source_url'] = sourceUrl;
      }
      if (sourceName != null && sourceName.isNotEmpty) {
        request.fields['source_name'] = sourceName;
      } else {
        request.fields['source_name'] = 'Kuryem Haber';
      }
      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
            filename: p.basename(imageFile.path),
          ),
        );
      }
      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        return {'status': 'error', 'message': 'Sunucu hatası: ${response.statusCode}. Detay: ${response.body}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Haber eklenirken bir hata oluştu: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> deleteNews({
    required String newsId,
    required int userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/delete_news.php'),
        body: {
          'news_id': newsId,
          'user_id': userId.toString(),
        },
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        return {'status': 'error', 'message': 'Sunucu hatası: ${response.statusCode}. Detay: ${response.body}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Haber silinirken bir hata oluştu: ${e.toString()}'};
    }
  }
}