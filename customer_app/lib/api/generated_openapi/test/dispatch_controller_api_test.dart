//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

import 'package:openapi/api.dart';
import 'package:test/test.dart';


/// tests for DispatchControllerApi
void main() {
  // final instance = DispatchControllerApi();

  group('tests for DispatchControllerApi', () {
    //Future<ApiResponseDispatchDto> acceptDispatch(int id) async
    test('test acceptDispatch', () async {
      // TODO
    });

    //Future<ApiResponseDispatchDto> assignDispatch(int id, int driverId, int vehicleId) async
    test('test assignDispatch', () async {
      // TODO
    });

    //Future<ApiResponseDispatchDto> assignDriverOnly(int id, int driverId) async
    test('test assignDriverOnly', () async {
      // TODO
    });

    //Future<ApiResponseDispatchDto> assignTruckOnly(int id, int vehicleId) async
    test('test assignTruckOnly', () async {
      // TODO
    });

    //Future<ApiResponseDispatchDto> changeDriver(int id, int driverId) async
    test('test changeDriver', () async {
      // TODO
    });

    //Future<ApiResponseDispatchDto> changeTruck(int id, int vehicleId) async
    test('test changeTruck', () async {
      // TODO
    });

    //Future<ApiResponseDispatchDto> createDispatch(DispatchDto dispatchDto) async
    test('test createDispatch', () async {
      // TODO
    });

    //Future<ApiResponseVoid> deleteDispatch(int id) async
    test('test deleteDispatch', () async {
      // TODO
    });

    //Future<ApiResponseLoadProofDto> driverSubmitLoadProof(int dispatchId, { String remarks, List<MultipartFile> images, MultipartFile signature }) async
    test('test driverSubmitLoadProof', () async {
      // TODO
    });

    //Future<ApiResponsePageDispatchDto> filterDispatches(Pageable pageable, { int driverId, int vehicleId, String status, String driverName, String routeCode, String q, String customerName, String destinationTo, String truckPlate, String tripNo, DateTime start, DateTime end }) async
    test('test filterDispatches', () async {
      // TODO
    });

    //Future<ApiResponsePageDispatchDto> getAllDispatches(Pageable pageable) async
    test('test getAllDispatches', () async {
      // TODO
    });

    //Future<ApiResponseDispatchDto> getDispatchById(int id) async
    test('test getDispatchById', () async {
      // TODO
    });

    //Future<ApiResponseListDispatchStatusHistoryDto> getDispatchStatusHistory(int id) async
    test('test getDispatchStatusHistory', () async {
      // TODO
    });

    //Future<PageDispatchDto> getDispatchesByDriverWithDateRange(int driverId, Pageable pageable, { DateTime from, DateTime to }) async
    test('test getDispatchesByDriverWithDateRange', () async {
      // TODO
    });

    //Future<PageDispatchDto> getDispatchesByDriverWithStatusFilter(int driverId, Pageable pageable, { String status }) async
    test('test getDispatchesByDriverWithStatusFilter', () async {
      // TODO
    });

    //Future<ApiResponseListLoadProofDto> getFilteredLoadProofs({ String search, String driver, String route, DateTime from, DateTime to }) async
    test('test getFilteredLoadProofs', () async {
      // TODO
    });

    //Future<ApiResponseString> importBulkDispatches(MultipartFile file) async
    test('test importBulkDispatches', () async {
      // TODO
    });

    //Future<Object> markAsUnloaded(int dispatchId, { String remarks, String address, double latitude, double longitude, MarkAsUnloadedRequest markAsUnloadedRequest }) async
    test('test markAsUnloaded', () async {
      // TODO
    });

    //Future<ApiResponseDispatchDto> notifyAssignedDriver(int id) async
    test('test notifyAssignedDriver', () async {
      // TODO
    });

    //Future<ApiResponseDispatchDto> planTrip(Map<String, Object> requestBody) async
    test('test planTrip', () async {
      // TODO
    });

    //Future<ApiResponseDispatchDto> rejectDispatch(int id, String reason) async
    test('test rejectDispatch', () async {
      // TODO
    });

    //Future<ApiResponseLoadProofDto> submitLoadProof(int dispatchId, { String remarks, List<MultipartFile> images, MultipartFile signature }) async
    test('test submitLoadProof', () async {
      // TODO
    });

    //Future<ApiResponseUnloadProofDto> submitUnloadProof(int dispatchId, { String remarks, String address, double latitude, double longitude, List<MultipartFile> images, MultipartFile signature }) async
    test('test submitUnloadProof', () async {
      // TODO
    });

    //Future<ApiResponseDispatchDto> updateDispatch(int id, DispatchDto dispatchDto) async
    test('test updateDispatch', () async {
      // TODO
    });

    //Future<ApiResponseDispatchDto> updateDispatchStatus(int id, String status) async
    test('test updateDispatchStatus', () async {
      // TODO
    });

  });
}
