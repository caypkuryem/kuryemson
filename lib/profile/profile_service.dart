import '../models/user.dart';
import '../services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Kullanıcı ID'sini almak için

class ProfileService {

  // Kullanıcının profil bilgilerini getiren metot (SQlite'tan)
  Future<User?> getCurrentUserProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('loggedInUserId'); // Kaydedilmiş kullanıcı ID'sini al

    if (userId != null) {
      // Kullanıcı ID'si varsa, DatabaseHelper'dan kullanıcıyı getir
      return await DatabaseHelper.instance.getUserById(userId);
    } else {
      // Giriş yapmış kullanıcı yok
      return null;
    }
  }

  // Kullanıcının profil bilgilerini güncelleyen metot (SQlite'a)
  Future<int> updateProfile(User user) async {
    // User nesnesinin ID'si dolu olmalı
    if (user.id == null) {
      throw Exception("Güncellenecek kullanıcının ID'si belirtilmemiş.");
    }
    // DatabaseHelper'ı kullanarak kullanıcıyı güncelle
    return await DatabaseHelper.instance.updateUser(user);
  }

// Eğer başka Firebase ile ilgili metotlar varsa, buraya SQlite karşılıklarını ekleyin
}