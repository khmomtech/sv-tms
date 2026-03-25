import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
// Generated OpenAPI client removed; use lightweight JSON maps instead.
import '../models/booking.dart';
import '../models/package.dart';
import '../services/local_storage.dart';
import '../services/generated_api_service.dart';
import 'auth_provider.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class BookingsProvider extends ChangeNotifier {
  static const _storageKey = 'bookings';
  final LocalStorage _storage;
  final List<Booking> _bookings = [];
  final GeneratedApiService? _apiService;
  final AuthProvider? _authProvider;
  Timer? _syncTimer;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  BookingsProvider(
      {required LocalStorage storage,
      GeneratedApiService? apiService,
      AuthProvider? authProvider})
      : _storage = storage,
        _apiService = apiService,
        _authProvider = authProvider {
    _load();
    _initRemote();
    _startBackgroundSync();
  }

  List<Booking> get bookings => List.unmodifiable(_bookings);

  Future<void> _load() async {
    try {
      final jsonStr = await _storage.getString(_storageKey);
      if (jsonStr != null) {
        final list = jsonDecode(jsonStr) as List<dynamic>;
        _bookings.clear();
        _bookings.addAll(
            list.map((e) => Booking.fromJson(e as Map<String, dynamic>)));
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    final jsonStr = jsonEncode(_bookings.map((e) => e.toJson()).toList());
    await _storage.saveString(_storageKey, jsonStr);
  }

  Future<void> _initRemote() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      if (_apiService == null || _authProvider == null) return;
      final user = _authProvider!.currentUser;
      if (user == null || user.customerId == null) return;
      final token = await _authProvider!.getToken();
      _apiService!.setAuthToken(token);
      final orders = await _apiService!.listOrdersForCustomer(user.customerId!);
      if (orders != null) {
        _bookings.clear();
        for (final o in orders) {
          _bookings.add(_mapOrderToBooking(o));
        }
        await _save();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('BookingsProvider: remote init failed: $e');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startBackgroundSync() {
    // Periodically attempt to retry failed syncs (best-effort).
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      await retryAllFailed();
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  /// Public method to refresh remote bookings and update local cache.
  Future<void> refresh() async {
    await _initRemote();
  }

  Future<Booking> addBooking({
    required String title,
    required String pickupAddress,
    required String dropoffAddress,
    String? contactName,
    String? contactPhone,
    String? vehicleType,
    String? serviceType,
    String? truckType,
    String? pickupCompany,
    String? destinationCompany,
    String? cargoType,
    double? totalWeightTons,
    double? totalVolumeCbm,
    int? palletCount,
    String? containerNo,
    String? specialHandlingNotes,
    String? receiverName,
    String? receiverPhone,
    int? capacity,
    DateTime? pickupDateTime,
    String? notes,
    List<PackageItem>? packages,
  }) async {
    // Attempt remote create if API supports it (best-effort). Fall back to local creation.
    try {
      if (_authProvider != null &&
          _authProvider!.currentUser?.customerId != null) {
        final token = await _authProvider!.getToken();
        final userId = _authProvider!.currentUser!.customerId!;
        final url =
            '${ApiConstants.baseUrl}${ApiConstants.customerOrders(userId)}';
        final payload = {
          'status': 'pending',
          'pickupAddress': {'addressLine': pickupAddress},
          'deliveryAddress': {'addressLine': dropoffAddress},
          'metadata': {
            'contactName': contactName,
            'contactPhone': contactPhone,
            'vehicleType': vehicleType,
            'serviceType': serviceType,
            'truckType': truckType,
            'pickupCompany': pickupCompany,
            'destinationCompany': destinationCompany,
            'cargoType': cargoType,
            'totalWeightTons': totalWeightTons,
            'totalVolumeCbm': totalVolumeCbm,
            'palletCount': palletCount,
            'containerNo': containerNo,
            'specialHandlingNotes': specialHandlingNotes,
            'receiverName': receiverName,
            'receiverPhone': receiverPhone,
            'capacity': capacity,
            'pickupDateTime': pickupDateTime?.toIso8601String(),
            'notes': notes,
            'packages': packages?.map((p) => p.toJson()).toList(),
          }
        };
        try {
          final resp = await http
              .post(Uri.parse(url),
                  headers: {
                    'Content-Type': ApiConstants.contentTypeJson,
                    if (token != null && token.isNotEmpty)
                      'Authorization': 'Bearer $token'
                  },
                  body: jsonEncode(payload))
              .timeout(const Duration(seconds: 10));

          if (resp.statusCode == 200 || resp.statusCode == 201) {
            final map = jsonDecode(resp.body) as Map<String, dynamic>;
            var remoteBooking =
                _mapOrderToBooking(map).copyWith(syncStatus: 'synced');
            // preserve optional metadata locally
            remoteBooking = remoteBooking.copyWith(
              contactName: contactName,
              contactPhone: contactPhone,
              vehicleType: vehicleType,
              capacity: capacity,
              pickupDateTime: pickupDateTime,
              notes: notes,
            );
            _bookings.insert(0, remoteBooking);
            await _save();
            notifyListeners();
            return remoteBooking;
          } else {
            debugPrint(
                'BookingsProvider: remote POST returned ${resp.statusCode}: ${resp.body}');
            // try to surface a friendly server error message to UI
            try {
              final map = jsonDecode(resp.body) as Map<String, dynamic>;
              _errorMessage =
                  map['message']?.toString() ?? 'Server: ${resp.statusCode}';
            } catch (_) {
              _errorMessage = 'Server: ${resp.statusCode} - ${resp.body}';
            }
            notifyListeners();
            throw Exception('Failed to create order: ${resp.statusCode}');
          }
        } catch (e) {
          debugPrint('BookingsProvider: remote POST failed: $e');
          // fall through to local create
        }
      }
    } catch (e) {
      debugPrint('BookingsProvider: remote create attempt failed: $e');
    }

    final localId = DateTime.now().millisecondsSinceEpoch.toString();
    final b = Booking(
      id: localId,
      isDraft: false,
      retryCount: 0,
      title: title,
      pickupAddress: pickupAddress,
      dropoffAddress: dropoffAddress,
      createdAt: DateTime.now(),
      syncStatus: 'pending',
      contactName: contactName,
      contactPhone: contactPhone,
      vehicleType: vehicleType,
      serviceType: serviceType,
      truckType: truckType,
      pickupCompany: pickupCompany,
      destinationCompany: destinationCompany,
      cargoType: cargoType,
      totalWeightTons: totalWeightTons,
      totalVolumeCbm: totalVolumeCbm,
      palletCount: palletCount,
      containerNo: containerNo,
      specialHandlingNotes: specialHandlingNotes,
      receiverName: receiverName,
      receiverPhone: receiverPhone,
      capacity: capacity,
      pickupDateTime: pickupDateTime,
      notes: notes,
      packages: packages,
    );
    _bookings.insert(0, b);
    await _save();
    notifyListeners();
    return b;
  }

  /// Create a draft Booking locally (not saved remotely) and return it without inserting to the list.
  Booking createDraft({
    required String title,
    required String pickupAddress,
    required String dropoffAddress,
    String? contactName,
    String? contactPhone,
    String? vehicleType,
    String? serviceType,
    String? truckType,
    String? pickupCompany,
    String? destinationCompany,
    String? cargoType,
    double? totalWeightTons,
    double? totalVolumeCbm,
    int? palletCount,
    String? containerNo,
    String? specialHandlingNotes,
    String? receiverName,
    String? receiverPhone,
    int? capacity,
    DateTime? pickupDateTime,
    String? notes,
    List<PackageItem>? packages,
  }) {
    final localId = DateTime.now().millisecondsSinceEpoch.toString();
    return Booking(
      id: localId,
      isDraft: true,
      retryCount: 0,
      title: title,
      pickupAddress: pickupAddress,
      dropoffAddress: dropoffAddress,
      createdAt: DateTime.now(),
      syncStatus: 'pending',
      contactName: contactName,
      contactPhone: contactPhone,
      vehicleType: vehicleType,
      serviceType: serviceType,
      truckType: truckType,
      pickupCompany: pickupCompany,
      destinationCompany: destinationCompany,
      cargoType: cargoType,
      totalWeightTons: totalWeightTons,
      totalVolumeCbm: totalVolumeCbm,
      palletCount: palletCount,
      containerNo: containerNo,
      specialHandlingNotes: specialHandlingNotes,
      receiverName: receiverName,
      receiverPhone: receiverPhone,
      capacity: capacity,
      pickupDateTime: pickupDateTime,
      notes: notes,
      packages: packages,
    );
  }

  /// Save or update a draft booking locally. Drafts are not sent to server.
  Future<void> saveDraft(Booking draft) async {
    final idx = _bookings.indexWhere((b) => b.id == draft.id);
    final d =
        draft.copyWith(isDraft: true, syncStatus: 'pending', retryCount: 0);
    if (idx == -1) {
      _bookings.insert(0, d);
    } else {
      _bookings[idx] = d;
    }
    await _save();
    notifyListeners();
  }

  /// Attempt to sync a local booking to remote backend. Returns true if synced.
  Future<bool> retrySync(Booking booking) async {
    if (_authProvider == null ||
        booking.syncStatus == 'synced' ||
        booking.isDraft) {
      return false;
    }
    final user = _authProvider!.currentUser;
    if (user == null || user.customerId == null) return false;
    try {
      final token = await _authProvider!.getToken();
      final url =
          '${ApiConstants.baseUrl}${ApiConstants.customerOrders(user.customerId!)}';
      final payload = {
        'status': booking.status,
        'pickupAddress': {'addressLine': booking.pickupAddress},
        'deliveryAddress': {'addressLine': booking.dropoffAddress},
      };
      final resp = await http
          .post(Uri.parse(url),
              headers: {
                'Content-Type': ApiConstants.contentTypeJson,
                if (token != null && token.isNotEmpty)
                  'Authorization': 'Bearer $token'
              },
              body: jsonEncode(payload))
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final map = jsonDecode(resp.body) as Map<String, dynamic>;
        final created = map; // plain Map<String, dynamic> from server
        final remoteBooking =
          _mapOrderToBooking(created).copyWith(syncStatus: 'synced');
        // replace booking in list by local id
        final idx = _bookings.indexWhere((b) => b.id == booking.id);
        if (idx != -1) {
            _bookings[idx] = remoteBooking.copyWith(
                id: booking.id,
                remoteId: (created['id'] ?? '').toString(),
                retryCount: 0,
                isDraft: false);
        }
        _errorMessage = null;
        await _save();
        notifyListeners();
        return true;
      }
      _errorMessage = 'Server: ${resp.statusCode}';
      // mark failed and increment retryCount
      final idx = _bookings.indexWhere((b) => b.id == booking.id);
      if (idx != -1) {
        final current = _bookings[idx];
        _bookings[idx] = current.copyWith(
            syncStatus: 'failed', retryCount: (current.retryCount) + 1);
        await _save();
      }
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('BookingsProvider.retrySync failed: $e');
      _errorMessage = e.toString();
      final idx = _bookings.indexWhere((b) => b.id == booking.id);
      if (idx != -1) {
        final current = _bookings[idx];
        _bookings[idx] = current.copyWith(
            syncStatus: 'failed', retryCount: (current.retryCount) + 1);
        await _save();
      }
      notifyListeners();
      return false;
    }
  }

  /// Retry all non-synced bookings with exponential backoff between attempts.
  Future<void> retryAllFailed() async {
    const int maxRetries = 5;
    final pending =
        _bookings.where((b) => b.syncStatus != 'synced' && !b.isDraft).toList();
    for (final b in pending) {
      // exponential backoff based on retryCount (ms), capped at 30s
      const base = 1000;
      final delayMs =
          (base * (1 << (b.retryCount.clamp(0, 10)))).clamp(500, 30000);
      await Future.delayed(Duration(milliseconds: delayMs));
      final success = await retrySync(b);
      if (!success) {
        final idx = _bookings.indexWhere((x) => x.id == b.id);
        if (idx != -1) {
          final current = _bookings[idx];
          final nextRetry = (current.retryCount) + 1;
          _bookings[idx] =
              current.copyWith(retryCount: nextRetry, syncStatus: 'failed');
          if (nextRetry >= maxRetries) {
            // give up after maxRetries; keep failed state
            _bookings[idx] = _bookings[idx].copyWith(syncStatus: 'failed');
          }
          await _save();
        }
      }
    }
    notifyListeners();
  }

  /// Admin: fetch all orders (best-effort). Returns a list of mapped bookings.
  Future<List<Booking>> fetchAdminOrders() async {
    try {
      if (_authProvider == null) return [];
      final token = await _authProvider!.getToken();
      const url = '${ApiConstants.baseUrl}/api/orders';
      final resp = await http.get(Uri.parse(url), headers: {
        'Content-Type': ApiConstants.contentTypeJson,
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token'
      }).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final list = jsonDecode(resp.body) as List<dynamic>;
        final out = <Booking>[];
        for (final item in list) {
          try {
            final map = item as Map<String, dynamic>;
            out.add(_mapOrderToBooking(map));
          } catch (_) {}
        }
        return out;
      }
      throw Exception('Server returned ${resp.statusCode}');
    } catch (e) {
      debugPrint('fetchAdminOrders failed: $e');
      rethrow;
    }
  }

  /// Admin: update remote order (best-effort). Returns true on success.
  Future<bool> updateBooking(Booking booking) async {
    if (_authProvider == null) return false;
    final token = await _authProvider!.getToken();
    if (booking.remoteId == null) return false;
    try {
      final url = '${ApiConstants.baseUrl}/api/orders/${booking.remoteId}';
      // include metadata to keep backend in sync with client-side fields
      final payload = {
        'status': booking.status,
        'pickupAddress': {'addressLine': booking.pickupAddress},
        'deliveryAddress': {'addressLine': booking.dropoffAddress},
        'metadata': {
          'contactName': booking.contactName,
          'contactPhone': booking.contactPhone,
          'vehicleType': booking.vehicleType,
          'serviceType': booking.serviceType,
          'truckType': booking.truckType,
          'pickupCompany': booking.pickupCompany,
          'destinationCompany': booking.destinationCompany,
          'cargoType': booking.cargoType,
          'totalWeightTons': booking.totalWeightTons,
          'totalVolumeCbm': booking.totalVolumeCbm,
          'palletCount': booking.palletCount,
          'containerNo': booking.containerNo,
          'specialHandlingNotes': booking.specialHandlingNotes,
          'receiverName': booking.receiverName,
          'receiverPhone': booking.receiverPhone,
          'capacity': booking.capacity,
          'pickupDateTime': booking.pickupDateTime?.toIso8601String(),
          'notes': booking.notes,
          'packages': booking.packages?.map((p) => p.toJson()).toList(),
        }
      };
      final resp = await http
          .put(Uri.parse(url),
              headers: {
                'Content-Type': ApiConstants.contentTypeJson,
                if (token != null && token.isNotEmpty)
                  'Authorization': 'Bearer $token'
              },
              body: jsonEncode(payload))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        // update local copy
        final idx = _bookings.indexWhere(
            (b) => b.id == booking.id || b.remoteId == booking.remoteId);
        if (idx != -1) {
          _bookings[idx] = booking.copyWith(syncStatus: 'synced');
        }
        await _save();
        notifyListeners();
        return true;
      }
      // try to surface server error
      try {
        final m = jsonDecode(resp.body) as Map<String, dynamic>;
        _errorMessage =
            m['message']?.toString() ?? 'Server: ${resp.statusCode}';
      } catch (_) {
        _errorMessage = 'Server: ${resp.statusCode}';
      }
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('updateBooking failed: $e');
      return false;
    }
  }

  /// Admin: delete remote order and remove local copy if present.
  Future<bool> deleteBookingRemote(Booking booking) async {
    if (_authProvider == null) return false;
    final token = await _authProvider!.getToken();
    if (booking.remoteId == null) return false;
    try {
      final url = '${ApiConstants.baseUrl}/api/orders/${booking.remoteId}';
      final resp = await http.delete(Uri.parse(url), headers: {
        'Content-Type': ApiConstants.contentTypeJson,
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token'
      }).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200 || resp.statusCode == 204) {
        // remove local
        _bookings.removeWhere(
            (b) => b.id == booking.id || b.remoteId == booking.remoteId);
        await _save();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('deleteBookingRemote failed: $e');
      return false;
    }
  }

  Future<void> removeBooking(String id) async {
    _bookings.removeWhere((b) => b.id == id);
    await _save();
    notifyListeners();
  }

  Booking? findById(String id) {
    try {
      return _bookings.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  Booking _mapOrderToBooking(dynamic o) {
    // Accept either a generated `Order`-like object (with `toJson()`)
    // or a plain `Map<String, dynamic>` from direct HTTP responses.
    Map<String, dynamic> map = {};
    try {
      if (o is Map<String, dynamic>) {
        map = o;
      } else {
        map = (o as dynamic).toJson() as Map<String, dynamic>;
      }
    } catch (_) {
      map = {};
    }

    final id = map['id']?.toString() ?? '';
    final title = 'Order #$id';
    String pickup = '';
    String drop = '';
    Map<String, dynamic>? metadata;
    try {
      if (map['pickupAddress'] != null && map['pickupAddress'] is Map) {
        pickup = (map['pickupAddress']['addressLine'] ?? '').toString();
      }
      if (map['deliveryAddress'] != null && map['deliveryAddress'] is Map) {
        drop = (map['deliveryAddress']['addressLine'] ?? '').toString();
      }
      if (map['metadata'] != null && map['metadata'] is Map) {
        metadata = Map<String, dynamic>.from(map['metadata'] as Map);
      }
    } catch (_) {}

    DateTime createdAt = DateTime.now();
    try {
      if (map['createdAt'] != null) {
        createdAt = DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now();
      }
    } catch (_) {}

    return Booking(
      id: id,
      title: title,
      pickupAddress: pickup,
      dropoffAddress: drop,
      createdAt: createdAt,
      status: map['status']?.toString() ?? 'pending',
      contactName: metadata?['contactName']?.toString(),
      contactPhone: metadata?['contactPhone']?.toString(),
      vehicleType: metadata?['vehicleType']?.toString(),
      serviceType: metadata?['serviceType']?.toString(),
      truckType: metadata?['truckType']?.toString(),
      pickupCompany: metadata?['pickupCompany']?.toString(),
      destinationCompany: metadata?['destinationCompany']?.toString(),
      cargoType: metadata?['cargoType']?.toString(),
      totalWeightTons: metadata != null && metadata['totalWeightTons'] != null
          ? double.tryParse(metadata['totalWeightTons'].toString())
          : null,
      totalVolumeCbm: metadata != null && metadata['totalVolumeCbm'] != null
          ? double.tryParse(metadata['totalVolumeCbm'].toString())
          : null,
      palletCount: metadata != null && metadata['palletCount'] != null
          ? int.tryParse(metadata['palletCount'].toString())
          : null,
      containerNo: metadata?['containerNo']?.toString(),
      specialHandlingNotes: metadata?['specialHandlingNotes']?.toString(),
      receiverName: metadata?['receiverName']?.toString(),
      receiverPhone: metadata?['receiverPhone']?.toString(),
      capacity: metadata != null && metadata['capacity'] != null
          ? int.tryParse(metadata['capacity'].toString())
          : null,
      pickupDateTime: metadata != null && metadata['pickupDateTime'] != null
          ? DateTime.tryParse(metadata['pickupDateTime'].toString())
          : null,
      notes: metadata?['notes']?.toString(),
      packages: metadata != null && metadata['packages'] != null
          ? (metadata['packages'] as List)
              .map((e) =>
                  PackageItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
          : null,
    );
  }
}
