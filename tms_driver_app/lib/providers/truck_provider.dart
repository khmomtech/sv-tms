import 'package:flutter/material.dart';
import '../models/assignment_model.dart';
import '../services/assignment_service.dart';

class TruckProvider with ChangeNotifier {
  AssignmentModel? _mainTruckAssignment;
  bool _loading = false;
  DateTime? _lastUpdated;
  String? _error;

  AssignmentModel? get mainTruckAssignment => _mainTruckAssignment;
  bool get loading => _loading;
  DateTime? get lastUpdated => _lastUpdated;
  String? get error => _error;

  String? get mainTruckPlate => _mainTruckAssignment?.truckPlate;
  int? get mainVehicleId => _mainTruckAssignment?.vehicleId;

  bool get hasAssignment =>
      _mainTruckAssignment != null && _mainTruckAssignment!.active;
  bool get needsRefresh =>
      _lastUpdated == null ||
      DateTime.now().difference(_lastUpdated!).inMinutes > 30;

  Future<void> fetchMainTruck(int driverId, {bool forceRefresh = false}) async {
    if (!forceRefresh && !needsRefresh && _mainTruckAssignment != null) {
      print(
          'Using cached assignment (age: ${DateTime.now().difference(_lastUpdated!).inMinutes}min)');
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _mainTruckAssignment =
          await AssignmentService.getDriverAssignment(driverId);
      _lastUpdated = DateTime.now();
      _error = null;
      print(
          'Main truck loaded: ${_mainTruckAssignment?.truckPlate ?? "None assigned"}');
    } catch (e) {
      _error = 'Failed to load truck assignment';
      print('Failed to fetch main truck: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clear() {
    _mainTruckAssignment = null;
    _lastUpdated = null;
    _error = null;
    notifyListeners();
  }
}
