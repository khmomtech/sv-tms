import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api/api_client.dart';
import '../core/api/api_data.dart';
import '../core/api/api_error.dart';
import '../core/api/endpoints.dart';
import '../models/trip.dart';

class TripProvider extends ChangeNotifier {
  static const _dispatchIdKey = 'current_dispatch_id';
  final ApiClient api;
  TripProvider(this.api) {
    _restoreDispatchContext();
  }

  Trip? currentTrip;
  Map<String, dynamic>? dispatchDetail;
  bool isLoading = false;
  String? error;

  int? get currentDispatchId => currentTrip?.dispatchId;

  Future<void> setTrip(String tripId) async {
    final dispatchId = int.tryParse(tripId);
    currentTrip = Trip(tripId: tripId, dispatchId: dispatchId);
    dispatchDetail = null;
    final sp = await SharedPreferences.getInstance();
    if (dispatchId != null) {
      await sp.setInt(_dispatchIdKey, dispatchId);
    } else {
      await sp.remove(_dispatchIdKey);
    }
    notifyListeners();
  }

  Future<void> _restoreDispatchContext() async {
    final sp = await SharedPreferences.getInstance();
    final dispatchId = sp.getInt(_dispatchIdKey);
    if (dispatchId != null) {
      currentTrip = Trip(tripId: dispatchId.toString(), dispatchId: dispatchId);
      notifyListeners();
    }
  }

  Future<void> fetchTimeline(String tripId) async {
    final dispatchId = int.tryParse(tripId);
    if (dispatchId == null) {
      error = 'Trip/dispatch ID must be numeric for loading APIs.';
      notifyListeners();
      return;
    }
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final res =
          await api.dio.get(Endpoints.loadingDispatchDetail(dispatchId));
      dispatchDetail = unwrapData(res.data);
    } on DioException catch (e) {
      error = parseApiError(e).message;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
