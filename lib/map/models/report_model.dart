// lib/map/models/report_model.dart
import 'package:latlong2/latlong.dart';
import 'report_type.dart'; // Doğru yolda olduğundan emin olun

class Report {
  final int id;
  final double latitude;
  final double longitude;
  final ReportType reportType;
  final int userId;
  final DateTime createdAt;
  final String? description;
  final String? userName; // user_name + user_surname birleşimi olabilir
  // final String? userSurname; // API'den ayrı geliyorsa

  Report({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.reportType,
    required this.userId,
    required this.createdAt,
    this.description,
    this.userName,
    // this.userSurname,
  });

  LatLng get location => LatLng(latitude, longitude);

  factory Report.fromJson(Map<String, dynamic> json) {
    String? combinedUserName;
    if (json.containsKey('user_name') || json.containsKey('user_surname')) {
      final name = json['user_name'] as String? ?? '';
      final surname = json['user_surname'] as String? ?? '';
      combinedUserName = '$name $surname'.trim();
      if (combinedUserName.isEmpty) combinedUserName = null;
    }

    return Report(
      id: _parseInt(json['id']),
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      reportType: ReportType.fromApiValue(json['report_type'] as String?),
      userId: _parseInt(json['user_id']),
      createdAt: _parseDateTime(json['created_at'] as String?),
      description: json['description'] as String?,
      userName: combinedUserName,
      // userSurname: json['user_surname'] as String?,
    );
  }

  // JSON'dan parse ederken tip güvenliği için yardımcı metotlar
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0; // Varsayılan veya hata durumu
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    if (value is int) return value.toDouble();
    return 0.0; // Varsayılan veya hata durumu
  }

  static DateTime _parseDateTime(String? value) {
    if (value == null) return DateTime.now(); // Veya hata fırlat
    return DateTime.tryParse(value) ?? DateTime.now();
  }
}