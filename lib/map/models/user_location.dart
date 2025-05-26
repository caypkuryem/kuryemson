// lib/map/models/user_location.dart
import 'package:latlong2/latlong.dart';

class UserLocation {
  final int userId;
  final String userName;
  final LatLng coordinates; // <--- Belki 'coordinates' veya başka bir isimdir
  final DateTime lastUpdate;

  UserLocation({
    required this.userId,
    required this.userName,
    required this.coordinates, // <--- Alan adı neyse o
    required this.lastUpdate,
  });

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      userId: json['user_id'] as int,
      userName: json['user_name'] as String? ?? 'Kullanıcı ${json['user_id']}',
      coordinates: LatLng( // <--- JSON'dan parse ederken de aynı alan adı
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      ),
      lastUpdate: DateTime.tryParse(json['last_update'] as String? ?? '') ?? DateTime.now(),
    );
  }
}