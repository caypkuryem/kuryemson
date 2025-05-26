// lib/map/map_screen.dart
import 'dart:async';
import 'dart:math' as math; // Slider için etiketlerde kullanılabilir
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/rxdart.dart';

import 'package:kuryemapp/map/models/report_model.dart';
import 'package:kuryemapp/map/models/report_type.dart';
import 'package:kuryemapp/map/models/user_location.dart';
import 'package:kuryemapp/services/api_service.dart';


// ReportDetailsDialogWidget burada veya ayrı bir dosyada olabilir.
// Önceki kodunuzda olduğu gibi bırakıyorum.
// **** YENİ WIDGET BAŞLANGICI ****
class ReportDetailsDialogWidget extends StatefulWidget {
  final LatLng reportLocation;

  const ReportDetailsDialogWidget({
    Key? key,
    required this.reportLocation,
  }) : super(key: key);

  @override
  _ReportDetailsDialogWidgetState createState() => _ReportDetailsDialogWidgetState();
}

class _ReportDetailsDialogWidgetState extends State<ReportDetailsDialogWidget> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  ReportType _selectedReportType = ReportType.values.first;
  bool _isDialogProcessing = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isDialogProcessing = true);

      Future.delayed(const Duration(milliseconds: 20), () {
        if (mounted) {
          Navigator.of(context).pop({
            'type': _selectedReportType,
            'description': _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rapor Detayları'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: ListBody(
            children: <Widget>[
              Text('Konum: ${widget.reportLocation.latitude.toStringAsFixed(5)}, ${widget.reportLocation.longitude.toStringAsFixed(5)}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<ReportType>(
                decoration: InputDecoration(
                  labelText: 'Rapor Tipi',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                value: _selectedReportType,
                selectedItemBuilder: (BuildContext context) {
                  return ReportType.values.map<Widget>((ReportType item) {
                    return Row(
                      children: [
                        Icon(item.icon, color: item.color, size: 20),
                        const SizedBox(width: 8),
                        Text(item.displayName),
                      ],
                    );
                  }).toList();
                },
                items: ReportType.values.map((ReportType type) {
                  return DropdownMenuItem<ReportType>(
                    value: type,
                    child: Row(
                      children: [
                        Icon(type.icon, color: type.color, size: 20),
                        const SizedBox(width: 8),
                        Text(type.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: _isDialogProcessing ? null : (ReportType? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedReportType = newValue;
                    });
                  }
                },
                validator: (value) => value == null ? 'Lütfen bir rapor tipi seçin' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Açıklama (Opsiyonel)',
                  hintText: 'Ek detaylar...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                maxLength: 200,
                textInputAction: TextInputAction.done,
                enabled: !_isDialogProcessing,
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('İptal'),
          onPressed: _isDialogProcessing ? null : () => Navigator.of(context).pop(),
        ),
        ElevatedButton.icon(
          icon: _isDialogProcessing
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.add_task_rounded),
          label: Text(_isDialogProcessing ? 'Ekleniyor...' : 'Raporu Ekle'),
          onPressed: _isDialogProcessing ? null : _submitForm,
        ),
      ],
    );
  }
}
// **** YENİ WIDGET SONU ****


class MapScreen extends StatefulWidget {
  final int currentUserId;
  final String? currentUserName;

  const MapScreen({
    Key? key,
    required this.currentUserId,
    this.currentUserName,
  }) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

// WidgetsBindingObserver'ı ekliyoruz
class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  final MapController _mapController = MapController();
  final ApiService _apiService = ApiService();

  List<Report> _reports = [];
  List<UserLocation> _otherUserLocations = [];

  LatLng _currentMapCenter = const LatLng(41.015137, 28.979530); // İstanbul (Başlangıç)
  LatLng? _currentDevicePosition;
  StreamSubscription<Position>? _positionStreamSubscription;

  // Orijinal Timer'lar
  Timer? _periodicReportFetcher;
  Timer? _periodicOtherUsersFetcher;

  // Arka plan için uzun aralıklı Timer'lar
  Timer? _backgroundPeriodicReportFetcher;
  Timer? _backgroundPeriodicOtherUsersFetcher;
  Timer? _backgroundLocationUpdater; // Arka planda tekil konum güncellemesi için (opsiyonel)

  bool _isLoadingReports = false;
  bool _isLoadingOtherUsers = false;
  bool _isProcessingAction = false;
  String? _errorMessage;
  bool _locationPermissionGranted = false;

  bool _isCurrentUserVisibleToEveryone = false;
  static const String keyIsAvailableForDelivery = 'courierIsAvailableForDelivery';

  bool _isSelectingLocationForReportMode = false;
  LatLng? _selectedLocationForNewReport;

  double _selectedDistanceFilterKm = 10.0;
  final double _maxDistanceFilterKm = 20.0;
  final double _allReportsFilterValue = 21.0;

  // Uygulamanın ön planda olup olmadığını takip etmek için bir bayrak
  bool _isAppInForeground = true;

  // Arka plan güncelleme aralığı
  static const Duration _backgroundUpdateInterval = Duration(minutes: 5);
  // Ön plan güncelleme aralıkları (orijinal değerleriniz)
  static const Duration _foregroundReportFetchInterval = Duration(seconds: 45);
  static const Duration _foregroundOtherUsersFetchInterval = Duration(seconds: 20);


  StreamTransformer<TileUpdateEvent, TileUpdateEvent>
  get _tileUpdateDebounceTransformer =>
      StreamTransformer<TileUpdateEvent, TileUpdateEvent>.fromBind(
            (Stream<TileUpdateEvent> stream) =>
            stream.debounceTime(const Duration(milliseconds: 200)),
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Observer'ı kaydet
    if (widget.currentUserId == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorSnackbar('Kullanıcı bilgileri yüklenemedi. Raporlama ve konum özellikleri kısıtlı olabilir.');
      });
    }
    _initializeMapAndLocation();
    _startPeriodicFetchersAndUpdaters(); // Başlangıçta ön plan fetcher'larını başlat
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Observer'ı kaldır
    _positionStreamSubscription?.cancel();
    _periodicReportFetcher?.cancel();
    _periodicOtherUsersFetcher?.cancel();
    _backgroundPeriodicReportFetcher?.cancel();
    _backgroundPeriodicOtherUsersFetcher?.cancel();
    _backgroundLocationUpdater?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    setState(() { // Bu setState UI'ı doğrudan etkilemese de, bayrağı güncellemek için
      _isAppInForeground = state == AppLifecycleState.resumed;
    });

    if (_isAppInForeground) {
      // Uygulama ön plana geldi
      _stopBackgroundTimers();
      _startPeriodicFetchersAndUpdaters(); // Ön plan timer'larını başlat
      _positionStreamSubscription?.resume(); // Konum dinleyicisini devam ettir
      // Ön plana gelindiğinde hemen bir veri güncellemesi yapılabilir
      if (mounted) {
        _fetchReports(showLoadingIndicator: false);
        _fetchOtherUserLocations(showLoadingIndicator: false);
        if (_locationPermissionGranted && _currentDevicePosition == null) {
          _getCurrentDeviceLocation(centerMap: false);
        }
      }
    } else {
      // Uygulama arka plana geçti (paused, inactive, detached)
      _stopForegroundTimers();
      _startBackgroundTimers(); // Arka plan timer'larını başlat
      _positionStreamSubscription?.pause(); // Konum dinleyicisini duraklat
    }
  }

  void _stopForegroundTimers() {
    _periodicReportFetcher?.cancel();
    _periodicReportFetcher = null;
    _periodicOtherUsersFetcher?.cancel();
    _periodicOtherUsersFetcher = null;
  }

  void _startBackgroundTimers() {
    _stopBackgroundTimers(); // Önce mevcut arka plan timer'larını durdur (varsa)

    _backgroundPeriodicReportFetcher = Timer.periodic(_backgroundUpdateInterval, (timer) {
      if (!_isLoadingReports && mounted && !_isAppInForeground && !_isProcessingAction) {
        _fetchReports(showLoadingIndicator: false);
      }
    });

    _backgroundPeriodicOtherUsersFetcher = Timer.periodic(_backgroundUpdateInterval, (timer) {
      if (!_isLoadingOtherUsers && mounted && !_isAppInForeground && !_isProcessingAction) {
        _fetchOtherUserLocations(showLoadingIndicator: false);
      }
    });

    // Opsiyonel: Arka planda periyodik olarak tekil konum güncellemesi
    // Bu, _positionStreamSubscription'ın duraklatılmasına ek olarak yapılabilir
    // Eğer sadece stream'i duraklatmak yeterliyse buna gerek yok.
    _backgroundLocationUpdater = Timer.periodic(_backgroundUpdateInterval, (timer) async {
      if (!_isAppInForeground && _locationPermissionGranted && widget.currentUserId != 0 && _isCurrentUserVisibleToEveryone) {
        try {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium, // Arka planda daha az hassasiyet
            timeLimit: const Duration(seconds: 30),
          );
          if (mounted) {
            final newBgPosition = LatLng(position.latitude, position.longitude);
            // setState(() { _currentDevicePosition = newBgPosition; }); // UI'ı etkilememesi için setState'e gerek yok
            await _updateOwnLocationToApi(newBgPosition);
          }
        } catch (e) {
          // Arka planda hata loglaması yapılabilir, snackbar gösterilmez
          debugPrint("Background location update failed: $e");
        }
      }
    });
  }

  void _stopBackgroundTimers() {
    _backgroundPeriodicReportFetcher?.cancel();
    _backgroundPeriodicReportFetcher = null;
    _backgroundPeriodicOtherUsersFetcher?.cancel();
    _backgroundPeriodicOtherUsersFetcher = null;
    _backgroundLocationUpdater?.cancel();
    _backgroundLocationUpdater = null;
  }


  Future<void> _initializeMapAndLocation() async {
    await _loadProfileSettings();
    await _checkAndRequestLocationPermission();
    if (_locationPermissionGranted) {
      await _getCurrentDeviceLocation(centerMap: true);
      _startListeningToLocationChanges();
    } else {
      if (mounted) {
        setState(() {
          _currentMapCenter = const LatLng(41.015137, 28.979530); // İstanbul
          _errorMessage = "Konum izni verilmedi. Harita özellikleri kısıtlı olabilir.";
        });
      }
    }
    // _isAppInForeground kontrolü eklenerek başlangıçta doğru fetcher'ların çalışması sağlanır
    if (_isAppInForeground) {
      await _fetchReports();
      await _fetchOtherUserLocations();
    }
  }

  Future<void> _loadProfileSettings() async {
    if (widget.currentUserId == 0) return;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _isCurrentUserVisibleToEveryone = prefs.getBool('${keyIsAvailableForDelivery}_${widget.currentUserId}') ?? false;
      });
    } catch (e) {
      if (mounted) _showErrorSnackbar('Profil ayarları yüklenemedi.');
    }
  }

  Future<void> _checkAndRequestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (!mounted) return;

    bool newPermissionState = (permission == LocationPermission.always || permission == LocationPermission.whileInUse);
    if (_locationPermissionGranted != newPermissionState) {
      setState(() {
        _locationPermissionGranted = newPermissionState;
        if (!_locationPermissionGranted) {
          _errorMessage = "Konum izni reddedildi. Rapor ekleyemez ve konumunuzu paylaşamazsınız.";
        } else {
          _errorMessage = null;
          // İzin yeni verildiyse ve konum dinleyici başlamadıysa başlat
          if (_positionStreamSubscription == null) {
            _startListeningToLocationChanges();
          }
        }
      });
    }
  }

  Future<void> _getCurrentDeviceLocation({bool centerMap = false}) async {
    if (!_locationPermissionGranted) return;
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: _isAppInForeground ? LocationAccuracy.high : LocationAccuracy.medium, // Ön/Arka plana göre hassasiyet
        timeLimit: const Duration(seconds: 10),
      );
      if (!mounted) return;

      final newPosition = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentDevicePosition = newPosition;
        if (centerMap && _currentDevicePosition != null && _isAppInForeground) { // Sadece ön plandaysa haritayı ortala
          _currentMapCenter = _currentDevicePosition!;
          _mapController.move(_currentMapCenter, 15.0);
        }
      });
      // Sadece uygulama ön plandaysa veya görünürlük açıksa sık API güncellemesi yap
      if (_isAppInForeground || _isCurrentUserVisibleToEveryone) {
        await _updateOwnLocationToApi(newPosition);
      }
    } catch (e) {
      if (mounted && _isAppInForeground) { // Hata mesajını sadece ön plandaysa göster
        _showErrorSnackbar("Mevcut konumunuz alınamadı. İnternet ve GPS ayarlarınızı kontrol edin.");
      } else {
        debugPrint("Error getting current location (background or no snackbar): $e");
      }
    }
  }

  void _startListeningToLocationChanges() {
    if (!_locationPermissionGranted || _positionStreamSubscription != null) return;

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: _isAppInForeground ? LocationAccuracy.high : LocationAccuracy.medium, // Ön/Arka plana göre hassasiyet
        distanceFilter: _isAppInForeground ? 15 : 100, // Arka planda daha büyük distanceFilter
      ),
    ).listen((Position? position) {
      if (position != null && mounted) {
        final newDevicePosition = LatLng(position.latitude, position.longitude);
        bool shouldUpdateState = _currentDevicePosition == null ||
            (_currentDevicePosition!.latitude - newDevicePosition.latitude).abs() > 0.00001 ||
            (_currentDevicePosition!.longitude - newDevicePosition.longitude).abs() > 0.00001;

        if (shouldUpdateState) {
          // Sadece ön plandaysa UI'ı hemen güncelle
          if (_isAppInForeground) {
            setState(() {
              _currentDevicePosition = newDevicePosition;
            });
          } else {
            _currentDevicePosition = newDevicePosition; // Arka planda UI güncellemesi olmadan state'i ayarla
          }
        }
        // Sadece uygulama ön plandaysa veya görünürlük açıksa sık API güncellemesi yap
        // Arka plandaki _backgroundLocationUpdater zaten periyodik olarak bunu yapacak.
        if (_isAppInForeground && _isCurrentUserVisibleToEveryone) {
          _updateOwnLocationToApi(newDevicePosition);
        }
      }
    }, onError: (error) {
      if (mounted && _isAppInForeground) _showErrorSnackbar('Konum güncellemeleri alınırken bir sorun oluştu.');
      else debugPrint("Location stream error (background or no snackbar): $error");
    });

    // Uygulama durumu değiştiğinde stream'i duraklat/devam ettir
    if (!_isAppInForeground) {
      _positionStreamSubscription?.pause();
    }
  }

  void _startPeriodicFetchersAndUpdaters() {
    // Bu fonksiyon sadece ön plan timer'larını yönetir.
    // Arka plan timer'ları didChangeAppLifecycleState içinde yönetilir.
    _stopForegroundTimers(); // Önce mevcutları durdur

    _periodicReportFetcher = Timer.periodic(_foregroundReportFetchInterval, (timer) {
      if (!_isLoadingReports && mounted && _isAppInForeground && !_isSelectingLocationForReportMode && !_isProcessingAction) {
        _fetchReports(showLoadingIndicator: false);
      }
    });

    _periodicOtherUsersFetcher = Timer.periodic(_foregroundOtherUsersFetchInterval, (timer) {
      if (!_isLoadingOtherUsers && mounted && _isAppInForeground && !_isSelectingLocationForReportMode && !_isProcessingAction) {
        _fetchOtherUserLocations(showLoadingIndicator: false);
      }
    });
  }

  Future<void> _updateOwnLocationToApi(LatLng position) async {
    if (widget.currentUserId == 0 || !_locationPermissionGranted) { // _isCurrentUserVisibleToEveryone kontrolü burada opsiyonel, çağrıldığı yerde yapılıyor
      return;
    }
    // Sadece görünürlük açıksa ve kullanıcı ID geçerliyse güncelle
    if (_isCurrentUserVisibleToEveryone) {
      try {
        await _apiService.updateUserLocation(
          userId: widget.currentUserId,
          latitude: position.latitude,
          longitude: position.longitude,
        //  isVisible: _isCurrentUserVisibleToEveryone, // Her zaman true olmalı bu blokta
        );
      } catch (e) {
        // Arka planda snackbar gösterme, sadece logla
        debugPrint("Failed to update own location to API: $e");
      }
    }
  }

  Future<void> _fetchReports({bool showLoadingIndicator = true}) async {
    if (showLoadingIndicator && _isLoadingReports) return;
    if (!mounted) return;

    // Sadece ön plandaysa ve gösterge isteniyorsa yükleme durumunu ayarla
    if (showLoadingIndicator && _isAppInForeground) {
      setState(() {
        _isLoadingReports = true;
        _errorMessage = null;
      });
    } else if (showLoadingIndicator && !_isAppInForeground) {
      // Arka planda showLoadingIndicator true geldiyse bile UI'ı güncelleme
      _isLoadingReports = true; // Sadece state'i tut, setState yok
    }


    try {
      final reportsFromApi = await _apiService.getReports();
      if (mounted) {
        // Sadece ön plandaysa UI'ı hemen güncelle
        if (_isAppInForeground) {
          setState(() => _reports = reportsFromApi);
        } else {
          _reports = reportsFromApi; // Arka planda UI güncellemesi olmadan state'i ayarla
        }
      }
    } on ApiException catch (e) {
      if (mounted && _isAppInForeground) setState(() => _errorMessage = "Raporlar yüklenemedi: ${e.message}");
      else debugPrint("API Exception fetching reports (background): ${e.message}");
    } catch (e) {
      if (mounted && _isAppInForeground) setState(() => _errorMessage = "Raporlar yüklenirken bir sorun oluştu.");
      else debugPrint("Error fetching reports (background): $e");
    } finally {
      if (mounted) {
        if (showLoadingIndicator && _isAppInForeground) {
          setState(() => _isLoadingReports = false);
        } else {
          _isLoadingReports = false; // Her durumda (setState olmadan da) bayrağı düşür
        }
      }
    }
  }

  Future<void> _fetchOtherUserLocations({bool showLoadingIndicator = true}) async {
    if (widget.currentUserId == 0) return;
    if (showLoadingIndicator && _isLoadingOtherUsers) return;
    if (!mounted) return;

    if (showLoadingIndicator && _isAppInForeground) {
      setState(() {
        _isLoadingOtherUsers = true;
        _errorMessage = null;
      });
    } else if (showLoadingIndicator && !_isAppInForeground) {
      _isLoadingOtherUsers = true;
    }

    try {
      final locationsFromApi = await _apiService.getActiveUsersLocations(currentUserId: widget.currentUserId);
      if (mounted) {
        if (_isAppInForeground) {
          setState(() => _otherUserLocations = locationsFromApi);
        } else {
          _otherUserLocations = locationsFromApi;
        }
      }
    } on ApiException catch (e) {
      if (mounted && _isAppInForeground) setState(() => _errorMessage = "Diğer kullanıcı konumları yüklenemedi: ${e.message}");
      else debugPrint("API Exception fetching other users (background): ${e.message}");
    } catch (e) {
      if (mounted && _isAppInForeground) setState(() => _errorMessage = "Diğer kullanıcı konumları yüklenirken bir sorun oluştu.");
      else debugPrint("Error fetching other users (background): $e");
    } finally {
      if (mounted) {
        if (showLoadingIndicator && _isAppInForeground) {
          setState(() => _isLoadingOtherUsers = false);
        } else {
          _isLoadingOtherUsers = false;
        }
      }
    }
  }
// ... (Report ekleme, silme, detay gösterme ve snackbar metodları aynı kalacak)
// ... (_enterLocationSelectionModeForReport, _initiateAddReportFlowViaLongPress, _handleLocationSelectedForReport)
// ... (_openReportDetailsDialog, _submitNewReport, _handleShowReportDetails, _handleDeleteReport)
// ... (_showErrorSnackbar, _showSuccessSnackbar, _showInfoSnackbar)
// ... (_buildReportMarkerIconWidget, _buildOtherUserLocationMarkerWidget)
// ... (_buildMarkers, _buildDistanceFilterBar)
// ... (build metodu aynı kalacak)
// Devamı (Report ekleme, silme, dialoglar, UI metodları)
  void _enterLocationSelectionModeForReport() {
    if (widget.currentUserId == 0) {
      _showErrorSnackbar('Rapor eklemek için geçerli bir kullanıcı girişi yapılmamış.');
      return;
    }
    if (!_locationPermissionGranted) {
      _showErrorSnackbar('Rapor eklemek için konum izni gereklidir. Lütfen ayarlardan izin verin.');
      _checkAndRequestLocationPermission();
      return;
    }
    if (!mounted || !_isAppInForeground) return; // Sadece ön planda ise mod değiştir

    setState(() {
      _isSelectingLocationForReportMode = true;
      _selectedLocationForNewReport = _currentDevicePosition ?? _currentMapCenter;
      _errorMessage = null;
    });
    _showInfoSnackbar('Lütfen raporlamak istediğiniz konumu haritadan seçin veya onaylayın.');
  }

  Future<void> _initiateAddReportFlowViaLongPress({required LatLng tappedPoint}) async {
    if (widget.currentUserId == 0) {
      _showErrorSnackbar('Rapor eklemek için geçerli bir kullanıcı girişi yapılmamış.');
      return;
    }
    if (!_locationPermissionGranted) {
      _showErrorSnackbar('Rapor eklemek için konum izni gereklidir.');
      return;
    }
    if (!mounted || !_isAppInForeground) return; // Sadece ön planda ise akışı başlat
    _handleLocationSelectedForReport(tappedPoint);
  }

  void _handleLocationSelectedForReport(LatLng selectedPoint) {
    if (!mounted || !_isAppInForeground) return; // Sadece ön planda ise
    setState(() {
      _selectedLocationForNewReport = selectedPoint;
      _isSelectingLocationForReportMode = false; // Bu işlemden sonra rapor detayları dialogu açılacak
    });
    _openReportDetailsDialog(selectedPoint);
  }

  Future<void> _openReportDetailsDialog(LatLng reportLocation) async {
    if (!mounted || !_isAppInForeground) return; // Sadece ön planda ise dialog aç

    final reportData = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: !_isProcessingAction,
      builder: (BuildContext dialogContext) {
        return ReportDetailsDialogWidget(reportLocation: reportLocation);
      },
    );

    if (reportData != null) {
      Future.delayed(const Duration(milliseconds: 50), () async {
        if (mounted) { // mounted kontrolü burada tekrar önemli
          final ReportType type = reportData['type'] as ReportType;
          final String? description = reportData['description'] as String?;
          await _submitNewReport(type, description, reportLocation);
        }
      });
    } else {
      if (!mounted) return;
      setState(() {
        _selectedLocationForNewReport = null;
        // _isSelectingLocationForReportMode = false; // Bu zaten _handleLocationSelectedForReport'ta yapılıyor olabilir veya burada da gerekebilir.
      });
    }
  }

  Future<void> _submitNewReport(ReportType type, String? description, LatLng location) async {
    if (!mounted) return;

    if (widget.currentUserId == 0) {
      if (_isAppInForeground) _showErrorSnackbar('Geçersiz kullanıcı ID. Rapor eklenemedi. Oturumu kontrol edin.');
      else debugPrint('Invalid user ID. Report not added.');
      setState(() {
        _isProcessingAction = false;
        _selectedLocationForNewReport = null;
      });
      return;
    }

    setState(() => _isProcessingAction = true);

    try {
      final response = await _apiService.addReport(
        latitude: location.latitude,
        longitude: location.longitude,
        reportType: type.apiValue,
        userId: widget.currentUserId,
        description: description,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        if (_isAppInForeground) _showSuccessSnackbar('Rapor başarıyla eklendi!');
        await _fetchReports(showLoadingIndicator: false);
      } else {
        if (_isAppInForeground) _showErrorSnackbar(response['message']?.toString() ?? 'Rapor eklenemedi. Sunucu hatası.');
        else debugPrint("Failed to add report: ${response['message']}");
      }
    } on ApiException catch (e) {
      if (mounted && _isAppInForeground) _showErrorSnackbar("API Hatası: ${e.message}");
      else debugPrint("API Exception submitting report: ${e.message}");
    } catch (e) {
      if (mounted && _isAppInForeground) _showErrorSnackbar("Rapor eklenirken beklenmedik bir hata oluştu: $e");
      else debugPrint("Error submitting report: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingAction = false;
          _selectedLocationForNewReport = null;
        });
      }
    }
  }

  Future<void> _handleShowReportDetails(Report report) async {
    if (!mounted || !_isAppInForeground) return; // Sadece ön planda ise dialog aç
    await showDialog(
        context: context,
        barrierDismissible: !_isProcessingAction,
        builder: (BuildContext dialogContext) {
      return AlertDialog(
          title: Row(
            children: [
              Icon(report.reportType.icon, color: report.reportType.color),
              const SizedBox(width: 8),
              Text(report.reportType.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                RichText(text: TextSpan(style: DefaultTextStyle.of(dialogContext).style.copyWith(fontSize: 14), children: [const TextSpan(text: 'Ekleyen: ', style: TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: report.userName ?? 'Kullanıcı ID: ${report.userId}')])),
                const SizedBox(height: 5),
                RichText(text: TextSpan(style: DefaultTextStyle.of(dialogContext).style.copyWith(fontSize: 14), children: [const TextSpan(text: 'Saat: ', style: TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: TimeOfDay.fromDateTime(report.createdAt.toLocal()).format(dialogContext))])),
                RichText(text: TextSpan(style: DefaultTextStyle.of(dialogContext).style.copyWith(fontSize: 14), children: [const TextSpan(text: 'Tarih: ', style: TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: "${report.createdAt.toLocal().day}.${report.createdAt.toLocal().month}.${report.createdAt.toLocal().year}")])),
                if (report.description != null && report.description!.isNotEmpty)
                  Padding(padding: const EdgeInsets.only(top: 8.0), child: RichText(text: TextSpan(style: DefaultTextStyle.of(dialogContext).style.copyWith(fontSize: 14), children: [const TextSpan(text: 'Açıklama: ', style: TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: report.description!)]))),
              ],
            ),
          ),
          actions: <Widget>[
      if (report.userId == widget.currentUserId && widget.currentUserId != 0)
      TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
    onPressed: _isProcessingAction ? null :() {
      Navigator.of(dialogContext).pop(); // Detay dialogunu kapat
      _handleDeleteReport(report); // Silme işlemini başlat
    },
        child: const Text('Sil'),
      ),
            TextButton(
              child: const Text('Kapat'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
      );
        },
    );
  }

  Future<void> _handleDeleteReport(Report report) async {
    if (widget.currentUserId == 0 || report.userId != widget.currentUserId) {
      if (_isAppInForeground) _showErrorSnackbar('Bu raporu silme yetkiniz yok.');
      else debugPrint("Unauthorized attempt to delete report.");
      return;
    }
    if (!mounted || !_isAppInForeground) return; // Sadece ön planda ise dialog aç

    bool deleteDialogIsProcessing = false; // Dialog içindeki işlem durumu için lokal state

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: !_isProcessingAction && !deleteDialogIsProcessing,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Raporu Sil'),
            content: const Text('Bu raporu silmek istediğinizden emin misiniz?'),
            actions: <Widget>[
              TextButton(
                child: const Text('İptal'),
                onPressed: deleteDialogIsProcessing ? null : () => Navigator.of(dialogContext).pop(false),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: deleteDialogIsProcessing ? null : () async {
                  setDialogState(() => deleteDialogIsProcessing = true);
                  // await Future.delayed(Duration(milliseconds: 50)); // UI'ın güncellenmesi için kısa bir bekleme
                  Navigator.of(dialogContext).pop(true);
                },
                child: deleteDialogIsProcessing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                    : const Text('Sil'),
              ),
            ],
          );
        }
        );
      },
    );

    if (confirmed == true) {
      if (!mounted) return;
      setState(() => _isProcessingAction = true);
      try {
        final response = await _apiService.deleteReport(
          reportId: report.id,
          currentUserId: widget.currentUserId,
        );
        if (!mounted) return;

        if (response['success'] == true) {
          if (_isAppInForeground) _showSuccessSnackbar('Rapor başarıyla silindi.');
          await _fetchReports(showLoadingIndicator: false); // Silindikten sonra raporları güncelle
        } else {
          if (_isAppInForeground) _showErrorSnackbar(response['message']?.toString() ?? 'Rapor silinemedi.');
          else debugPrint("Failed to delete report: ${response['message']}");
        }
      } on ApiException catch (e) {
        if (mounted && _isAppInForeground) _showErrorSnackbar("API Hatası: ${e.message}");
        else debugPrint("API Exception deleting report: ${e.message}");
      } catch (e) {
        if (mounted && _isAppInForeground) _showErrorSnackbar("Rapor silinirken bir hata oluştu: $e");
        else debugPrint("Error deleting report: $e");
      } finally {
        if (mounted) setState(() => _isProcessingAction = false);
      }
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted || !_isAppInForeground) {
      debugPrint("Snackbar (Error) suppressed (not mounted or app in background): $message");
      return;
    }
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    if (scaffoldMessenger == null || !scaffoldMessenger.mounted) return;
    scaffoldMessenger.removeCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted || !_isAppInForeground) {
      debugPrint("Snackbar (Success) suppressed (not mounted or app in background): $message");
      return;
    }
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    if (scaffoldMessenger == null || !scaffoldMessenger.mounted) return;
    scaffoldMessenger.removeCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showInfoSnackbar(String message) {
    if (!mounted || !_isAppInForeground) {
      debugPrint("Snackbar (Info) suppressed (not mounted or app in background): $message");
      return;
    }
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    if (scaffoldMessenger == null || !scaffoldMessenger.mounted) return;
    scaffoldMessenger.removeCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blueAccent,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildReportMarkerIconWidget(Report report) {
    return Transform.translate(
      offset: const Offset(0, -12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: report.reportType.color.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          report.reportType.icon,
          color: report.reportType.color,
          size: 28.0,
        ),
      ),
    );
  }

  Widget _buildOtherUserLocationMarkerWidget(UserLocation userLocation) {
    return Transform.translate(
      offset: const Offset(0, -12),
      child: Tooltip(
        message: userLocation.userName ?? 'Kurye ${userLocation.userId}',
        child: Icon(
          Icons.directions_bike,
          color: Colors.deepPurpleAccent,
          size: 30.0,
        ),
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final List<Marker> markers = [];
    final LatLng? referencePoint = _currentDevicePosition;

    if (_currentDevicePosition != null && _locationPermissionGranted) {
      markers.add(
        Marker(
            width: 30.0,
            height: 30.0,
            point: _currentDevicePosition!,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.7),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.my_location, color: Colors.white, size: 16),
            )
        ),
      );
    }

    for (var report in _reports) {
      bool shouldShowReport = true;
      if (referencePoint != null && _selectedDistanceFilterKm < _allReportsFilterValue) {
        final distanceInMeters = Geolocator.distanceBetween(
          referencePoint.latitude,
          referencePoint.longitude,
          report.latitude,
          report.longitude,
        );
        if (distanceInMeters > (_selectedDistanceFilterKm * 1000)) {
          shouldShowReport = false;
        }
      }

      if (shouldShowReport) {
        markers.add(
          Marker(
            width: 40.0,
            height: 40.0,
            point: LatLng(report.latitude, report.longitude),
            child: GestureDetector(
              onTap: () => _handleShowReportDetails(report),
              child: _buildReportMarkerIconWidget(report),
            ),
          ),
        );
      }
    }

    if (_isCurrentUserVisibleToEveryone) {
      for (var userLocation in _otherUserLocations) {
        if (userLocation.userId != widget.currentUserId) {
          markers.add(
            Marker(
              width: 40.0,
              height: 40.0,
              point: userLocation.coordinates,
              child: _buildOtherUserLocationMarkerWidget(userLocation),
            ),
          );
        }
      }
    }

    if (_isSelectingLocationForReportMode && _selectedLocationForNewReport != null) {
      markers.add(
        Marker(
          width: 50.0,
          height: 50.0,
          point: _selectedLocationForNewReport!,
          child: Transform.translate(
            offset: const Offset(0, -15),
            child: const Icon(Icons.add_location_alt_rounded, color: Colors.orangeAccent, size: 50.0),
          ),
        ),
      );
    }
    return markers;
  }

  Widget _buildDistanceFilterBar() {
    String sliderLabel;
    if (_selectedDistanceFilterKm >= _allReportsFilterValue) {
      sliderLabel = "Tümü";
    } else if (_selectedDistanceFilterKm < 1) {
      sliderLabel = "${(_selectedDistanceFilterKm * 1000).round()} m";
    }
    else {
      sliderLabel = "${_selectedDistanceFilterKm.toStringAsFixed(0)} km";
    }

    return Positioned(
      bottom: _isSelectingLocationForReportMode ? 80 : 20,
      left: 10,
      right: 10,
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Raporları Filtrele:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(sliderLabel, style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  showValueIndicator: ShowValueIndicator.never,
                ),
                child: Slider(
                  value: _selectedDistanceFilterKm,
                  min: 0.5,
                  max: _allReportsFilterValue,
                  divisions: 41,
                  label: sliderLabel,
                  onChanged: (_isProcessingAction || !_isAppInForeground) ? null : (double value) {
                    // Sadece ön planda ve işlem yokken slider'ı güncelle
                    setState(() {
                      _selectedDistanceFilterKm = value;
                    });
                  },
                ),
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
        title: const Text('Rapor Haritası'),
        actions: [
          if (widget.currentUserId != 0 && _locationPermissionGranted)
            Tooltip(
              message: _isCurrentUserVisibleToEveryone ? 'Konumum Herkese Görünür' : 'Konumum Gizli',
              child: Switch(
                value: _isCurrentUserVisibleToEveryone,
                onChanged: (_isProcessingAction || !_isAppInForeground) ? null : (value) async {
                  if (widget.currentUserId == 0) return;
                  setState(() => _isProcessingAction = true);
                  try {
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('${keyIsAvailableForDelivery}_${widget.currentUserId}', value);
                    // _isCurrentUserVisibleToEveryone state'i burada güncelleniyor
                    // _updateOwnLocationToApi çağrısı, _currentDevicePosition varsa ve görünürlük true ise konum gönderecek
                    // Eğer görünürlük false ise, API'ye bir sonraki periyodik güncellemede isVisible:false gidecek
                    // veya hemen göndermek için ek bir API çağrısı yapılabilir.
                    // Şimdilik, sadece state'i güncelleyip, bir sonraki _updateOwnLocationToApi'nin doğru isVisible değerini kullanmasını bekliyoruz.
                    setState(() {
                      _isCurrentUserVisibleToEveryone = value;
                      // Eğer kullanıcı kendini gizlediyse ve o anda konumu varsa, hemen bir "gizli" güncelleme gönderebiliriz.
                      // Eğer görünür yaptıysa, bir sonraki konum güncellemesinde (stream veya periyodik) zaten görünür gidecektir.
                      if (!value && _currentDevicePosition != null) {
                        _apiService.updateUserLocation(
                          userId: widget.currentUserId,
                          latitude: _currentDevicePosition!.latitude,
                          longitude: _currentDevicePosition!.longitude,
                       //   isVisible: false, // Hemen gizle
                        );
                      } else if (value && _currentDevicePosition != null) {
                        // Görünür yaptıysa ve konumu varsa, hemen görünür bir güncelleme gönder.
                        _updateOwnLocationToApi(_currentDevicePosition!);
                      }
                    });

                    _showSuccessSnackbar(value ? 'Konumunuz artık herkese görünür.' : 'Konumunuz gizlendi.');
                  } catch (e) {
                    _showErrorSnackbar('Görünürlük ayarı güncellenirken bir hata oluştu.');
                  } finally {
                    if (mounted) setState(() => _isProcessingAction = false);
                  }
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Verileri Yenile',
            onPressed: (_isLoadingReports || _isLoadingOtherUsers || _isProcessingAction || !_isAppInForeground) ? null : () async {
              await _fetchReports();
              await _fetchOtherUserLocations();
              if (_locationPermissionGranted && _currentDevicePosition == null) {
                await _getCurrentDeviceLocation(centerMap: false);
              }
            },
          ),
          if (_locationPermissionGranted)
            IconButton(
              icon: const Icon(Icons.my_location),
              tooltip: 'Konumuma Git',
              onPressed: (_currentDevicePosition == null || _isProcessingAction || !_isAppInForeground) ? null : () {
                _mapController.move(_currentDevicePosition!, 15.0);
              },
            ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentMapCenter,
              initialZoom: 13.0,
              minZoom: 5.0,
              maxZoom: 18.0,
              onPositionChanged: (MapPosition position, bool hasGesture) {
                if (hasGesture && !_isProcessingAction && _isAppInForeground) {
                  _currentMapCenter = position.center ?? _currentMapCenter;
                }
              },
              onTap: (_, point) {
                if (_isSelectingLocationForReportMode && !_isProcessingAction && _isAppInForeground) {
                  _handleLocationSelectedForReport(point);
                }
              },
              onLongPress: (_, point) {
                if (!_isSelectingLocationForReportMode && !_isProcessingAction && widget.currentUserId != 0 && _isAppInForeground) {
                  _initiateAddReportFlowViaLongPress(tappedPoint: point);
                }
              },
              keepAlive: true,
            //  tileUpdateTransformer: _tileUpdateDebounceTransformer,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.metehanersoy.kuryemapp', // Kendi paket adınız
              ),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),
          if ((_isLoadingReports || _isLoadingOtherUsers) && _isAppInForeground) // Yükleme göstergesini sadece ön plandaysa göster
            const Center(child: CircularProgressIndicator()),
          if (_errorMessage != null && !_isLoadingReports && !_isLoadingOtherUsers && _isAppInForeground) // Hata mesajını sadece ön plandaysa göster
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.redAccent.withOpacity(0.9),
                padding: const EdgeInsets.all(8.0),
                child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
              ),
            ),
          // Mesafe filtresi sadece ön plandaysa gösterilir ve etkileşimlidir
          if (_isAppInForeground && !_isSelectingLocationForReportMode) _buildDistanceFilterBar(),
          if (_isSelectingLocationForReportMode && _isAppInForeground) // Rapor için konum seçme uyarısı sadece ön planda
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Card(
                color: Colors.blueAccent.withOpacity(0.9),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(child: Text("Rapor için konumu seçin veya onaylayın.", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _isSelectingLocationForReportMode = false;
                            _selectedLocationForNewReport = null;
                          });
                        },
                      )
                    ],
                  ),
                ),
              ),
            ),
          if (_isSelectingLocationForReportMode && _selectedLocationForNewReport != null && _isAppInForeground) // Onay FAB'ı sadece ön planda
            Positioned(
              bottom: 20,
              left: MediaQuery.of(context).size.width / 2 - 90, // Ortalamak için ayarlandı
              child: FloatingActionButton.extended(
                onPressed: _isProcessingAction ? null : () {
                  _handleLocationSelectedForReport(_selectedLocationForNewReport!);
                },
                label: Text(_isProcessingAction ? "İşleniyor..." : "Onayla ve Devam Et"),
                icon: _isProcessingAction ? const SizedBox(width:18, height:18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,)) : const Icon(Icons.check_circle_outline),
                backgroundColor: Colors.green,
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: (_isSelectingLocationForReportMode || !_isAppInForeground) // FAB'ı sadece ön planda ve rapor seçme modunda değilken göster
          ? null
          : Padding(
        padding: EdgeInsets.only(bottom: _isAppInForeground && !_isSelectingLocationForReportMode ? 110.0 : 20.0), // Filtre çubuğu varsa daha yukarı it
        child: FloatingActionButton.extended(
          onPressed: (_locationPermissionGranted && !_isProcessingAction && widget.currentUserId != 0)
              ? _enterLocationSelectionModeForReport
              : () {
            if (widget.currentUserId == 0) {
              _showErrorSnackbar('Rapor eklemek için geçerli bir kullanıcı girişi yapılmamış.');
            } else if (!_locationPermissionGranted) {
              _showErrorSnackbar('Rapor eklemek için konum izni gereklidir.');
              _checkAndRequestLocationPermission();
            }
          },
          tooltip: 'Yeni Rapor Ekle',
          icon: const Icon(Icons.add_comment_rounded),
          label: const Text("Rapor Ekle"),
        ),
      ),
    );
  }
}