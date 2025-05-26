import 'package:flutter/material.dart';
import 'kazanc_hesaplama_sayfasi.dart';
import 'fiyuu_kazanc.dart';
import 'yemeksepeti.dart'; // Önceki mesajdaki gibi dosya adınız 'yemeksepeti.dart' ise düzeltin

class FirmalarSayfasi extends StatelessWidget {
  const FirmalarSayfasi({super.key});

  void _navigateToFirmaHesaplama(BuildContext context, String firmaAdi) {
    if (firmaAdi == 'Vigo') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const KazancHesaplamaSayfasi()),
      );
    } else if (firmaAdi == 'Fiyuu') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FiyuuKazancHesaplamaSayfasi()),
      );
    } else if (firmaAdi == 'Yemeksepeti') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const YemeksepetiSayfasi()),
      );
    }
  }

  Widget _buildFirmaKarti(BuildContext context, String firmaAdi, String logoAssetYolu, Color renk) {
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: InkWell(
        onTap: () => _navigateToFirmaHesaplama(context, firmaAdi),
        borderRadius: BorderRadius.circular(15.0),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                logoAssetYolu,
                height: 80.0,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.business_center, size: 80.0, color: renk.withOpacity(0.6));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kazanç Hesaplama Firması Seçin'),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
        children: <Widget>[
          _buildFirmaKarti(
            context,
            'Vigo',
            'assets/images/vigo-logo.png',
            Colors.green,
          ),
          _buildFirmaKarti(
            context,
            'Fiyuu',
            'assets/images/fiyuu-logo.png',
            Colors.pink,
          ),
          _buildFirmaKarti(
            context,
            'Yemeksepeti',
            'assets/images/yemeksepeti-logo.png',
            const Color(0xFFff6b8a),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0), // Genel yatay padding
            child: Align( // <--- GIF'i hizalamak için Align widget'ı eklendi
              alignment: Alignment.centerRight, // <--- GIF'i sağa yaslar (dikeyde ortalar)
              // Diğer seçenekler:
              // alignment: Alignment.topRight, // Sağa ve üste yaslar
              // alignment: Alignment.bottomRight, // Sağa ve alta yaslar
              child: Image.asset(
                'assets/images/para_say.gif',
                height: 200,
                fit: BoxFit.contain, // Genişliği içeriğe göre ayarlanacağı için contain iyi bir seçenek
                errorBuilder: (context, error, stackTrace) {
                  return const Text(
                    'GIF yüklenemedi',
                    style: TextStyle(color: Colors.red),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}