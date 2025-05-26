// lib/map/models/report_type.dart
import 'package:flutter/material.dart'; // <-- BU SATIRI EKLE (IconData ve Color için gerekli)

enum ReportType {
  accident('Kaza', 'accident', Icons.car_crash, Colors.red),
  roadWork('Yol Çalışması', 'road_work', Icons.build, Colors.orange),
  policeControl('Yolda Yağ Var', 'police_control', Icons.add_road, Colors.blue),
  hazard('Tehlike', 'hazard', Icons.warning_amber_rounded, Colors.red), // Colors.yellow[700]'ün const HEX karşılığı
  other('Diğer', 'other', Icons.info_outline, Colors.grey); // Her zaman bir 'other' veya varsayılan tip bulundurmak iyidir

  // Constructor'ı yeni alanları alacak şekilde güncelle
  const ReportType(this.displayName, this.apiValue, this.icon, this.color); // icon ve color eklendi
  final String displayName;
  final String apiValue;
  final IconData icon; // <-- YENİ ALAN: İkon için
  final Color color;   // <-- YENİ ALAN: Renk için

  // Bu metodun static olması önemli
  static ReportType fromApiValue(String? value) {
    if (value == null) {
      return ReportType.other;
    }
    for (ReportType type in values) {
      if (type.apiValue == value) {
        return type;
      }
    }
    // Eşleşme bulunamazsa, konsola loglayıp varsayılan bir değer döndürebiliriz
    return ReportType.other;
  }

  // İsteğe bağlı: Enum değerini doğrudan String'e çevirmek için (nadiren gerekir)
  // String toJson() => apiValue;
  // static ReportType fromJson(String json) => fromApiValue(json);
}