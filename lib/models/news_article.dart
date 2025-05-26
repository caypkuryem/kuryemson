// lib/models/news_article.dart DOSYASININ SON HALİ

class NewsArticle {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? sourceUrl;
  final DateTime publishedAt;
  final String? sourceName;

  NewsArticle({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.sourceUrl,
    required this.publishedAt,
    this.sourceName,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    String? rawImageUrl = json['image_url'];
    String? fullImageUrl = rawImageUrl; // get_news.php'de tam URL oluşturduğumuz için direkt kullanabiliriz

    return NewsArticle(
      id: json['id'].toString(),
      title: json['title'] ?? 'Başlık Yok',
      description: json['description'] ?? 'Açıklama Yok',
      imageUrl: fullImageUrl,
      sourceUrl: json['source_url'],
      publishedAt: DateTime.tryParse(json['published_at'] ?? '') ?? DateTime.now(),
      sourceName: json['source_name'],
    );
  }
}