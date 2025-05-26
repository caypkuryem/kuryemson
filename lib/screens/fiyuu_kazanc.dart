import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // TextFormField için FilteringTextInputFormatter

// --- VERİ MODELLERİ VE SABİTLER (HTML'ye Göre) ---

class FiyuuBolgeFiyatlari {
  final double ilkPaket;
  final double cokluPaket;
  final double avmBonus;
  final double geceBonus;

  const FiyuuBolgeFiyatlari({
    required this.ilkPaket,
    required this.cokluPaket,
    required this.avmBonus,
    required this.geceBonus,
  });
}

// BÖLGE FİYATLARI (HTML'deki regionPrices objesinden)
const Map<String, FiyuuBolgeFiyatlari> fiyuuBolgeFiyatListesi = {
  '1': FiyuuBolgeFiyatlari(ilkPaket: 100, cokluPaket: 50, avmBonus: 10, geceBonus: 20),
  '2': FiyuuBolgeFiyatlari(ilkPaket: 85, cokluPaket: 40, avmBonus: 10, geceBonus: 20),
  '3': FiyuuBolgeFiyatlari(ilkPaket: 70, cokluPaket: 30, avmBonus: 10, geceBonus: 20),
};

// GÜNLERİN LİSTESİ (ID ve gösterim adı - HTML'deki `capitalize` fonksiyonuna benzer)
const List<Map<String, String>> fiyuuGunlerListesi = [
  {'id': 'monday', 'ad': 'Pazartesi'},
  {'id': 'tuesday', 'ad': 'Salı'},
  {'id': 'wednesday', 'ad': 'Çarşamba'},
  {'id': 'thursday', 'ad': 'Perşembe'},
  {'id': 'friday', 'ad': 'Cuma'},
  {'id': 'saturday', 'ad': 'Cumartesi'},
  {'id': 'sunday', 'ad': 'Pazar'},
];

// Fiyuu Kazanç Hesaplama Sayfası Widget'ı
class FiyuuKazancHesaplamaSayfasi extends StatefulWidget {
  const FiyuuKazancHesaplamaSayfasi({super.key});

  @override
  State<FiyuuKazancHesaplamaSayfasi> createState() => _FiyuuKazancHesaplamaSayfasiState();
}

class _FiyuuKazancHesaplamaSayfasiState extends State<FiyuuKazancHesaplamaSayfasi> {
  // --- STATE DEĞİŞKENLERİ ---
  String _seciliBolgeId = '1'; // Başlangıçta Bölge 1 seçili
  late FiyuuBolgeFiyatlari _aktifFiyatlar;

  // Her gün ve her paket türü için TextEditingController'lar
  // Gün ID'si -> Paket Türü ID'si -> Controller
  final Map<String, Map<String, TextEditingController>> _controllers = {};

  // Hesaplama sonuçları için widget listesi
  List<Widget> _sonucWidgetlari = [];
  double _toplamKazanc = 0;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _guncelFiyatlariAyarla(); // Başlangıçta doğru fiyatları ayarla
  }

  void _initializeControllers() {
    for (var gun in fiyuuGunlerListesi) {
      final gunId = gun['id']!;
      _controllers[gunId] = {
        'first': TextEditingController(),    // HTML'de day-first
        'multiple': TextEditingController(), // HTML'de day-multiple
        'avm': TextEditingController(),      // HTML'de day-avm
        'night': TextEditingController(),    // HTML'de day-night
      };
    }
  }

  @override
  void dispose() {
    _controllers.forEach((gunId, paketTuruMap) {
      paketTuruMap.forEach((paketTuruId, controller) {
        controller.dispose();
      });
    });
    super.dispose();
  }

  void _guncelFiyatlariAyarla() {
    setState(() {
      _aktifFiyatlar = fiyuuBolgeFiyatListesi[_seciliBolgeId]!;
      _alanlariTemizleVeSonuclariSifirla(); // Fiyatlar değişince eski girişleri ve sonuçları temizle
    });
  }

  // --- HESAPLAMA FONKSİYONU (HTML'deki calculate() fonksiyonuna göre) ---
  void _hesapla() {
    double anlikToplamKazanc = 0;
    List<Widget> anlikSonucWidgetlari = [];

    // HTML'deki gibi başlık
    anlikSonucWidgetlari.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0, top: 15.0),
          child: Text(
            'Günlük Detaylar:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent[100]),
          ),
        )
    );

    for (int i = 0; i < fiyuuGunlerListesi.length; i++) {
      final gunData = fiyuuGunlerListesi[i];
      final String gunId = gunData['id']!;
      final String gunAdi = gunData['ad']!;

      final int ilkPaketSayisi = int.tryParse(_controllers[gunId]!['first']!.text) ?? 0;
      final int cokluPaketSayisi = int.tryParse(_controllers[gunId]!['multiple']!.text) ?? 0;
      final int avmBonusSayisi = int.tryParse(_controllers[gunId]!['avm']!.text) ?? 0;
      final int geceBonusSayisi = int.tryParse(_controllers[gunId]!['night']!.text) ?? 0;

      final double gunlukToplam = (ilkPaketSayisi * _aktifFiyatlar.ilkPaket) +
          (cokluPaketSayisi * _aktifFiyatlar.cokluPaket) +
          (avmBonusSayisi * _aktifFiyatlar.avmBonus) +
          (geceBonusSayisi * _aktifFiyatlar.geceBonus);

      anlikToplamKazanc += gunlukToplam;

      // Günlük sonuçları widget olarak ekle (HTML'deki details paragrafı gibi)
      anlikSonucWidgetlari.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9)), // Temaya uygun renk
              children: <TextSpan>[
                TextSpan(text: '$gunAdi: ', style: TextStyle(color: Colors.cyan[600], fontWeight: FontWeight.w500)),
                const TextSpan(text: 'İlk: '),
                TextSpan(text: '$ilkPaketSayisi', style: const TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold)),
                const TextSpan(text: ', Çoklu: '),
                TextSpan(text: '$cokluPaketSayisi', style: const TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold)),
                const TextSpan(text: ', AVM: '),
                TextSpan(text: '$avmBonusSayisi', style: const TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold)),
                const TextSpan(text: ', Gece: '),
                TextSpan(text: '$geceBonusSayisi', style: const TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold)),
                TextSpan(text: ' ➜ ', style: TextStyle(color: Colors.grey[400])),
                TextSpan(text: '${gunlukToplam.toStringAsFixed(2)}₺', style: const TextStyle(color: Colors.lightGreenAccent, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      );
    }

    // Sonuç widget listesini ve toplam kazancı güncelle, UI'ı yeniden çiz
    setState(() {
      _toplamKazanc = anlikToplamKazanc;
      _sonucWidgetlari = anlikSonucWidgetlari;
    });
  }

  void _alanlariTemizleVeSonuclariSifirla() {
    _controllers.forEach((gunId, paketTuruMap) {
      paketTuruMap.forEach((paketTuruId, controller) {
        controller.clear();
      });
    });
    setState(() {
      _toplamKazanc = 0;
      _sonucWidgetlari = [];
    });
  }

  // --- BUILD METODU (UI OLUŞTURMA) ---
  @override
  Widget build(BuildContext context) {
    // HTML'deki koyu temaya benzer bir görünüm için renkler
    final Color backgroundColor = Color(0xFF2c2c2c);
    final Color cardBackgroundColor = Color(0xFF3a3a3a); // Günlük girişler için
    final Color inputBackgroundColor = Color(0xFF484848); // Inputların arkaplanı biraz daha açık
    final Color textColor = Color(0xFFf1f1f1);
    final Color headerTextColor = Color(0xFF00b0ff); // HTML'deki h1 rengi
    final Color borderColor = Color(0xFF555555);
    final Color buttonColor = Color(0xFFFF66B2); // HTML'deki buton rengi
    final Color buttonHoverColor = Color(0xFFFF3385);

    return Scaffold(
      backgroundColor: backgroundColor,
      // Bu sayfanın kendi AppBar'ı olabilir veya firmalar sayfasından geliyorsa olmayabilir.
      // Şimdilik Vigo gibi AppBar'sız bırakalım. İstenirse eklenebilir.
      // appBar: AppBar(
      //   title: Text('Fiyuu Kazanç Hesaplama', style: TextStyle(color: headerTextColor)),
      //   backgroundColor: backgroundColor,
      //   iconTheme: IconThemeData(color: headerTextColor), // Geri tuşu için
      // ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // LOGO (HTML'deki gibi)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 15.0),
                child: Image.asset(
                  'assets/images/fiyuu-logo.png', // Fiyuu logo dosya yolunuz
                  width: 150,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.error_outline, color: headerTextColor, size: 80);
                  },
                ),
              ),
            ),

            // BAŞLIK (HTML'deki h1)
            Text(
              'Haftalık Kazanç ve Bonus Hesaplama',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, color: headerTextColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20.0),

            // BÖLGE SEÇİMİ (HTML'deki region-select)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                color: inputBackgroundColor,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: borderColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _seciliBolgeId,
                  isExpanded: true,
                  dropdownColor: inputBackgroundColor,
                  iconEnabledColor: textColor,
                  style: TextStyle(color: textColor, fontSize: 17), // Fontsize büyütüldü
                  items: fiyuuBolgeFiyatListesi.keys.map((String key) {
                    String bolgeAciklama = "";
                    if (key == '1') bolgeAciklama = "1. Bölge (İlk: ${_aktifFiyatlar.ilkPaket}₺, Çoklu: ${_aktifFiyatlar.cokluPaket}₺)";
                    else if (key == '2') bolgeAciklama = "2. Bölge (İlk: ${_aktifFiyatlar.ilkPaket}₺, Çoklu: ${_aktifFiyatlar.cokluPaket}₺)";
                    else if (key == '3') bolgeAciklama = "3. Bölge (İlk: ${_aktifFiyatlar.ilkPaket}₺, Çoklu: ${_aktifFiyatlar.cokluPaket}₺)";
                    // Dropdown içindeki metni dinamik olarak güncellemek için _aktifFiyatlar kullanılabilir
                    // ancak seçili olan ID'ye göre fiyuuBolgeFiyatListesi'nden çekmek daha doğru
                    final fiyatlar = fiyuuBolgeFiyatListesi[key]!;
                    if (key == '1') bolgeAciklama = "📍 1. Bölge (İlk: ${fiyatlar.ilkPaket.toInt()}₺, Çoklu: ${fiyatlar.cokluPaket.toInt()}₺)";
                    else if (key == '2') bolgeAciklama = "📍 2. Bölge (İlk: ${fiyatlar.ilkPaket.toInt()}₺, Çoklu: ${fiyatlar.cokluPaket.toInt()}₺)";
                    else if (key == '3') bolgeAciklama = "📍 3. Bölge (İlk: ${fiyatlar.ilkPaket.toInt()}₺, Çoklu: ${fiyatlar.cokluPaket.toInt()}₺)";

                    return DropdownMenuItem<String>(
                      value: key,
                      child: Center(child: Text(bolgeAciklama, textAlign: TextAlign.center)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _seciliBolgeId = newValue;
                        _guncelFiyatlariAyarla();
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20.0),

            // GÜNLÜK PAKET GİRİŞ ALANLARI (HTML'deki tabloya benzer yapı)
            // Her gün için bir Card içinde satırlar
            ...fiyuuGunlerListesi.map((gunData) {
              final String gunId = gunData['id']!;
              final String gunAdi = gunData['ad']!;
              return Card(
                color: cardBackgroundColor,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(gunAdi, style: TextStyle(color: headerTextColor.withOpacity(0.85), fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      _buildInputRow('İlk Paket:', _controllers[gunId]!['first']!, textColor, inputBackgroundColor, borderColor, placeholder: '${_aktifFiyatlar.ilkPaket.toInt()}₺'),
                      _buildInputRow('Çoklu Paket:', _controllers[gunId]!['multiple']!, textColor, inputBackgroundColor, borderColor, placeholder: '${_aktifFiyatlar.cokluPaket.toInt()}₺'),
                      _buildInputRow('AVM Bonus:', _controllers[gunId]!['avm']!, textColor, inputBackgroundColor, borderColor, placeholder: '${_aktifFiyatlar.avmBonus.toInt()}₺'),
                      _buildInputRow('Gece Bonus:', _controllers[gunId]!['night']!, textColor, inputBackgroundColor, borderColor, placeholder: '${_aktifFiyatlar.geceBonus.toInt()}₺'),
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 24.0),

            // HESAPLA BUTONU
            ElevatedButton(
              onPressed: _hesapla,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                foregroundColor: Colors.white, // Buton üzerindeki yazı rengi
              ).copyWith(
                overlayColor: MaterialStateProperty.resolveWith<Color?>(
                      (Set<MaterialState> states) {
                    if (states.contains(MaterialState.hovered)) return buttonHoverColor.withOpacity(0.8);
                    if (states.contains(MaterialState.pressed)) return buttonHoverColor;
                    return null; // Defer to the widget's default.
                  },
                ),
              ),
              child: const Text('Hesapla'),
            ),
            const SizedBox(height: 24.0),

            // SONUÇLAR ALANI (HTML'deki results div'i)
            if (_sonucWidgetlari.isNotEmpty || _toplamKazanc > 0)
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: cardBackgroundColor.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: borderColor.withOpacity(0.7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Toplam Kazanç: ${_toplamKazanc.toStringAsFixed(2)}₺',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.yellow[600]), // HTML highlight
                    ),
                    const SizedBox(height: 8),
                    ..._sonucWidgetlari, // Günlük detaylar burada gösterilecek
                  ],
                ),
              ),
            const SizedBox(height: 20), // En altta biraz boşluk
          ],
        ),
      ),
    );
  }

  // Input satırlarını oluşturan yardımcı widget (placeholder eklendi)
  Widget _buildInputRow(String label, TextEditingController controller, Color textColor, Color inputBackgroundColor, Color borderColor, {String? placeholder}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: TextStyle(color: textColor, fontSize: 15))),
          Expanded(
            flex: 3, // Input alanı için daha fazla yer
            child: SizedBox(
              height: 42,
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor, fontSize: 15),
                decoration: InputDecoration(
                  hintText: placeholder, // Placeholder eklendi
                  hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                  filled: true,
                  fillColor: inputBackgroundColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                    borderSide: BorderSide(color: Colors.blueAccent[100]!), // Odaklanınca farklı renk
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