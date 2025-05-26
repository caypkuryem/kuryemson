// lib/add_news_page.dart

import 'dart:io'; // File için
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart'; // SharedPreferences importu
// NewsService'in doğru yolunu belirttiğinizden emin olun
// Eğer services klasörü lib altında ise:
import 'package:kuryemapp/services/news_service.dart';
// Eğer farklı bir yoldaysa, ona göre güncelleyin. Örn: import '../services/news_service.dart';

class AddNewsPage extends StatefulWidget {
  const AddNewsPage({Key? key}) : super(key: key);

  @override
  _AddNewsPageState createState() => _AddNewsPageState();
}

class _AddNewsPageState extends State<AddNewsPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sourceUrlController = TextEditingController(); // Opsiyonel
  final _sourceNameController = TextEditingController(); // Opsiyonel

  final NewsService _newsService = NewsService();
  final ImagePicker _picker = ImagePicker();
  File? _imageFile; // Seçilen görsel dosyası

  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print("Görsel seçme hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Görsel seçilirken bir hata oluştu. İzinleri kontrol edin.')),
        );
      }
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeriden Seç'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Kameradan Çek'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitNews() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // ---- KULLANICI ID'SİNİ SHARED PREFERENCES'TEN OKU ----
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('loggedInUserId'); // login_form.dart'ta kullanılan anahtar

    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kullanıcı ID bulunamadı. Lütfen tekrar giriş yapın.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }
    // ---- KULLANICI ID OKUMA SONU ----

    try {
      final result = await _newsService.addNews(
        userId: userId, // <<<--- KULLANICI ID'SİNİ PARAMETRE OLARAK GEÇ
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        imageFile: _imageFile,
        sourceUrl: _sourceUrlController.text.trim(),
        sourceName: _sourceNameController.text.trim(),
      );

      if (mounted) {
        if (result['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Haber başarıyla eklendi!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Haber eklenirken bir hata oluştu.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bir ağ veya sunucu hatası oluştu: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
      print("Haber gönderme hatası (catch bloğu): $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _sourceUrlController.dispose();
    _sourceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Haber Ekle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              GestureDetector(
                onTap: () => _showImageSourceActionSheet(context),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                  )
                      : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, size: 50, color: Colors.grey[600]),
                        const SizedBox(height: 8),
                        Text('Görsel Seçmek İçin Tıkla', style: TextStyle(color: Colors.grey[700])),
                      ],
                    ),
                  ),
                ),
              ),
              if (_imageFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, bottom: 12.0),
                  child: TextButton.icon(
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Görseli Kaldır'),
                    onPressed: () {
                      setState(() {
                        _imageFile = null;
                      });
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  ),
                )
              else
                const SizedBox(height: 20),

              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Haber Başlığı *',
                  hintText: 'Haberin dikkat çekici başlığı',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lütfen haber başlığını girin.';
                  }
                  if (value.trim().length < 5) {
                    return 'Başlık en az 5 karakter olmalıdır.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Haber Açıklaması *',
                  hintText: 'Haberin detaylı açıklaması',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 5,
                minLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lütfen haber açıklamasını girin.';
                  }
                  if (value.trim().length < 20) {
                    return 'Açıklama en az 20 karakter olmalıdır.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _sourceUrlController,
                decoration: InputDecoration(
                  labelText: 'Kaynak Linki (Opsiyonel)',
                  hintText: 'https://ornek-haber-sitesi.com/haber',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final uri = Uri.tryParse(value.trim());
                    if (uri == null || !uri.isAbsolute || !uri.hasScheme) {
                      return 'Lütfen geçerli bir URL girin (örn: https://...).';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _sourceNameController,
                decoration: InputDecoration(
                  labelText: 'Kaynak Adı (Opsiyonel)',
                  hintText: 'Örn: Kuryem Haber, AA',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.source),
                ),
                validator: (value) {
                  return null;
                },
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.send),
                label: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text('Haberi Yayınla'),
                onPressed: _isLoading ? null : _submitNews,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}