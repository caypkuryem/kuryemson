// lib/profile/models/user.dart

class User {
  final int id;
  final String name;
  final String surname;
  final String email;
  final String? phone;
  final String? company;
  final String password; // Genellikle API'den gelmez, lokalde tutuluyorsa veya oluşturuluyorsa
  final String? calistigiBolge;
  final String? motorPlakasi;
  final String? avatarUrl;
  final String? hesapDurumu; // Veritabanındaki 'hesap_durumu' veya API'deki ilgili alan

  User({
    required this.id,
    required this.name,
    required this.surname,
    required this.email,
    this.phone,
    this.company,
    required this.password, // Eğer parola ile işlem yapıyorsanız gerekli
    this.calistigiBolge,
    this.motorPlakasi,
    this.avatarUrl,
    this.hesapDurumu,
  });

  // Yerel SQLite Veritabanından okumak için
  // 'calistigi_il_ilce' ve 'motor_plakasi' gibi DB sütun adlarınızın doğru olduğundan emin olun.
  // 'hesap_durumu' da aynı şekilde DB'deki sütun adıyla eşleşmeli.
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      name: map['name'] as String? ?? '',
      surname: map['surname'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String?,
      company: map['company'] as String?,
      password: map['password'] as String? ?? '', // SQLite'da parola tutuyorsanız
      calistigiBolge: map['calistigi_il_ilce'] as String?,
      motorPlakasi: map['motor_plakasi'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      hesapDurumu: map['hesap_durumu'] as String?,
    );
  }

  // Yerel SQLite Veritabanına yazmak için
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'surname': surname,
      'email': email,
      'phone': phone,
      'company': company,
      'password': password, // SQLite'da parola tutuyorsanız
      'calistigi_il_ilce': calistigiBolge,
      'motor_plakasi': motorPlakasi,
      'avatar_url': avatarUrl,
      'hesap_durumu': hesapDurumu,
    };
  }

  // API'ye profil güncelleme verisi göndermek için
  // API'nizin beklediği anahtar adlarını kontrol edin (örn: 'avatarUrl' vs 'avatar_url')
  Map<String, dynamic> toMapForApiUpdate() {
    final map = <String, dynamic>{
      'id': id, // Genellikle ID güncellenmez ama endpoint'e göre değişir
      'name': name,
      'surname': surname,
      'email': email, // Email güncellenebilir mi? API'nize bağlı.
      'phone': phone,
      'company': company,
      'avatarUrl': avatarUrl, // API'niz 'avatar_url' bekliyorsa düzeltin
      'calistigiBolge': calistigiBolge, // API'niz 'calistigi_il_ilce' bekliyorsa düzeltin
      'motorPlakasi': motorPlakasi, // API'niz 'motor_plakasi' bekliyorsa düzeltin
      // 'hesap_durumu' genellikle kullanıcı tarafından güncellenmez, admin yapar.
      // Eğer API üzerinden güncelleniyorsa ve farklı bir endpoint ise buraya eklemeyin.
    };
    // Null olan değerleri göndermemek için (API'niz null kabul etmiyorsa)
    map.removeWhere((key, value) => value == null);
    return map;
  }

  // API yanıtından (genellikle tek bir kullanıcı detayı için) User nesnesi oluşturmak için
  // API'nizin döndürdüğü JSON anahtar adlarının doğru olduğundan emin olun.
  factory User.fromApiResponse(Map<String, dynamic> apiResponse, int userId) {
    // userId parametresi, eğer API yanıtında user ID yoksa ve dışarıdan geliyorsa kullanılır.
    // Eğer API yanıtı 'id' içeriyorsa, onu kullanmak daha iyi olabilir.
    final idFromResponse = apiResponse['id'] is int
        ? apiResponse['id']
        : int.tryParse(apiResponse['id']?.toString() ?? userId.toString()) ?? userId;

    return User(
      id: idFromResponse,
      name: apiResponse['name']?.toString() ?? 'N/A',
      surname: apiResponse['surname']?.toString() ?? '',
      email: apiResponse['email']?.toString() ?? '',
      phone: apiResponse['phone']?.toString(),
      company: apiResponse['company']?.toString(),
      password: '', // API yanıtında genellikle parola olmaz
      calistigiBolge: apiResponse['calistigi_il_ilce']?.toString() ?? apiResponse['calistigiBolge']?.toString(),
      motorPlakasi: apiResponse['motor_plakasi']?.toString() ?? apiResponse['motorPlakasi']?.toString(),
      avatarUrl: apiResponse['avatar_url']?.toString() ?? apiResponse['avatarUrl']?.toString(),
      hesapDurumu: apiResponse['hesap_durumu']?.toString() ?? apiResponse['hesapDurumu']?.toString(),
    );
  }

  // API'den gelen kullanıcı listesindeki her bir JSON objesi için User nesnesi oluşturmak için
  // API'nizin döndürdüğü JSON anahtar adlarının doğru olduğundan emin olun.
  factory User.fromApiListJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? 'N/A',
      surname: json['surname']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      password: '', // API yanıtında genellikle parola olmaz
      phone: json['phone']?.toString(),
      company: json['company']?.toString(),
      calistigiBolge: json['calistigi_il_ilce']?.toString() ?? json['calistigiBolge']?.toString(),
      motorPlakasi: json['motor_plakasi']?.toString() ?? json['motorPlakasi']?.toString(),
      avatarUrl: json['avatar_url']?.toString() ?? json['avatarUrl']?.toString(),
      hesapDurumu: json['hesap_durumu']?.toString() ?? json['hesapDurumu']?.toString(),
    );
  }

  String get fullName {
    if (name.isNotEmpty && surname.isNotEmpty) {
      return '$name $surname';
    } else if (name.isNotEmpty) {
      return name;
    }
    return 'İsim Yok'; // Veya boş string
  }

  // Bu getter, hesapDurumu'nu daha okunabilir bir metne çevirebilir veya
  // UI'da doğrudan 'Admin' gibi bir kontrol için kullanılabilir.
  String? get hesapDurumuAciklamasi {
    if (hesapDurumu == null) return null;
    // Buradaki değerleri veritabanınızdaki/API'nizdeki 'hesap_durumu'
    // sütununda/alanında kullandığınız gerçek değerlerle eşleştirin.
    // Büyük/küçük harfe duyarlı olabilir.
    switch (hesapDurumu!) { // .toLowerCase() eklenebilir eğer case'ler küçük harfse
      case 'Kurye': // veya 'kurye'
        return 'Kurye';
      case 'Admin': // veya 'admin'
        return 'Yönetici';
      case 'Musteri': // veya 'musteri'
        return 'Müşteri';
      default:
        return hesapDurumu; // Bilinmeyen bir durumsa olduğu gibi göster
    }
  }

  // copyWith metodu, User nesnesinin bazı alanlarını güncelleyerek yeni bir kopya oluşturmak için kullanışlıdır.
  User copyWith({
    int? id,
    String? name,
    String? surname,
    String? email,
    String? phone,
    String? company,
    String? password,
    String? calistigiBolge,
    String? motorPlakasi,
    String? avatarUrl,
    String? hesapDurumu,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      password: password ?? this.password,
      calistigiBolge: calistigiBolge ?? this.calistigiBolge,
      motorPlakasi: motorPlakasi ?? this.motorPlakasi,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      hesapDurumu: hesapDurumu ?? this.hesapDurumu,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, surname: $surname, email: $email, phone: $phone, company: $company, calistigiBolge: $calistigiBolge, motorPlakasi: $motorPlakasi, avatarUrl: $avatarUrl, hesapDurumu: $hesapDurumu)';
    // Parola genellikle loglanmaz, o yüzden toString'den çıkarılabilir.
  }

  // İsteğe bağlı: Eşitlik ve hashCode override'ları, User nesnelerini karşılaştırmak
  // veya Set gibi koleksiyonlarda kullanmak için faydalı olabilir.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.email == email; // Genellikle id ve email benzersizlik için yeterlidir
  }

  @override
  int get hashCode => id.hashCode ^ email.hashCode;
}