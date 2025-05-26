// lib/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kuryemapp/models/news_article.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kuryemapp/services/news_service.dart';
import 'package:kuryemapp/add_news_page.dart';
import 'package:kuryemapp/services/news_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final NewsService _newsService = NewsService();

  List<NewsArticle> _allNewsArticles = []; // API'den çekilen tüm haberler
  List<NewsArticle> _displayedArticles = []; // O anki sayfada gösterilen haberler

  bool _isLoading = true;
  String? _errorMessage;

  int _currentPageForDisplay = 1; // Kullanıcının gördüğü sayfa (1 tabanlı)
  static const int _itemsPerPage = 4; // Sayfa başına gösterilecek haber sayısı
  int _totalPagesForDisplay = 1; // Görüntüleme için toplam sayfa sayısı

  bool _isUserAdmin = false;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _checkUserRoleAndLoadInitialNews();
  }

  Future<void> _checkUserRoleAndLoadInitialNews() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getInt('loggedInUserId');
    String? userAccountStatus = prefs.getString('loggedInUserAccountStatus');
    _isUserAdmin = userAccountStatus?.toLowerCase().trim() == 'admin';

    if (mounted) {
      setState(() {}); // _isUserAdmin set edildikten sonra UI güncellensin
    }
    await _fetchAllNews(refresh: true);
  }

  // Bu fonksiyon, API'nizden haberleri çekmeye çalışır.
  // İdealde, tüm haberleri veya sayfalama için yeterli sayıda haberi çeker.
  Future<void> _fetchAllNews({bool refresh = false}) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      if (refresh) {
        _allNewsArticles.clear();
        _displayedArticles.clear();
        _currentPageForDisplay = 1;
      }
    });

    try {
      // API'niz tüm haberleri tek seferde veremiyorsa,
      // burada tüm haberleri alana kadar döngüsel istekler yapmanız gerekebilir.
      // Basitlik adına, API'nin tek bir çağrıda sayfalama için yeterli haber
      // (veya tüm haberleri) döndürdüğünü varsayıyoruz.
      // `getNews` fonksiyonunuzun `limit` parametresini yüksek tutun
      // ya da API'nizden toplam haber sayısını alıp tümünü çekin.
      // Örneğin, veritabanınızda 6 haber varsa ve limit=100 ise hepsi gelecektir.
      final NewsApiResponse apiResponse = await _newsService.getNews(page: 1, limit: 100); // Örnek: En fazla 100 haber çek

      if (mounted) {
        if (apiResponse.status == 'success') {
          _allNewsArticles = List.from(apiResponse.articles);
          _updateDisplayedArticles(); // Bu fonksiyon setState'i kendi içinde çağırır
        } else {
          _errorMessage = apiResponse.message ?? 'Haberler yüklenirken bir sorun oluştu.';
          setState(() {}); // Hata mesajını göstermek için
        }
      }
    } catch (e) {
      if (mounted) {
        _errorMessage = e.toString().replaceFirst("Exception: ", "");
        setState(() {}); // Hata mesajını göstermek için
      }
      print("HomePage: Haberler yüklenirken HATA (catch): $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateDisplayedArticles() {
    if (_allNewsArticles.isEmpty) {
      _displayedArticles = [];
      _totalPagesForDisplay = 1;
      _currentPageForDisplay = 1; // Boşsa ilk sayfaya resetle
      if (mounted) setState(() {});
      return;
    }

    _totalPagesForDisplay = (_allNewsArticles.length / _itemsPerPage).ceil();
    if (_totalPagesForDisplay == 0) _totalPagesForDisplay = 1;

    // Mevcut sayfanın geçerliliğini kontrol et (örneğin haber silme sonrası)
    if (_currentPageForDisplay > _totalPagesForDisplay) {
      _currentPageForDisplay = _totalPagesForDisplay;
    }
    if (_currentPageForDisplay < 1) {
      _currentPageForDisplay = 1;
    }

    int startIndex = (_currentPageForDisplay - 1) * _itemsPerPage;
    // Başlangıç index'inin liste sınırları içinde olduğundan emin ol
    startIndex = startIndex < 0 ? 0 : startIndex;
    if (startIndex >= _allNewsArticles.length && _allNewsArticles.isNotEmpty) {
      // Bu durum pek olmamalı ama bir güvence.
      // Son geçerli sayfaya git.
      _currentPageForDisplay = _totalPagesForDisplay;
      startIndex = (_currentPageForDisplay - 1) * _itemsPerPage;
    }


    int endIndex = startIndex + _itemsPerPage;
    endIndex = endIndex > _allNewsArticles.length ? _allNewsArticles.length : endIndex;

    if (mounted) {
      setState(() {
        // startIndex ve endIndex'in geçerli aralıkta olduğundan emin ol.
        if (startIndex < endIndex && startIndex < _allNewsArticles.length) {
          _displayedArticles = _allNewsArticles.sublist(startIndex, endIndex);
        } else if (_allNewsArticles.isNotEmpty && startIndex == 0 && endIndex == 0) {
          // Bu durum genellikle _allNewsArticles.length < _itemsPerPage olduğunda ve ilk sayfada
          // tüm öğeler gösterildiğinde oluşabilir, sublist(0,0) boş liste verir.
          // _allNewsArticles.length 0 ile _itemsPerPage-1 arasında ise tümünü al.
          _displayedArticles = _allNewsArticles.sublist(0, _allNewsArticles.length);
        }
        else {
          _displayedArticles = []; // Geçersiz aralık veya boş kaynak liste
        }
      });
    }
  }

  void _goToPage(int pageNumber) {
    if (pageNumber >= 1 && pageNumber <= _totalPagesForDisplay) {
      if (mounted) {
        setState(() {
          _currentPageForDisplay = pageNumber;
          _updateDisplayedArticles();
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _fetchAllNews(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kuryem Haberler'),
        actions: [
          if (_isUserAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Yeni Haber Ekle',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddNewsPage()),
                );
                if (result == true) {
                  _handleRefresh();
                }
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _displayedArticles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _displayedArticles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Hata: $_errorMessage', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _handleRefresh,
                child: const Text('Tekrar Dene'),
              )
            ],
          ),
        ),
      );
    }

    if (_allNewsArticles.isEmpty && !_isLoading) { // _allNewsArticles kontrolü daha doğru
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Gösterilecek haber bulunamadı.'),
            const SizedBox(height: 20),
            if (_isUserAdmin)
              TextButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddNewsPage()),
                    );
                    if (result == true) {
                      _handleRefresh();
                    }
                  },
                  child: const Text("İlk haberi eklemek için tıkla!")
              ),
            ElevatedButton(
              onPressed: _handleRefresh,
              child: const Text('Yenile'),
            )
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            // ScrollController artık sonsuz kaydırma için kullanılmıyor.
            // Ancak gerekirse normal kaydırma işlemleri için tutulabilir.
            itemCount: _displayedArticles.length,
            itemBuilder: (context, index) {
              final article = _displayedArticles[index];
              final String heroTag = 'news_image_${article.id}_page$_currentPageForDisplay _$index';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewsDetailPage(
                          newsItem: article,
                          isUserAdmin: _isUserAdmin,
                          currentUserId: _currentUserId,
                        ),
                      ),
                    ).then((value) {
                      if (value == true || (value is Map && value['refresh'] == true)) {
                        _handleRefresh();
                      }
                    });
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (article.imageUrl != null && article.imageUrl!.isNotEmpty)
                        Hero(
                          tag: heroTag,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: Image.network(
                              article.imageUrl!,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: double.infinity,
                                  height: 200,
                                  color: Colors.grey[300],
                                  child: Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey[600])),
                                );
                              },
                              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) return child;
                                return SizedBox(
                                  width: double.infinity,
                                  height: 200,
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
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              article.title,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              article.description,
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    article.sourceName ?? 'Bilinmeyen Kaynak',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[700]),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('dd.MM.yyyy HH:mm', 'tr_TR').format(article.publishedAt),
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_totalPagesForDisplay > 1) // Sadece birden fazla sayfa varsa sayfa kontrollerini göster
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPageForDisplay > 1
                      ? () => _goToPage(_currentPageForDisplay - 1)
                      : null, // İlk sayfadaysa pasif
                ),
                Text('Sayfa $_currentPageForDisplay / $_totalPagesForDisplay'),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPageForDisplay < _totalPagesForDisplay
                      ? () => _goToPage(_currentPageForDisplay + 1)
                      : null, // Son sayfadaysa pasif
                ),
              ],
            ),
          ),
      ],
    );
  }
}