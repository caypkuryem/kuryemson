import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // TextFormField için FilteringTextInputFormatter

// --- VERİ MODELLERİ VE SABİTLER (HTML'ye Göre Güncellendi) ---

class BonusSeviyesi {
  final int altLimit;
  final num ustLimit; // JavaScript'teki Infinity için num kullanıyoruz
  final double bonusMiktari;

  const BonusSeviyesi({
    required this.altLimit,
    required this.ustLimit,
    required this.bonusMiktari,
  });
}

// BÖLGE 1 BONUSLARI (HTML'deki gibi)
const List<BonusSeviyesi> bolge1GunlukBonuslar = [
  BonusSeviyesi(altLimit: 10, ustLimit: 13, bonusMiktari: 105),
  BonusSeviyesi(altLimit: 14, ustLimit: 17, bonusMiktari: 145),
  BonusSeviyesi(altLimit: 18, ustLimit: 21, bonusMiktari: 220),
  BonusSeviyesi(altLimit: 22, ustLimit: 24, bonusMiktari: 265),
  BonusSeviyesi(altLimit: 25, ustLimit: 29, bonusMiktari: 305),
  BonusSeviyesi(altLimit: 30, ustLimit: 34, bonusMiktari: 365),
  BonusSeviyesi(altLimit: 35, ustLimit: 39, bonusMiktari: 475),
  BonusSeviyesi(altLimit: 40, ustLimit: 44, bonusMiktari: 570),
  BonusSeviyesi(altLimit: 45, ustLimit: 49, bonusMiktari: 627),
  BonusSeviyesi(altLimit: 50, ustLimit: double.infinity, bonusMiktari: 690),
];

const List<BonusSeviyesi> bolge1HaftalikBonuslar = [
  BonusSeviyesi(altLimit: 120, ustLimit: 139, bonusMiktari: 450),
  BonusSeviyesi(altLimit: 140, ustLimit: 159, bonusMiktari: 565),
  BonusSeviyesi(altLimit: 160, ustLimit: 179, bonusMiktari: 705),
  BonusSeviyesi(altLimit: 180, ustLimit: 199, bonusMiktari: 880),
  BonusSeviyesi(altLimit: 200, ustLimit: 239, bonusMiktari: 1100),
  BonusSeviyesi(altLimit: 240, ustLimit: 279, bonusMiktari: 1375),
  BonusSeviyesi(altLimit: 280, ustLimit: 319, bonusMiktari: 1720),
  BonusSeviyesi(altLimit: 320, ustLimit: 359, bonusMiktari: 2150),
  BonusSeviyesi(altLimit: 360, ustLimit: 399, bonusMiktari: 2690),
  BonusSeviyesi(altLimit: 400, ustLimit: double.infinity, bonusMiktari: 3365),
];

// BÖLGE 2 BONUSLARI (HTML'deki gibi)
const List<BonusSeviyesi> bolge2GunlukBonuslar = [
  BonusSeviyesi(altLimit: 10, ustLimit: 13, bonusMiktari: 150),
  BonusSeviyesi(altLimit: 14, ustLimit: 17, bonusMiktari: 205),
  BonusSeviyesi(altLimit: 18, ustLimit: 21, bonusMiktari: 310),
  BonusSeviyesi(altLimit: 22, ustLimit: 24, bonusMiktari: 370),
  BonusSeviyesi(altLimit: 25, ustLimit: 29, bonusMiktari: 425),
  BonusSeviyesi(altLimit: 30, ustLimit: 34, bonusMiktari: 510),
  BonusSeviyesi(altLimit: 35, ustLimit: 39, bonusMiktari: 665),
  BonusSeviyesi(altLimit: 40, ustLimit: 44, bonusMiktari: 800),
  BonusSeviyesi(altLimit: 45, ustLimit: 49, bonusMiktari: 880),
  BonusSeviyesi(altLimit: 50, ustLimit: double.infinity, bonusMiktari: 968),
];

const List<BonusSeviyesi> bolge2HaftalikBonuslar = [
  BonusSeviyesi(altLimit: 120, ustLimit: 139, bonusMiktari: 625),
  BonusSeviyesi(altLimit: 140, ustLimit: 159, bonusMiktari: 780),
  BonusSeviyesi(altLimit: 160, ustLimit: 179, bonusMiktari: 975),
  BonusSeviyesi(altLimit: 180, ustLimit: 199, bonusMiktari: 1220),
  BonusSeviyesi(altLimit: 200, ustLimit: 239, bonusMiktari: 1525),
  BonusSeviyesi(altLimit: 240, ustLimit: 279, bonusMiktari: 1905),
  BonusSeviyesi(altLimit: 280, ustLimit: 319, bonusMiktari: 2380),
  BonusSeviyesi(altLimit: 320, ustLimit: 359, bonusMiktari: 2975),
  BonusSeviyesi(altLimit: 360, ustLimit: 399, bonusMiktari: 3720),
  BonusSeviyesi(altLimit: 400, ustLimit: double.infinity, bonusMiktari: 4650),
];

// PAKET ÜCRETLERİ (HTML'deki gibi)
const List<double> paketUcretleri = [100.0, 85.0, 100.0]; // Sırasıyla 08-10, 10-20, 20-24
const double birlesenPaketUcreti = 45.0;

// GÜNLERİN LİSTESİ (ID ve gösterim adı)
const List<Map<String, String>> gunlerListesi = [
  {'id': 'monday', 'ad': 'Pazartesi'},
  {'id': 'tuesday', 'ad': 'Salı'},
  {'id': 'wednesday', 'ad': 'Çarşamba'},
  {'id': 'thursday', 'ad': 'Perşembe'},
  {'id': 'friday', 'ad': 'Cuma'},
  {'id': 'saturday', 'ad': 'Cumartesi'},
  {'id': 'sunday', 'ad': 'Pazar'},
];

// Kazanç Hesaplama Sayfası Widget'ı
class KazancHesaplamaSayfasi extends StatefulWidget {
  const KazancHesaplamaSayfasi({super.key});

  @override
  State<KazancHesaplamaSayfasi> createState() => _KazancHesaplamaSayfasiState();
}

class _KazancHesaplamaSayfasiState extends State<KazancHesaplamaSayfasi> {
  // --- STATE DEĞİŞKENLERİ ---
  String _seciliBolge = '1'; // Başlangıçta Bölge 1 seçili
  late List<BonusSeviyesi> _aktifGunlukBonuslar;
  late List<BonusSeviyesi> _aktifHaftalikBonuslar;

  // Her gün ve her saat dilimi için TextEditingController'lar
  // Gün ID'si -> Saat Dilimi ID'si -> Controller
  final Map<String, Map<String, TextEditingController>> _controllers = {};

  // Hesaplama sonuçları için widget listesi
  List<Widget> _sonucWidgetlari = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _guncelBonuslariAyarla(); // Başlangıçta doğru bonusları ayarla
  }

  void _initializeControllers() {
    for (var gun in gunlerListesi) {
      final gunId = gun['id']!;
      _controllers[gunId] = {
        'saat1': TextEditingController(), // 08:00 - 10:00 (HTML'de day-1)
        'saat2': TextEditingController(), // 10:00 - 20:00 (HTML'de day-2)
        'saat3': TextEditingController(), // 20:00 - 24:00 (HTML'de day-3)
        'birlesen': TextEditingController(), // Birleşen Paket (HTML'de day-birlesen)
      };
    }
  }

  @override
  void dispose() {
    _controllers.forEach((gunId, saatDilimiMap) {
      saatDilimiMap.forEach((saatDilimiId, controller) {
        controller.dispose();
      });
    });
    super.dispose();
  }

  void _guncelBonuslariAyarla() {
    if (_seciliBolge == '1') {
      _aktifGunlukBonuslar = bolge1GunlukBonuslar;
      _aktifHaftalikBonuslar = bolge1HaftalikBonuslar;
    } else {
      _aktifGunlukBonuslar = bolge2GunlukBonuslar;
      _aktifHaftalikBonuslar = bolge2HaftalikBonuslar;
    }
    // Bölge değiştiğinde mevcut sonuçları temizleyebiliriz
    // setState(() {
    //   _sonucWidgetlari = [];
    // });
  }

  // --- HESAPLAMA FONKSİYONU (HTML'deki calculate() fonksiyonuna göre) ---
  void _hesapla() {
    double toplamKazanc = 0;
    int toplamPaket = 0;
    List<Widget> anlikSonucWidgetlari = []; // Bu hesaplama için geçici widget listesi

    for (int i = 0; i < gunlerListesi.length; i++) {
      final gunData = gunlerListesi[i];
      final String gunId = gunData['id']!;
      final String gunAdi = gunData['ad']!;

      double gunlukKazanc = 0;
      int gunlukPaket = 0;

      // Normal paketler (HTML'deki `day-1`, `day-2`, `day-3` inputları)
      final int paketSayisi1 = int.tryParse(_controllers[gunId]!['saat1']!.text) ?? 0;
      final int paketSayisi2 = int.tryParse(_controllers[gunId]!['saat2']!.text) ?? 0;
      final int paketSayisi3 = int.tryParse(_controllers[gunId]!['saat3']!.text) ?? 0;

      gunlukKazanc += paketSayisi1 * paketUcretleri[0]; // paketUcretleri[0] -> 08-10
      gunlukKazanc += paketSayisi2 * paketUcretleri[1]; // paketUcretleri[1] -> 10-20
      gunlukKazanc += paketSayisi3 * paketUcretleri[2]; // paketUcretleri[2] -> 20-24
      gunlukPaket += paketSayisi1 + paketSayisi2 + paketSayisi3;

      // Birleşen paketler (HTML'deki `day-birlesen` inputu)
      final int birlesenPaketSayisi = int.tryParse(_controllers[gunId]!['birlesen']!.text) ?? 0;
      gunlukKazanc += birlesenPaketSayisi * birlesenPaketUcreti;
      gunlukPaket += birlesenPaketSayisi;

      // Günlük bonusu bul
      double gunlukBonus = 0;
      for (final bonus in _aktifGunlukBonuslar) {
        // ustLimit'in double.infinity olup olmadığını kontrol et
        bool ustLimitKontrolu = (bonus.ustLimit == double.infinity)
            ? true // Eğer sonsuzsa, sadece alt limitten büyük olması yeterli
            : gunlukPaket <= bonus.ustLimit;

        if (gunlukPaket >= bonus.altLimit && ustLimitKontrolu) {
          gunlukBonus = bonus.bonusMiktari;
          break;
        }
      }

      gunlukKazanc += gunlukBonus;
      toplamKazanc += gunlukKazanc;
      toplamPaket += gunlukPaket;

      // Günlük sonuçları widget olarak ekle (HTML'deki result-item div'i gibi)
      anlikSonucWidgetlari.add(
        Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              '$gunAdi: Günlük Paket: $gunlukPaket, Günlük Bonus: ${gunlukBonus.toStringAsFixed(0)} TL, Günlük Kazanç (Birleşen Dahil): ${gunlukKazanc.toStringAsFixed(2)} TL',
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ),
      );
    }

    // Haftalık bonusu bul
    double haftalikBonus = 0;
    for (final bonus in _aktifHaftalikBonuslar) {
      bool ustLimitKontrolu = (bonus.ustLimit == double.infinity)
          ? true
          : toplamPaket <= bonus.ustLimit;

      if (toplamPaket >= bonus.altLimit && ustLimitKontrolu) {
        haftalikBonus = bonus.bonusMiktari;
        break;
      }
    }

    toplamKazanc += haftalikBonus;

    // Haftalık özet ve toplam kazancı widget olarak ekle
    anlikSonucWidgetlari.add(
      Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Haftalık Paket: $toplamPaket, Haftalık Bonus: ${haftalikBonus.toStringAsFixed(0)} TL',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Toplam Kazanç: ${toplamKazanc.toStringAsFixed(2)} TL',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ],
        ),
      ),
    );

    // Sonuç widget listesini güncelle ve UI'ı yeniden çiz
    setState(() {
      _sonucWidgetlari = anlikSonucWidgetlari;
    });
  }

  void _alanlariTemizleVeSonuclariSifirla() {
    _controllers.forEach((gunId, saatDilimiMap) {
      saatDilimiMap.forEach((saatDilimiId, controller) {
        controller.clear();
      });
    });
    setState(() {
      _sonucWidgetlari = [];
    });
  }


  // --- BUILD METODU (UI OLUŞTURMA) ---
  @override
  Widget build(BuildContext context) {
    // HTML'deki koyu temaya benzer bir görünüm için renkler
    final Color backgroundColor = Color(0xFF2c2c2c);
    final Color cardBackgroundColor = Color(0xFF3a3a3a);
    final Color textColor = Color(0xFFf1f1f1);
    final Color headerTextColor = Color(0xFFd1d1d1);
    final Color tableHeaderColor = Color(0xFF444444);
    final Color tableCellColor = Color(0xFF4a4a4a);
    final Color inputBackgroundColor = Color(0xFF333333);
    final Color borderColor = Color(0xFF555555);

    return Scaffold(
      backgroundColor: backgroundColor,

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0), // container padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // LOGO (HTML'deki gibi)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                // Eğer vigo-logo.png dosyanız assets/images/ altındaysa:
                child: Image.asset('assets/images/vigo-logo.png', width: 200),
                // Eğer assets/ altında doğrudan vigo-logo.png ise:
                // child: Image.asset('assets/vigo-logo.png', width: 200),
              ),
            ),

            // BAŞLIK (HTML'deki h1)
            Text(
              'Haftalık Kazanç ve Bonus Hesaplama',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, color: headerTextColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),

            // AÇIKLAMA (HTML'deki p)
            Text(
              'MDU Sisteminin 2025 Zamlarına Göre Hesaplanmıştır (km kazançları dahil edilmemiştir).',
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor.withOpacity(0.8)),
            ),
            const SizedBox(height: 24.0),

            // BÖLGE SEÇİMİ (HTML'deki region-select)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              decoration: BoxDecoration(
                color: inputBackgroundColor,
                borderRadius: BorderRadius.circular(5.0),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon(Icons.location_on, color: textColor), // HTML'de 📍 vardı, ikonla değiştirebiliriz
                  // const SizedBox(width: 8),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: _seciliBolge,
                    dropdownColor: inputBackgroundColor,
                    style: TextStyle(color: textColor, fontSize: 16),
                    iconEnabledColor: textColor,
                    underline: SizedBox(), // Varsayılan çizgiyi kaldır
                    items: const [
                      DropdownMenuItem(value: '1', child: Text('Pendik - Tuzla - Çekmeköy - Sultanbeyli')),
                      DropdownMenuItem(value: '2', child: Text('Ataşehir - Kartal - Kadıköy - Üsküdar')),
                    ],
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _seciliBolge = newValue;
                          _guncelBonuslariAyarla();
                          _alanlariTemizleVeSonuclariSifirla(); // Bölge değişince eski sonuçları temizle
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20.0),

            // GÜNLÜK PAKET GİRİŞ ALANLARI (HTML'deki tabloya benzer yapı)
            // Her gün için bir Card içinde satırlar oluşturacağız
            ...gunlerListesi.map((gunData) {
              final String gunId = gunData['id']!;
              final String gunAdi = gunData['ad']!;
              return Card(
                color: cardBackgroundColor,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(gunAdi, style: TextStyle(color: headerTextColor, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      _buildInputRow('08.00 - 10.00:', _controllers[gunId]!['saat1']!, textColor, inputBackgroundColor, borderColor),
                      _buildInputRow('10.00 - 20.00:', _controllers[gunId]!['saat2']!, textColor, inputBackgroundColor, borderColor),
                      _buildInputRow('20.00 - 24.00:', _controllers[gunId]!['saat3']!, textColor, inputBackgroundColor, borderColor),
                      _buildInputRow('Birleşen Paket:', _controllers[gunId]!['birlesen']!, textColor, inputBackgroundColor, borderColor),
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 24.0),

            // HESAPLA BUTONU (HTML'deki button)
            ElevatedButton(
              onPressed: _hesapla,
              style: ElevatedButton.styleFrom(
                backgroundColor: borderColor, // Buton rengi
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                textStyle: TextStyle(fontSize: 18, color: textColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
              ),
              child: Text('Hesapla', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 24.0),

            // SONUÇLAR ALANI (HTML'deki results div'i)
            if (_sonucWidgetlari.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: cardBackgroundColor,
                  borderRadius: BorderRadius.circular(5.0),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _sonucWidgetlari,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Input satırlarını oluşturan yardımcı widget
  Widget _buildInputRow(String label, TextEditingController controller, Color textColor, Color inputBackgroundColor, Color borderColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label, style: TextStyle(color: textColor, fontSize: 15))),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 40, // Input yüksekliği
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor, fontSize: 15),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: inputBackgroundColor,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4.0),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4.0),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4.0),
                    borderSide: BorderSide(color: Colors.blueAccent), // Odaklanınca farklı renk
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}