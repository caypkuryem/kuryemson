// lib/pages/news_detail_page.dart DOSYASININ GÜNCELLENMİŞ HALİ

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Tarih formatlama için
import 'package:kuryemapp/models/news_article.dart';
import 'package:kuryemapp/services/news_service.dart'; // NewsService'i import ediyoruz
// import 'package:url_launcher/url_launcher.dart'; // Opsiyonel: Kaynak URL'yi açmak için

class NewsDetailPage extends StatefulWidget {
  final NewsArticle newsItem;
  final bool isUserAdmin; // HomePage'den gelen admin durumu
  final int? currentUserId; // HomePage'den gelen kullanıcı ID'si

  const NewsDetailPage({
    Key? key,
    required this.newsItem,
    required this.isUserAdmin,
    required this.currentUserId,
  }) : super(key: key);

  @override
  _NewsDetailPageState createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  final NewsService _newsService = NewsService(); // NewsService örneği
  bool _isDeleting = false; // Silme işlemi sırasında yükleme göstergesi için

  // Opsiyonel: Kaynak URL'yi açmak için bir metod
  // Future<void> _launchURL(String? urlString) async {
  //   if (urlString == null || urlString.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Kaynak URL bulunamadı.')),
  //     );
  //     return;
  //   }
  //   final Uri url = Uri.parse(urlString);
  //   if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('URL açılamadı: $urlString')),
  //     );
  //   }
  // }

  Future<void> _deleteNewsArticle() async {
    if (!widget.isUserAdmin || widget.currentUserId == null || widget.newsItem.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silme işlemi için yetki veya gerekli bilgi eksik.')),
      );
      return;
    }

    // Onay dialogu göster
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Haberi Sil'),
          content: const Text('Bu haberi kalıcı olarak silmek istediğinizden emin misiniz?'),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop(false); // Onaylanmadı
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Sil'),
              onPressed: () {
                Navigator.of(context).pop(true); // Onaylandı
              },
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      setState(() {
        _isDeleting = true;
      });

      try {
        final response = await _newsService.deleteNews(
          newsId: widget.newsItem.id!, // newsItem.id'nin null olmayacağını varsayıyoruz
          userId: widget.currentUserId!, // currentUserId'nin null olmayacağını varsayıyoruz
        );

        if (!mounted) return; // İşlem bittiğinde widget ağaçtan kaldırılmışsa devam etme

        if (response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Haber başarıyla silindi.'),
              backgroundColor: Colors.green,
            ),
          );
          // Başarılı silme işleminden sonra HomePage'e true değeriyle geri dön
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Haber silinirken bir hata oluştu.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bir hata oluştu: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isDeleting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String heroTag = 'news_image_${widget.newsItem.id}';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.newsItem.title.length > 20
            ? '${widget.newsItem.title.substring(0, 20)}...'
            : widget.newsItem.title),
        actions: [
          // Sadece admin ise ve silme işlemi devam etmiyorsa silme butonunu göster
          if (widget.isUserAdmin && !_isDeleting)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Haberi Sil',
              onPressed: _deleteNewsArticle,
            ),
          // Silme işlemi sırasında yükleme göstergesi
          if (_isDeleting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (widget.newsItem.imageUrl != null && widget.newsItem.imageUrl!.isNotEmpty)
              Hero(
                tag: heroTag, // HomePage'deki ile aynı tag olmalı
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.network(
                    widget.newsItem.imageUrl!,
                    width: double.infinity,
                    height: 250, // Detay sayfasında biraz daha büyük olabilir
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: double.infinity,
                      height: 250,
                      color: Colors.grey[300],
                      child: Center(child: Icon(Icons.broken_image, size: 60, color: Colors.grey[600])),
                    ),
                    loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) return child;
                      return SizedBox(
                        width: double.infinity,
                        height: 250,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 16.0),
            Text(
              widget.newsItem.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12.0),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 6.0),
                Text(
                  DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR').format(widget.newsItem.publishedAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                ),
                const Spacer(), // Araya boşluk ekler
                if (widget.newsItem.sourceName != null && widget.newsItem.sourceName!.isNotEmpty)
                  Flexible( // Kaynak adı çok uzunsa taşmayı önler
                    child: Text(
                      "Kaynak: ${widget.newsItem.sourceName}",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            const Divider(height: 24.0),
            Text(
              widget.newsItem.description, // Ya da 'content' eğer tam içerik varsa
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5), // Okunabilirlik için satır yüksekliği
            ),
            const SizedBox(height: 20.0),
            // Opsiyonel: Kaynak URL'ye gitmek için bir buton
            // if (widget.newsItem.sourceUrl != null && widget.newsItem.sourceUrl!.isNotEmpty)
            //   Center(
            //     child: ElevatedButton.icon(
            //       icon: const Icon(Icons.open_in_new),
            //       label: const Text('Kaynağa Git'),
            //       onPressed: () => _launchURL(widget.newsItem.sourceUrl),
            //       style: ElevatedButton.styleFrom(
            //         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            //       ),
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }
}