import 'package:flutter/material.dart';

// --- VERİ MODELLERİ VE SABİTLER (HTML'ye Göre) ---

class YemeksepetiBolgeVerisi {
  final List<List<String>> fiyatlar; // Saat, Pzt-Per, Cuma, Cmt, Paz
  final List<String> haftalikBonus;
  final String notlar;

  const YemeksepetiBolgeVerisi({
    required this.fiyatlar,
    required this.haftalikBonus,
    required this.notlar,
  });
}

// BÖLGE VERİLERİ (HTML'deki regionData objesinden)
const Map<String, YemeksepetiBolgeVerisi> yemeksepetiBolgeVeriListesi = {
  '1': YemeksepetiBolgeVerisi(
      fiyatlar: [
        ["00:00 - 07:59", "64.5 TL", "64.5 TL", "66.0 TL", "71.0 TL"],
        ["08:00 - 11:59", "69.0 TL", "72.0 TL", "69.0 TL", "80.0 TL"],
        ["12:00 - 14:59", "71.0 TL", "72.0 TL", "69.0 TL", "76.0 TL"],
        ["15:00 - 17:59", "69.0 TL", "69.0 TL", "69.0 TL", "85.5 TL"],
        ["18:00 - 20:59", "83.0 TL", "86.0 TL", "86.0 TL", "92.0 TL"],
        ["21:00 - 23:59", "79.0 TL", "79.0 TL", "79.0 TL", "87.5 TL"]
      ],
      haftalikBonus: [
        "160-179 Paket → 2000 TL",
        "180-199 Paket → 2500 TL",
        "200-219 Paket → 4000 TL",
        "220-259 Paket → 5000 TL",
        "260-299 Paket → 6000 TL",
        "300-339 Paket → 7000 TL",
        "340-379 Paket → 8000 TL",
        "380-419 Paket → 9000 TL",
        "420+ Paket → 10000 TL"
      ],
      notlar: "İstanbul bölgesine ait fiyatlandırmalar."
  ),
  '2': YemeksepetiBolgeVerisi(
      fiyatlar: [
        ["00:00 - 07:59", "55.0 TL", "55.0 TL", "56.0 TL", "60.5 TL"],
        ["08:00 - 11:59", "59.0 TL", "61.5 TL", "56.5 TL", "65.0 TL"],
        ["12:00 - 14:59", "59.0 TL", "59.0 TL", "59.0 TL", "64.5 TL"],
        ["15:00 - 17:59", "59.0 TL", "59.0 TL", "63.0 TL", "73.0 TL"],
        ["18:00 - 20:59", "70.5 TL", "73.5 TL", "73.5 TL", "78.5 TL"],
        ["21:00 - 23:59", "67.5 TL", "67.5 TL", "67.5 TL", "74.5 TL"]
      ],
      haftalikBonus: [
        "160-179 Paket → 1500 TL",
        "180-199 Paket → 2000 TL",
        "200-219 Paket → 2750 TL",
        "220-259 Paket → 3500 TL",
        "260-299 Paket → 4000 TL",
        "300-339 Paket → 5000 TL",
        "340-379 Paket → 5700 TL",
        "380-419 Paket → 6700 TL",
        "420+ Paket → 8000 TL"
      ],
      notlar: "İzmir ve Ankara için geçerlidir."
  ),
  '3': YemeksepetiBolgeVerisi(
      fiyatlar: [
        ["00:00 - 07:59", "54.5 TL", "54.5 TL", "55.5 TL", "60.0 TL"],
        ["08:00 - 11:59", "58.5 TL", "61.0 TL", "58.5 TL", "64.5 TL"],
        ["12:00 - 14:59", "58.5 TL", "58.5 TL", "58.5 TL", "64.0 TL"],
        ["15:00 - 17:59", "58.5 TL", "58.5 TL", "62.5 TL", "72.0 TL"],
        ["18:00 - 20:59", "69.5 TL", "72.5 TL", "72.5 TL", "77.5 TL"],
        ["21:00 - 23:59", "66.5 TL", "66.5 TL", "66.5 TL", "73.5 TL"]
      ],
      haftalikBonus: [
        "160-179 Paket → 1000 TL",
        "180-199 Paket → 1400 TL",
        "200-219 Paket → 2500 TL",
        "220-259 Paket → 3000 TL",
        "260-299 Paket → 3500 TL",
        "300-339 Paket → 4000 TL",
        "340-379 Paket → 4500 TL",
        "380-419 Paket → 5500 TL",
        "420+ Paket → 6500 TL"
      ],
      notlar: "Adana, Antalya, Bursa, Denizli, Eskişehir, Gaziantep, Kayseri, Kocaeli, Konya, Mersin, Sakarya, Samsun'da geçerlidir."
  ),
  '4': YemeksepetiBolgeVerisi(
      fiyatlar: [
        ["00:00 - 07:59", "50.5 TL", "50.5 TL", "51.5 TL", "55.0 TL"],
        ["08:00 - 11:59", "54.5 TL", "57.0 TL", "54.5 TL", "60.5 TL"],
        ["12:00 - 14:59", "54.5 TL", "54.5 TL", "54.5 TL", "60.0 TL"],
        ["15:00 - 17:59", "54.5 TL", "54.5 TL", "58.5 TL", "68.0 TL"],
        ["18:00 - 20:59", "65.5 TL", "68.5 TL", "68.5 TL", "73.5 TL"],
        ["21:00 - 23:59", "62.5 TL", "62.5 TL", "62.5 TL", "69.5 TL"]
      ],
      haftalikBonus: [
        "160-179 Paket → 900 TL",
        "180-199 Paket → 1200 TL",
        "200-219 Paket → 2000 TL",
        "220-259 Paket → 2500 TL",
        "260-299 Paket → 3000 TL",
        "300-339 Paket → 3500 TL",
        "340-379 Paket → 4000 TL",
        "380-419 Paket → 4500 TL",
        "420+ Paket → 5000 TL"
      ],
      notlar: "Diğer İller için geçerlidir."
  )
};

// Yemeksepeti Bilgi Sayfası Widget'ı
class YemeksepetiSayfasi extends StatefulWidget {
  const YemeksepetiSayfasi({super.key});

  @override
  State<YemeksepetiSayfasi> createState() => _YemeksepetiSayfasiState();
}

class _YemeksepetiSayfasiState extends State<YemeksepetiSayfasi> with TickerProviderStateMixin { // Animasyon için TickerProviderStateMixin eklendi
  String _seciliBolgeId = '1'; // Başlangıçta Bölge 1 seçili
  late YemeksepetiBolgeVerisi _aktifVeri;

  // Animasyon için controller
  late AnimationController _motorController;
  late Animation<Offset> _motorAnimation;

  @override
  void initState() {
    super.initState();
    _aktifVeri = yemeksepetiBolgeVeriListesi[_seciliBolgeId]!;

    // Motor animasyonu
    _motorController = AnimationController(
      duration: const Duration(seconds: 7), // HTML'deki 5 saniyeye benzer bir süre
      vsync: this,
    )..repeat(); // Animasyonu sürekli tekrarla

    _motorAnimation = Tween<Offset>(
      begin: const Offset(1.5, 0), // Ekranın sağından başla (genişliğe göre ayarlanabilir)
      end: const Offset(-0.5, 0),   // Ekranın solundan çık (genişliğe göre ayarlanabilir)
    ).animate(CurvedAnimation(
      parent: _motorController,
      curve: Curves.linear,
    ));
    // İlk veriyi yükle
    _bolgeVerisiniGuncelle();
  }

  @override
  void dispose() {
    _motorController.dispose();
    super.dispose();
  }

  void _bolgeVerisiniGuncelle() {
    setState(() {
      _aktifVeri = yemeksepetiBolgeVeriListesi[_seciliBolgeId]!;
    });
  }

  @override
  Widget build(BuildContext context) {
    // HTML'deki renklere benzer tema
    final Color backgroundColor = Color(0xFFffe6eb);
    final Color headerColor = Color(0xFFff6b8a);
    final Color textColor = Color(0xFF333333);
    final Color tableHeaderColor = Color(0xFFff8aab);
    final Color tableOddRowColor = Color(0xFFffe6eb); // Zaten arkaplan ile aynı, isterseniz farklılaştırılabilir
    final Color tableEvenRowColor = Colors.white.withOpacity(0.8); // Çift satırlar için hafif farklı bir renk
    final Color noteBoxColor = Color(0xFFffb3c6);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar( // Basit bir AppBar, firmalar sayfasından gelindiği için
        title: Text('Yemeksepeti Fiyatları', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: headerColor,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // HTML'deki "Ödemeler Gün İçerisinde..." notu
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
              margin: const EdgeInsets.only(bottom: 15.0),
              decoration: BoxDecoration(
                  color: noteBoxColor.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: headerColor.withOpacity(0.5))
              ),
              child: Text(
                'Ödemeler Gün İçerisinde Fazla Saate Bölünmesi Nedeni İle Hesaplama Gerekli Görülmemiştir.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor.withOpacity(0.9), fontSize: 14, fontStyle: FontStyle.italic),
              ),
            ),

            // BÖLGE SEÇİMİ (HTML'deki region-selector)
            Text('Bölge Seçiniz:', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: headerColor.withOpacity(0.6)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _seciliBolgeId,
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  iconEnabledColor: headerColor,
                  style: TextStyle(color: textColor, fontSize: 16),
                  items: yemeksepetiBolgeVeriListesi.keys.map((String key) {
                    return DropdownMenuItem<String>(
                      value: key,
                      child: Text('$key. Bölge', textAlign: TextAlign.center),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _seciliBolgeId = newValue;
                        _bolgeVerisiniGuncelle();
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 8.0),
            // Bölgeye özel not
            Center(
              child: Text(
                _aktifVeri.notlar,
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 20.0),

            // SAATLİK FİYAT TABLOSU (HTML'deki input-section)
            Text('Saatlik Ücretler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: headerColor)),
            const SizedBox(height: 10.0),
            SingleChildScrollView( // Tablo geniş olabileceğinden yatayda scroll edilebilir yapıyoruz
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(tableHeaderColor),
                headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                        (Set<MaterialState> states) {
                      // Bu kısım çalışmayabilir, satır bazlı renklendirme için farklı bir yaklaşım gerekebilir
                      // Şimdilik tüm satırlar için aynı renk veya DataRow içinde manuel kontrol
                      return null;
                    }),
                border: TableBorder.all(color: headerColor.withOpacity(0.4), borderRadius: BorderRadius.circular(6)),
                columnSpacing: 15, // Sütunlar arası boşluk
                columns: const [
                  DataColumn(label: Text('Saat')),
                  DataColumn(label: Text('Pzt-Per')),
                  DataColumn(label: Text('Cuma')),
                  DataColumn(label: Text('Cumartesi')),
                  DataColumn(label: Text('Pazar')),
                ],
                rows: _aktifVeri.fiyatlar.asMap().entries.map((entry) {
                  int rowIndex = entry.key;
                  List<String> row = entry.value;
                  return DataRow(
                    color: MaterialStateProperty.all(rowIndex.isOdd ? tableOddRowColor : tableEvenRowColor),
                    cells: row.map((cell) => DataCell(Text(cell, style: TextStyle(color: textColor, fontSize: 13)))).toList(),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 25.0),

            // HAFTALIK BONUS ve GÜNLÜK BONUS GÖRSELİ (HTML'deki bonus-section)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3, // Bonus listesi için daha fazla yer
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Haftalık Bonus', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: headerColor)),
                      const SizedBox(height: 10.0),
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                            color: noteBoxColor.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: headerColor.withOpacity(0.3))
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _aktifVeri.haftalikBonus.map((bonus) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3.0),
                              child: Text('• $bonus', style: TextStyle(color: textColor, fontSize: 14)),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  flex: 2, // Görsel için daha az yer
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Günlük Bonus', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: headerColor.withOpacity(0.85))),
                      const SizedBox(height: 10.0),
                      Container( // HTML'deki note-box'a benzer
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: noteBoxColor,
                          borderRadius: BorderRadius.circular(10.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/gunluk.png', // Bu görselin assets/images altında olduğundan emin olun
                          fit: BoxFit.contain, // Görselin oranını koruyarak sığdır
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 100,
                              color: Colors.grey[300],
                              child: Center(child: Icon(Icons.image_not_supported, color: Colors.grey[600], size: 40)),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30.0),

            // MOTOR VE YOL ANİMASYONU (HTML'deki road ve motorcycle)
            Container(
              height: 120, // HTML'deki road yüksekliği
              width: double.infinity,
              color: headerColor, // Yolun arkaplan rengi
              child: Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  // Yol çizgileri (HTML'deki ::before pseudo-elementine benzer)
                  // Bu kısmı basit bir Container ile de yapabiliriz veya daha karmaşık bir CustomPaint
                  // Şimdilik düz bir yol olarak bırakalım, isterseniz çizgili animasyon eklenebilir.
                  // Basit beyaz çizgi örneği:
                  Positioned(
                    bottom: 55, // Ortalama
                    left: 0,
                    right: 0,
                    child: Container(height: 6, color: Colors.white54),
                  ),

                  SlideTransition(
                    position: _motorAnimation,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 5.0), // Motoru biraz yukarı al
                      child: Image.asset(
                        'assets/images/motorcu.png', // Bu görselin assets/images altında olduğundan emin olun
                        width: 80, // HTML'deki genişliğe benzer
                        errorBuilder: (context, error, stackTrace) {
                          return SizedBox(width: 80, height: 50, child: Icon(Icons.motorcycle, color: Colors.white, size: 40));
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20.0),

            // FOOTER (HTML'deki footer)
            Text(
              '© ${DateTime.now().year} KuryemApp. Tüm Hakları Saklıdır.', // Dinamik yıl ve kendi uygulama adınız
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12),
            ),
            const SizedBox(height: 10.0),
          ],
        ),
      ),
    );
  }
}